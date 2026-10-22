#!/bin/bash
# Update the non-AIO containers (Caddy, Komga, Jellyfin, monitoring) on the OCI instance
# Usage: ./scripts/update-containers.sh
#
# These services use :latest tags, but nothing updates them on the server:
# the AIO watchtower only handles the AIO mastercontainer. The script pulls
# the new images, shows which containers would change, asks for confirmation
# and recreates only those.
#
# The AIO mastercontainer is deliberately NOT in the list: updating it outside
# the AIO interface leaves the child containers on older images and takes
# Nextcloud down (see docs/13-AIO-UPDATE-TROUBLESHOOTING.md).

set -e

# Compose service names, not container names (Caddy runs as caddy-reverse-proxy)
SERVICES="caddy komga jellyfin grafana prometheus node-exporter cadvisor"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Non-AIO Container Update ===${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$OCI_INSTANCE_IP" ] || [ "$OCI_INSTANCE_IP" = "YOUR_PUBLIC_IP_HERE" ]; then
    echo -e "${RED}Error: OCI_INSTANCE_IP not set in .env${NC}"
    exit 1
fi

if [ -z "$OCI_SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: OCI_SSH_KEY_PATH not set in .env${NC}"
    exit 1
fi

# Expand tilde in path
SSH_KEY_PATH="${OCI_SSH_KEY_PATH/#\~/$HOME}"
SSH_TARGET="${OCI_SSH_USER}@${OCI_INSTANCE_IP}"

echo -e "${GREEN}Server:${NC} ${YELLOW}${SSH_TARGET}${NC}"
echo -e "${GREEN}Services:${NC} ${YELLOW}${SERVICES}${NC}"
echo ""

# Step 1: pull the new images and compare them with the running containers.
# Pulling only downloads images: no container is touched yet.
# Human-readable lines go to stderr, the services to update go to stdout.
echo -e "${YELLOW}[1/2] Pulling images (this can take a minute)...${NC}"
echo ""

PENDING=$(ssh -i "$SSH_KEY_PATH" "$SSH_TARGET" "bash -s -- $SERVICES" << 'ENDSSH'
set -e
cd ~/nextcloud
docker compose pull --quiet "$@" >&2

for service in "$@"; do
    container=$(docker compose ps -aq "$service")
    if [ -z "$container" ]; then
        echo "  $service: no container, skipped" >&2
        continue
    fi
    image=$(docker inspect -f '{{.Config.Image}}' "$container")
    running_id=$(docker inspect -f '{{.Image}}' "$container")
    latest_id=$(docker image inspect -f '{{.Id}}' "$image")
    running_date=$(docker image inspect -f '{{.Created}}' "$running_id" | cut -c1-10)
    latest_date=$(docker image inspect -f '{{.Created}}' "$latest_id" | cut -c1-10)

    if [ "$running_id" = "$latest_id" ]; then
        echo "  $service: up to date (image of $running_date)" >&2
    else
        echo "  $service: $running_date -> $latest_date" >&2
        echo "$service"
    fi
done
ENDSSH
)

echo ""
if [ -z "$PENDING" ]; then
    echo -e "${GREEN}✓ All containers are up to date${NC}"
    exit 0
fi

PENDING=$(echo "$PENDING" | tr '\n' ' ')
echo -e "${YELLOW}To be recreated:${NC} ${PENDING}"
if [[ " $PENDING " == *" caddy "* ]]; then
    echo -e "${YELLOW}Caddy is included: Nextcloud will be unreachable for a few seconds.${NC}"
fi
echo -e "${YELLOW}After a long gap some services migrate their database on first start: let them finish.${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. The new images are downloaded, but no container was changed."
    exit 0
fi

# Step 2: recreate the containers and wait for them to settle.
# --no-deps keeps compose from recreating the services these depend on.
# A container that crash-loops can look "running" between two restarts,
# so the restart count is checked too.
echo ""
echo -e "${YELLOW}[2/2] Recreating containers...${NC}"
echo ""

UPDATE_FAILED=false
ssh -i "$SSH_KEY_PATH" "$SSH_TARGET" "bash -s -- $PENDING" << 'ENDSSH' || UPDATE_FAILED=true
set -e
cd ~/nextcloud
docker compose up -d --no-deps "$@"

state_of() {
    docker inspect -f '{{.State.Status}}{{if .State.Health}}/{{.State.Health.Status}}{{end}} restarts={{.RestartCount}}' "$1"
}

is_ok() {
    case "$1" in
        "running restarts=0" | "running/healthy restarts=0") return 0 ;;
        *) return 1 ;;
    esac
}

# Give crashing containers time to crash, then wait up to 3 more minutes
# for healthchecks to leave "starting"
echo ""
echo "Waiting for containers to start..."
sleep 30
for _ in $(seq 18); do
    settled=true
    for service in "$@"; do
        is_ok "$(state_of "$(docker compose ps -aq "$service")")" || settled=false
    done
    [ "$settled" = true ] && break
    sleep 10
done

echo ""
failed=0
for service in "$@"; do
    container=$(docker compose ps -aq "$service")
    name=$(docker inspect -f '{{.Name}}' "$container" | tr -d /)
    state=$(state_of "$container")
    if is_ok "$state"; then
        echo "  OK    $service ($state)"
    elif [ "$state" = "running/starting restarts=0" ]; then
        # Usually a long database migration: not a failure yet
        echo "  WAIT  $service (still starting: check again in a few minutes with docker ps)"
    else
        echo "  FAIL  $service ($state) -> docker logs $name --tail 80"
        failed=1
    fi
done
exit $failed
ENDSSH

echo ""
if [ "$UPDATE_FAILED" = true ]; then
    echo -e "${RED}✗ Some containers did not start cleanly: check the logs listed above${NC}"
    exit 1
fi
echo -e "${GREEN}✓ All containers updated and running${NC}"

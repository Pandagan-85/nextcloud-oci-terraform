#!/bin/bash
# Setup pre-commit hooks for automated formatting
# Usage: ./scripts/setup-precommit.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Setting up Pre-commit Hooks ===${NC}"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required${NC}"
    echo "Please install Python 3 first"
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}Error: pip3 is required${NC}"
    echo "Please install pip3 first"
    exit 1
fi

# Install pre-commit
echo -e "${YELLOW}Installing pre-commit...${NC}"
pip3 install --user pre-commit

# Install the git hooks
echo -e "${YELLOW}Installing git hooks...${NC}"
pre-commit install

# Run on all files to verify setup
echo -e "${YELLOW}Running pre-commit on all files (this may take a while)...${NC}"
pre-commit run --all-files || true

echo ""
echo -e "${GREEN}✓ Pre-commit hooks installed successfully!${NC}"
echo ""
echo -e "${BLUE}What happens now:${NC}"
echo "  • Before each commit, pre-commit will automatically:"
echo "    - Format Terraform files (terraform fmt)"
echo "    - Lint shell scripts (shellcheck)"
echo "    - Fix markdown files (markdownlint)"
echo "    - Check YAML syntax"
echo "    - Detect secrets (gitleaks)"
echo "    - Fix trailing whitespace and line endings"
echo ""
echo -e "${YELLOW}Manual run:${NC} pre-commit run --all-files"
echo -e "${YELLOW}Skip hooks:${NC} git commit --no-verify"
echo ""

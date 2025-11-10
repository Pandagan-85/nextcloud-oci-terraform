# Monitoring Stack - Prometheus + Grafana

Complete monitoring solution for Nextcloud on OCI using Prometheus and Grafana.

## Architecture

```
┌───────────────────────────────────────────────────┐
│                MONITORING STACK                   │
├───────────────────────────────────────────────────┤
│                                                   │
│  ┌──────────────┐      ┌──────────────┐         │
│  │ Node Exporter│─────▶│              │         │
│  │  (System)    │      │              │         │
│  └──────────────┘      │  Prometheus  │         │
│                        │   :9090      │         │
│  ┌──────────────┐      │              │         │
│  │  cAdvisor    │─────▶│              │         │
│  │ (Containers) │      └──────┬───────┘         │
│  └──────────────┘             │                  │
│                                │                  │
│                                ▼                  │
│                        ┌──────────────┐          │
│                        │   Grafana    │          │
│                        │    :3000     │          │
│                        └──────┬───────┘          │
│                               │                   │
│                               ▼                   │
│                        ┌──────────────┐          │
│                        │     Caddy    │          │
│                        │  Reverse     │          │
│                        │    Proxy     │          │
│                        └──────────────┘          │
│                               │                   │
└───────────────────────────────┼───────────────────┘
                                ▼
            https://monitoring.yourdomain.duckdns.org
```

## Components

### 1. **Prometheus** (Port 9090)
- Metrics collection and storage
- 30-day retention by default
- Scrapes metrics every 15 seconds
- **Access**: http://localhost:9090 (localhost only)

### 2. **Grafana** (Port 3000)
- Visualization and dashboards
- Pre-configured Prometheus datasource
- **Access**: https://monitoring.yourdomain.duckdns.org

### 3. **Node Exporter** (Port 9100)
- System metrics:
  - CPU usage, load average
  - Memory (free, cached, buffers)
  - Disk I/O and space
  - Network traffic
  - System uptime

### 4. **cAdvisor** (Port 8081)
- Docker container metrics:
  - Per-container CPU usage
  - Per-container memory usage
  - Container network I/O
  - Container disk I/O
  - Container health and restarts

## Setup Instructions

### 1. Configure DuckDNS Subdomain

Add the monitoring subdomain to your DuckDNS account:

```bash
# Go to https://www.duckdns.org
# Add subdomain: monitoring.yourdomain
# Point it to the same IP as your main domain
```

### 2. Set Grafana Password

Edit your `.env` file:

```bash
# Generate secure password
openssl rand -base64 32

# Add to .env
GRAFANA_ADMIN_PASSWORD=your-generated-password-here
```

### 3. Deploy Monitoring Stack

```bash
# From docker/ directory
cd docker/

# Start all services (including monitoring)
docker compose up -d

# Check logs
docker compose logs -f prometheus grafana
```

### 4. Access Grafana

```bash
# URL: https://monitoring.yourdomain.duckdns.org
# Username: admin
# Password: (from GRAFANA_ADMIN_PASSWORD in .env)
```

## Metrics Available

### System Metrics (Node Exporter)

- **CPU**:
  - `node_cpu_seconds_total` - CPU time per mode (user, system, idle)
  - `node_load1`, `node_load5`, `node_load15` - System load averages

- **Memory**:
  - `node_memory_MemTotal_bytes` - Total RAM
  - `node_memory_MemAvailable_bytes` - Available RAM
  - `node_memory_Cached_bytes` - Cached memory

- **Disk**:
  - `node_filesystem_avail_bytes` - Available disk space
  - `node_filesystem_size_bytes` - Total disk space
  - `node_disk_read_bytes_total` - Disk read throughput
  - `node_disk_written_bytes_total` - Disk write throughput

- **Network**:
  - `node_network_receive_bytes_total` - Network RX
  - `node_network_transmit_bytes_total` - Network TX

### Container Metrics (cAdvisor)

- **CPU**:
  - `container_cpu_usage_seconds_total` - Per-container CPU usage
  - `container_cpu_system_seconds_total` - System CPU time

- **Memory**:
  - `container_memory_usage_bytes` - Current memory usage
  - `container_memory_max_usage_bytes` - Peak memory usage
  - `container_memory_cache` - Cache memory

- **Network**:
  - `container_network_receive_bytes_total` - Container RX
  - `container_network_transmit_bytes_total` - Container TX

- **Filesystem**:
  - `container_fs_usage_bytes` - Filesystem usage
  - `container_fs_limit_bytes` - Filesystem limit

## Grafana Dashboard Setup

### Import Pre-built Dashboards

1. **Node Exporter Full** (ID: 1860)
   ```
   Grafana → Dashboards → Import → Enter ID: 1860
   ```
   - Comprehensive system monitoring
   - CPU, Memory, Disk, Network graphs

2. **Docker Container & Host Metrics** (ID: 179)
   ```
   Grafana → Dashboards → Import → Enter ID: 179
   ```
   - Per-container resource usage
   - Container health monitoring

3. **Caddy Monitoring** (ID: 14280)
   ```
   Grafana → Dashboards → Import → Enter ID: 14280
   ```
   - HTTP request rates
   - Response times
   - SSL certificate status

### Custom Queries

Useful PromQL queries for custom dashboards:

**CPU Usage Percentage**:
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory Usage Percentage**:
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Disk Usage Percentage**:
```promql
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

**Container CPU Usage**:
```promql
rate(container_cpu_usage_seconds_total{name=~"nextcloud.*"}[5m]) * 100
```

**Container Memory Usage (MB)**:
```promql
container_memory_usage_bytes{name=~"nextcloud.*"} / 1024 / 1024
```

## Troubleshooting

### Prometheus Not Scraping Metrics

```bash
# Check if exporters are running
docker ps | grep -E "prometheus|node-exporter|cadvisor"

# Check Prometheus targets
# Go to: http://localhost:9090/targets
# All targets should be "UP"

# View Prometheus logs
docker compose logs prometheus
```

### Grafana Can't Connect to Prometheus

```bash
# Check if both are on the same network
docker network inspect monitoring

# Should see both prometheus and grafana containers

# Test connectivity from Grafana container
docker exec grafana wget -qO- http://prometheus:9090/-/healthy
# Should return: Prometheus is Healthy.
```

### cAdvisor Privileged Mode Warning

cAdvisor requires `privileged: true` to access host metrics. This is by design and safe as:
- Container is read-only for most paths
- Only collects metrics, doesn't modify system
- Industry standard practice for container monitoring

### High Memory Usage

Prometheus stores metrics in memory. Expected usage:
- Base: ~50-100 MB
- Per day of data: ~10-20 MB
- With 30-day retention: ~500 MB - 1 GB

To reduce:
```yaml
# In prometheus command section of docker-compose.yml
- '--storage.tsdb.retention.time=15d'  # Reduce to 15 days
```

## Security Considerations

### Port Bindings

All monitoring services bind to `127.0.0.1` (localhost only):
- Prometheus: `127.0.0.1:9090`
- Grafana: `127.0.0.1:3000`
- Node Exporter: `127.0.0.1:9100`
- cAdvisor: `127.0.0.1:8081`

**Only Grafana is exposed via HTTPS** through Caddy reverse proxy.

### Grafana Authentication

- Change default admin password immediately after first login
- Disable user sign-up (already configured: `GF_USERS_ALLOW_SIGN_UP=false`)
- Use strong password (minimum 20 characters)

### Network Isolation

Monitoring services run on dedicated `monitoring` network, isolated from `nextcloud-aio` network. Only Caddy bridges both networks.

## Data Persistence

### Prometheus Data

Stored in Docker volume: `prometheus_data`

```bash
# Backup Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/prometheus-backup.tar.gz /data

# Restore Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/prometheus-backup.tar.gz -C /
```

### Grafana Data

Stored in Docker volume: `grafana_data`

```bash
# Backup Grafana dashboards and settings
docker run --rm -v grafana_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup.tar.gz /data

# Restore Grafana data
docker run --rm -v grafana_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/grafana-backup.tar.gz -C /
```

## Resource Usage

Estimated resource consumption:

| Service | CPU | RAM | Disk (30 days) |
|---------|-----|-----|----------------|
| Prometheus | 0.1-0.3 CPU | 500 MB - 1 GB | 2-5 GB |
| Grafana | 0.05-0.1 CPU | 100-200 MB | 100 MB |
| Node Exporter | 0.01 CPU | 10 MB | Negligible |
| cAdvisor | 0.1 CPU | 50-100 MB | Negligible |
| **Total** | **~0.3 CPU** | **~1 GB** | **~3 GB** |

Well within OCI free tier limits (4 vCPU, 24 GB RAM).

## Useful Commands

```bash
# View all monitoring containers
docker ps --filter "name=prometheus|grafana|node-exporter|cadvisor"

# Restart monitoring stack
docker compose restart prometheus grafana node-exporter cadvisor

# View metrics endpoints
curl http://localhost:9100/metrics  # Node Exporter
curl http://localhost:8081/metrics  # cAdvisor
curl http://localhost:9090/metrics  # Prometheus

# Check Grafana health
curl http://localhost:3000/api/health

# Prometheus query API
curl 'http://localhost:9090/api/v1/query?query=up'
```

## Next Steps

1. **Set up Alertmanager** (optional)
   - Email/Slack notifications for critical alerts
   - See: https://prometheus.io/docs/alerting/latest/alertmanager/

2. **Create Custom Dashboards**
   - Nextcloud-specific metrics
   - Backup success/failure tracking
   - User activity monitoring

3. **Enable Caddy Metrics**
   - Add Prometheus metrics to Caddy
   - Monitor reverse proxy performance

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter Guide](https://github.com/prometheus/node_exporter)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

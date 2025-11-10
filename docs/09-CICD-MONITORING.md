# CI/CD and Monitoring

This document describes the CI/CD pipeline and monitoring setup for the Nextcloud OCI Terraform project.

## CI/CD Architecture

The project uses a **staged CI/CD pipeline** with GitHub Actions, following real-world best practices for efficient feedback and resource utilization.

### Workflow Structure

```
┌─────────────────────────────────────────────────────────┐
│                    CI PIPELINE (ci.yml)                 │
│                   Runs on: PR + Push                    │
├─────────────────────────────────────────────────────────┤
│  Stage 1: VALIDATION (< 2 min)                         │
│    ├─ Terraform fmt + validate                         │
│    ├─ YAML lint                                         │
│    ├─ Markdown lint                                     │
│    ├─ Docker Compose validate                          │
│    └─ ShellCheck                                        │
├─────────────────────────────────────────────────────────┤
│  Stage 2: SECURITY (parallel after validation)         │
│    ├─ tfsec (Terraform security)                       │
│    ├─ Trivy (IaC vulnerabilities)                      │
│    └─ Gitleaks (secret detection)                      │
├─────────────────────────────────────────────────────────┤
│  Stage 3: DOCKER (parallel with security)              │
│    ├─ Trivy Docker Compose scan                        │
│    ├─ Check privileged containers                      │
│    ├─ Check Docker socket permissions                  │
│    └─ Check hardcoded secrets                          │
├─────────────────────────────────────────────────────────┤
│  Stage 4: PR AUTOMATION (parallel, PR only)            │
│    ├─ Display PR info                                   │
│    ├─ Auto-label by files changed                      │
│    ├─ Size labeling (XS/S/M/L/XL)                      │
│    └─ Conventional commits check (informational)       │
├─────────────────────────────────────────────────────────┤
│  Stage 5: SUMMARY                                       │
│    └─ Aggregate results and report status              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│         DEEP SECURITY SCAN (security-deep.yml)          │
│          Runs: Weekly (Mon 9:00 UTC) + Manual          │
├─────────────────────────────────────────────────────────┤
│  • tfsec with SARIF upload                             │
│  • Trivy full IaC scan                                  │
│  • ShellCheck (all scripts)                             │
│  • Gitleaks (full history)                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│        DOCKER IMAGE SCAN (docker-image-scan.yml)        │
│          Runs: Weekly (Wed 3:00 UTC) + Manual          │
├─────────────────────────────────────────────────────────┤
│  • Scan nextcloud/all-in-one:latest                     │
│  • Scan caddy:latest                                    │
│  • Check for image updates                              │
│  • Test Docker Compose pull                             │
└─────────────────────────────────────────────────────────┘
```

## Workflow Files

### 1. `ci.yml` - Main CI Pipeline

**Purpose**: Fast feedback for developers on every PR and push to main.

**Triggers**:

- Pull requests (opened, synchronized, reopened)
- Push to main branch

**Stages**:

1. **Validation** (< 2 min) - Fast checks that fail immediately if code is malformed
2. **Security** (2-5 min) - Security scans after validation passes
3. **Docker** (1-2 min) - Docker-specific checks, parallel with security
4. **PR Automation** (< 1 min) - Auto-labeling and commit checks, parallel
5. **Summary** (< 1 min) - Aggregates all results

**Status**: ✅ **Required** - PRs cannot merge if this fails

**Design Principles**:

- **Fail fast**: Validation runs first, fails quickly on formatting errors
- **Efficient parallelization**: Security and Docker checks run in parallel after validation
- **Clear feedback**: Summary stage shows exactly what failed
- **Non-blocking commit checks**: Conventional commits are informational only

### 2. `security-deep.yml` - Deep Security Scanning

**Purpose**: Comprehensive weekly security audit.

**Triggers**:

- Schedule: Every Monday at 9:00 UTC
- Manual: workflow_dispatch

**Checks**:

- **tfsec**: Terraform security best practices
- **Trivy**: Full IaC vulnerability scanning (config + filesystem)
- **ShellCheck**: All shell scripts linting
- **Gitleaks**: Secret detection across full git history

**Results**: Uploaded to GitHub Security tab (SARIF format)

**Status**: ℹ️ **Informational** - Does not block PRs

### 3. `docker-image-scan.yml` - Docker Image Security

**Purpose**: Monitor vulnerabilities in upstream Docker images.

**Triggers**:

- Schedule: Every Wednesday at 3:00 UTC
- Manual: workflow_dispatch

**Checks**:

- Vulnerability scan of `nextcloud/all-in-one:latest`
- Vulnerability scan of `caddy:latest`
- Check for image updates
- Validate Docker Compose configuration

**Results**: Uploaded to GitHub Security tab (SARIF format)

**Status**: ℹ️ **Informational** - Does not block PRs

**Note**: We use `:latest` tags for simplicity. For production at scale, consider digest pinning:

```yaml
image: nextcloud/all-in-one@sha256:abc123...
```

## Pre-commit Hooks

**Prevent CI failures before committing!**

Pre-commit hooks automatically format and check your code locally:

### Setup

```bash
./scripts/setup-precommit.sh
```

### What it does

- **Terraform fmt**: Auto-format Terraform files
- **Markdown fix**: Auto-fix markdown formatting issues
- **ShellCheck**: Lint shell scripts
- **YAML validation**: Check YAML syntax
- **Gitleaks**: Detect hardcoded secrets
- **File checks**: Fix trailing whitespace, line endings, etc.

### Manual run

```bash
# Run on all files
pre-commit run --all-files

# Run on staged files only
pre-commit run
```

### Skip hooks (not recommended)

```bash
git commit --no-verify
```

## GitHub Security Integration

All security scan results are uploaded to the **GitHub Security** tab in SARIF format:

- Navigate to: `Security` → `Code scanning alerts`
- View: Vulnerabilities, security issues, and secret leaks
- Filter by: Tool (tfsec, Trivy, Gitleaks), severity, status

## Branch Protection Rules

**Recommended settings for `main` branch:**

```yaml
Require status checks to pass:
  ✅ CI Pipeline / validation
  ✅ CI Pipeline / security
  ✅ CI Pipeline / docker
  ✅ CI Pipeline / summary

Require branches to be up to date: ✅
Require linear history: ✅ (optional)
```

**Not required** (informational only):

- Deep Security Scan (scheduled)
- Docker Image Scan (scheduled)
- Conventional commits check

## CI Pipeline Flow

### Stage 1: Validation (Fast Fail)

The validation stage runs first and fails fast if basic checks don't pass:

```bash
# Terraform checks
terraform fmt -check -recursive terraform/
terraform validate

# YAML lint
yamllint docker/docker-compose.yml terraform/cloud-init.yaml .github/workflows/*.yml

# Docker Compose validation
docker compose config --quiet

# Markdown lint
markdownlint-cli2 "**/*.md"

# ShellCheck
shellcheck scripts/*.sh
```

### Stage 2-4: Parallel Checks

After validation passes, three stages run in parallel:

**Security Stage**:

- tfsec → Terraform security scanning
- Trivy → IaC vulnerability detection
- Gitleaks → Secret detection

**Docker Stage**:

- Trivy Docker Compose scan
- Custom security checks (privileged containers, socket permissions, hardcoded secrets)

**PR Automation** (PRs only):

- Display PR information
- Auto-label by changed files
- Size labeling (XS/S/M/L/XL based on lines changed)
- Conventional commits validation (informational)

### Stage 5: Summary

Aggregates results from all stages and provides a clear pass/fail status.

## Monitoring

### Current Status

🚧 **Monitoring is not yet implemented.**

### Planned Implementation

The following monitoring stack will be added in a future phase:

- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics (CPU, RAM, disk)
- **cAdvisor**: Container metrics
- **Alertmanager**: Alert notifications

See [ROADMAP.md](../ROADMAP.md) for details.

## Troubleshooting

### CI Pipeline Failures

**Validation stage fails**:

- Run `pre-commit run --all-files` locally to fix formatting
- Check `terraform fmt -check -recursive terraform/`
- Verify YAML syntax with `yamllint`

**Security stage fails**:

- Review tfsec findings: usually Terraform security best practices
- Check Trivy output for IaC misconfigurations
- Gitleaks failure means secrets detected - remove and rotate them immediately

**Docker stage fails**:

- Check for privileged containers or read-write Docker socket
- Verify no hardcoded secrets in docker-compose.yml
- Review Trivy Docker Compose scan results

### Pre-commit Hook Issues

**Hooks not running**:

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
```

**Hook fails**:

```bash
# Update hook dependencies
pre-commit autoupdate

# Clear cache and retry
pre-commit clean
pre-commit run --all-files
```

### SARIF Upload Failures

If you see "Resource not accessible by integration":

- Ensure workflow has `security-events: write` permission
- Check that GitHub Advanced Security is enabled (free for public repos)

## Best Practices

1. **Always use pre-commit hooks** - Catch issues before CI runs
2. **Fix validation errors first** - They're fast and easy to fix
3. **Don't ignore security warnings** - Review and address or document exceptions
4. **Keep dependencies updated** - Monitor scheduled scan results
5. **Use conventional commits** - Helps with changelog generation
6. **Test locally before pushing** - Run `docker compose config` and `terraform validate`

## Local Testing

Before pushing, test locally:

```bash
# 1. Pre-commit checks
pre-commit run --all-files

# 2. Terraform validation
cd terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate
cd ..

# 3. Docker Compose validation
cd docker
docker compose config --quiet
cd ..

# 4. ShellCheck
shellcheck scripts/*.sh

# 5. Markdown lint
npx markdownlint-cli2 "**/*.md"
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Security Best Practices](https://www.terraform.io/docs/language/values/variables.html#sensitive)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Pre-commit Framework](https://pre-commit.com/)

---

**Next Steps**: Implement Prometheus + Grafana monitoring (see ROADMAP.md Phase 3)

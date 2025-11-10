# Contributing to Nextcloud OCI Terraform

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 🎯 Project Philosophy

This project aims to provide a **production-ready, fully automated, and reusable** Nextcloud deployment on Oracle Cloud's free tier. All contributions should align with these principles:

1. **Infrastructure as Code** - Everything automated via Terraform
2. **Security First** - No hardcoded secrets, security scanning enabled
3. **Documentation** - Well-documented for reproducibility
4. **Simplicity** - Easy to use for beginners, powerful for advanced users

## 🚀 Getting Started

### Prerequisites

- Oracle Cloud account (free tier)
- Terraform >= 1.9
- Git
- Basic understanding of Terraform and Docker

### Development Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/nextcloud-oci-terraform.git
   cd nextcloud-oci-terraform
   ```

2. **Create a Branch**

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Set up Terraform**

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Install Pre-commit Hooks** (Recommended)

   Pre-commit hooks automatically format and check your code before committing, preventing CI/CD failures:

   ```bash
   ./scripts/setup-precommit.sh
   ```

   This will automatically:
   - Format Terraform files (`terraform fmt`)
   - Lint shell scripts (`shellcheck`)
   - Fix markdown formatting (`markdownlint`)
   - Check YAML syntax
   - Detect hardcoded secrets (`gitleaks`)
   - Fix trailing whitespace and line endings

   **Manual run:** `pre-commit run --all-files`

   **Skip hooks (not recommended):** `git commit --no-verify`

## 📝 Contribution Guidelines

### Code Style

#### Terraform

- Use consistent formatting: `terraform fmt -recursive`
- Follow HashiCorp's [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Add comments for complex logic
- Use variables instead of hardcoded values

#### Shell Scripts

- Use `#!/bin/bash` shebang
- Add descriptive comments
- Use `set -e` for error handling
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

#### Markdown

- Follow [markdownlint](https://github.com/DavidAnson/markdownlint) rules
- Use relative links for internal documentation
- Keep line length reasonable (80-120 chars when possible)

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```bash
feat(terraform): add support for custom VCN CIDR

- Allow users to specify custom VCN and subnet CIDR blocks
- Update documentation with examples
- Add validation for CIDR format

Closes #123
```

```bash
fix(scripts): resolve backup script permission error

The backup script was failing due to incorrect permissions
on the backup directory. This commit adds proper ownership check
and fixes the permission setting.

Fixes #456
```

### Pull Request Process

1. **Update Documentation**
   - Update README.md if adding features
   - Update relevant docs/ files
   - Add inline comments for complex code

2. **Run Local Tests**

   ```bash
   # Format Terraform
   terraform fmt -recursive -check terraform/

   # Validate Terraform
   cd terraform && terraform init -backend=false && terraform validate

   # Check shell scripts
   shellcheck scripts/*.sh
   ```

3. **Create Pull Request**
   - Use the PR template provided
   - Fill in all relevant sections
   - Link related issues
   - Add screenshots if UI changes

4. **CI/CD Checks**
   All PRs must pass:
   - ✅ Terraform validation
   - ✅ Security scanning (tfsec, trivy)
   - ✅ Documentation checks
   - ✅ Shell script linting

5. **Review Process**
   - Address review comments promptly
   - Keep PRs focused and atomic
   - Squash commits if requested

## 🔒 Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead, please email security concerns to the maintainer privately.

### Security Best Practices

- Never commit secrets (use `.gitignore`)
- Use variables for sensitive data
- Mark Terraform variables as `sensitive = true`
- Follow the principle of least privilege
- Keep dependencies updated

## 🧪 Testing

### Terraform Testing

```bash
# Initialize without backend
terraform init -backend=false

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Security scan
docker run --rm -v $(pwd):/src aquasec/tfsec /src/terraform
```

### Integration Testing

When possible, test changes on a real OCI instance:

1. Create test environment: `terraform apply`
2. Verify functionality
3. Document test results in PR
4. Clean up: `terraform destroy`

## 📚 Documentation

### Adding Documentation

- Place new docs in `docs/` directory
- Use numbered prefixes for ordered guides (e.g., `01-SETUP.md`)
- Update README.md table of contents
- Include code examples and screenshots

### Documentation Structure

```
docs/
├── 01-INITIAL-SETUP.md       # First-time setup
├── 02-SYSTEM-SETUP.md        # System configuration
├── 03-DOCKER-SETUP.md        # Docker installation
├── 04-FIREWALL-SECURITY.md   # Security hardening
└── 09-CICD-MONITORING.md     # CI/CD and monitoring
```

## 🎯 Areas for Contribution

Looking for ideas? Here are areas that need help:

### High Priority

- [ ] GitHub Actions workflows optimization
- [ ] Monitoring with Prometheus + Grafana
- [ ] Automated backup testing
- [ ] Multi-region deployment guide

### Medium Priority

- [ ] Object Storage integration for off-site backups
- [ ] Data migration scripts
- [ ] Performance tuning documentation
- [ ] Cost optimization tips

### Nice to Have

- [ ] Ansible playbooks alternative
- [ ] GitLab CI/CD support
- [ ] Docker Swarm/Kubernetes alternatives
- [ ] Windows deployment scripts

## 💬 Communication

- **Issues**: For bugs, feature requests, and questions
- **Discussions**: For general discussions and ideas
- **Pull Requests**: For code contributions

## 📋 Checklist for Contributions

Before submitting your PR, ensure:

- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] No secrets or personal data committed
- [ ] PR template is filled out completely
- [ ] Related issues are linked

## 🙏 Thank You

Every contribution, no matter how small, is valuable. Thank you for helping make this project better!

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

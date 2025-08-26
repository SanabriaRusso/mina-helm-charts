# GitHub Actions CI/CD Setup for mina-daemon-chart

## 🎯 Overview

This implementation provides a complete CI/CD pipeline for the `mina-daemon-chart` Helm chart with:
- **PR Gates**: Comprehensive linting and testing before merge
- **Auto-Tagging**: Automatic version tagging based on Chart.yaml
- **Modern Distribution**: OCI registry publishing to GitHub Container Registry

## 🏗️ Architecture

### Workflows Created

1. **`.github/workflows/pr-validation.yml`**
   - Triggers on PRs to master/main
   - Runs helm lint with both values.yaml and ct-values.yaml
   - Template rendering validation
   - Chart-testing (ct) with kind cluster
   - Security scanning for common vulnerabilities
   - Chart metadata validation

2. **`.github/workflows/release.yml`**
   - Triggers on push to master/main
   - Extracts version from Chart.yaml
   - Creates git tags (format: v0.0.1)
   - Publishes to GitHub OCI registry (ghcr.io)
   - Creates GitHub releases with notes
   - Skips if tag already exists

3. **`ct.yaml`**
   - Chart-testing configuration
   - Standardizes testing parameters

4. **`scripts/validate-chart.sh`**
   - Local validation script
   - Replicates workflow checks locally

## 🚀 Usage

### For Development

1. **Local Testing**:
   ```bash
   # Run comprehensive local validation
   ./scripts/validate-chart.sh
   ```

2. **Create a PR**:
   - Make changes to the chart
   - Create pull request to master
   - PR validation workflow runs automatically
   - All checks must pass before merge

3. **Release Process**:
   - Merge PR to master
   - Release workflow runs automatically
   - Tag created: `v<chart-version>`
   - Chart published to OCI registry

### For Chart Users

#### Install from OCI Registry (Recommended)
```bash
# Latest version
helm install my-mina oci://ghcr.io/<your-org>/charts/mina-standard-daemon

# Specific version
helm install my-mina oci://ghcr.io/<your-org>/charts/mina-standard-daemon --version 0.0.1
```

#### Install from GitHub Release
```bash
# Download and install from release
helm install my-mina https://github.com/<your-org>/mina-helm-charts/releases/download/v0.0.1/mina-standard-daemon-0.0.1.tgz
```

## 🔧 Configuration

### Required GitHub Settings

1. **Repository Settings**:
   - Enable GitHub Pages (for potential chart hosting)
   - Allow GitHub Actions
   - Enable "Read and write permissions" for GITHUB_TOKEN

2. **Branch Protection** (Recommended):
   ```yaml
   # Add to master/main branch protection rules
   required_status_checks:
     - lint-and-test
     - validate-chart-metadata
   ```

#### Release Customization
- **Tag Format**: Change tag format in release.yml (currently `v{version}`)
- **Registry**: Switch from ghcr.io to another OCI registry
- **Release Notes**: Customize release notes template

## 🔒 Security Features

### Built-in Security Checks
- **No Hardcoded Secrets**: Scans templates for potential secrets
- **No Privileged Containers**: Prevents privileged container usage
- **No hostNetwork**: Blocks dangerous host networking
- **Minimal Permissions**: Workflows use minimal required permissions

### Repository Security
- **GITHUB_TOKEN**: Uses built-in token with minimal permissions
- **OCI Registry**: Uses GitHub's secure container registry
- **No External Dependencies**: All actions from verified publishers

## 📊 Monitoring

### Chart Distribution
```bash
# Check available versions
helm search repo oci://ghcr.io/<your-org>/charts/mina-standard-daemon --versions

# View chart information  
helm show chart oci://ghcr.io/<your-org>/charts/mina-standard-daemon
```

## 🐛 Troubleshooting

### Common Issues

1. **Lint Failures**:
   ```bash
   # Test locally first
   cd mina-daemon-chart
   helm lint . --values values.yaml
   ```

2. **Template Rendering Issues**:
   ```bash
   # Debug template output
   helm template test . --values ct-values.yaml --debug
   ```

3. **Dependency Problems**:
   ```bash
   # Update dependencies
   helm dependency update
   ```

4. **OCI Registry Issues**:
   - Ensure repository visibility settings allow package access
   - Check GITHUB_TOKEN permissions
   - Verify lowercase repository owner name

### Validation Script Output
The local validation script provides detailed output for each step:
- ✅ Success indicators
- ❌ Error indicators with explanations
- 📊 Statistics and metadata
- 📥 Next steps guidance

## 🔄 Version Management

### Semantic Versioning
- Chart versions must follow semver (e.g., 0.0.1, 1.0.0, 1.2.3)
- Increment version in Chart.yaml for releases
- Tags are automatically created as v{version}

### Release Strategy
1. **Development**: Work in feature branches
2. **Testing**: PR validation ensures quality
3. **Release**: Merge triggers automatic release
4. **Distribution**: Available immediately in OCI registry

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains community-generalized Helm charts for deploying Mina blockchain nodes on Kubernetes. The charts are forked from o1Labs' private gitops-helm-charts repository and have been made open source for community use while maintaining backwards compatibility.

**Important**: This repository represents a transition from private o1Labs-specific charts to community-friendly versions. Always ensure backwards compatibility and use generic configurations suitable for public use.

## Architecture

The repository follows a layered Helm chart architecture with two main components:

### 1. mina-daemon-chart (Baseline Chart)
- **Purpose**: Provides the core Kubernetes manifests for deploying Mina daemon containers
- **Type**: Standard Helm chart with templates and values
- **Dependencies**: PostgreSQL chart from Bitnami (optional, controlled via `postgresql.enable`)
- **Key Templates**: 
  - `_container.tpl`: Reusable container template for daemon, archive, and extra containers
  - `deployment.yaml`: Main workload definition
  - `_helpers.tpl`: Standard Helm helper functions for naming and labeling

### 2. mina-node-orchestrator (Node-Level Abstraction)
- **Purpose**: Helmfile-based orchestrator that generates values for the baseline chart
- **Type**: Helmfile with Go templates (`.gotmpl` files)
- **Valid Node Roles**: `plain`, `coordinator`, `snarkWorker`, `blockProducer`, `seed`, `archive`, `openminaplain`, `openminaseed`
- **Key Components**:
  - `helmfile.yaml.gotmpl`: Main orchestration file with role validation
  - `environment/defaults.yaml`: Node-level API schema and default values (590+ lines)
  - `templates/*.gotmpl`: Role-specific template overrides
  - `_helpers.tpl`: Template helper functions for value generation

## Development Commands

### Helm Chart Development (mina-daemon-chart)
```bash
# Navigate to chart directory
cd mina-daemon-chart

# Validate chart syntax and structure  
helm lint .

# Test template rendering with default values
helm template . --values values.yaml

# Test with extended ct-values (for CI/CD)
helm template . --values ct-values.yaml

# Update dependencies (PostgreSQL)
helm dependency update

# Package for distribution
helm package .

# Install locally for testing
helm install mina-daemon . --values values.yaml

# Upgrade existing installation
helm upgrade mina-daemon . --values values.yaml
```

### Helmfile Development (mina-node-orchestrator)
```bash
# Navigate to orchestrator directory
cd mina-node-orchestrator

# Validate helmfile syntax
helmfile lint

# Preview what would be deployed
helmfile diff

# Apply configurations (dry-run)
helmfile apply --dry-run

# Deploy to cluster
helmfile apply
```

## Configuration Hierarchy

The system uses a hierarchical configuration approach:

1. **Global Level** (`global.*`): Namespace, network settings
2. **Common Level** (`common.*`): Shared values across all node types  
3. **Role Defaults** (`defaults.<role>.*`): Per-role default configurations
4. **Node Instance** (`nodes.<identifier>.*`): Specific node overrides

## Key Configuration Patterns

### Image References
- **Community Standard**: Use `minaprotocol/mina-daemon` and `minaprotocol/mina-archive`
- **OpenMina Support**: Use OpenMina images for `openminaplain` and `openminaseed` roles
- **Backwards Compatibility**: Original `gcr.io/o1labs-192920/*` references have been replaced

### Annotations and Labels  
- **Community Standard**: Use `app.minaprotocol.org/baseline-chart`
- **Node Roles**: Use `node-role.minaprotocol.org` for node scheduling labels

### Container Configuration
All containers support the full Kubernetes container spec through the `_container.tpl` template:
- Image configuration, commands, and arguments
- Environment variables (both direct and from secrets)
- Port definitions with protocol support
- Volume mounts and persistent storage
- Health probes and resource constraints
- Security contexts

## Template Context Structure

When working with Go templates in `mina-node-orchestrator`, the context object contains:
- `.root`: Root helmfile context with global values
- `.node`: Node-specific configuration merged with role defaults

## Development Guidelines

### Generalization Requirements
- Replace all o1Labs-specific references with community-friendly alternatives
- Maintain backwards compatibility with existing API schemas
- Use generic Docker images from public registries
- Ensure templates work without GCP-specific configurations

### Chart Versioning
- Both charts use semantic versioning starting at `0.0.1`
- Chart versions should be incremented for any template or default value changes
- AppVersion reflects the Mina daemon version being deployed

### Testing and Validation
- Always run `helm lint` before committing changes to mina-daemon-chart
- Test template rendering with both `values.yaml` and `ct-values.yaml`
- Validate helmfile syntax with `helmfile lint` for mina-node-orchestrator changes
- Ensure role validation works correctly in `helmfile.yaml.gotmpl`
- Test backwards compatibility with existing mina-standard-node configurations

## OpenMina Node Support

### Supported OpenMina Roles
- **`openminaplain`**: Basic OpenMina node for network participation
  - Uses `openmina node` command with configurable peer lists
  - No initialization containers or key management required
  - Default ports: 3000 (external), 8302 (libp2p)
  
- **`openminaseed`**: OpenMina seed node for peer discovery
  - Includes `--seed` flag for seed node functionality
  - Supports P2P secret key management via `OPENMINA_P2P_SEC_KEY` environment variable
  - Default ports: 3080 (external), 8302 (libp2p)
  - LoadBalancer service type for external accessibility

### OpenMina Configuration Examples

```yaml
# Basic OpenMina plain node
nodes:
  openminaNode1:
    enable: true
    role: openminaplain
    name: openmina-plain-1
    values:
      daemon:
        ports:
          external:
            containerPort: 3080
            hostPort: 3080
          libp2p:
            containerPort: 8302
        service:
          type: ClusterIP
        resources:
          requests:
            cpu: "6"
            memory: 12Gi

# OpenMina seed node with custom configuration
nodes:
  openminaSeed1:
    enable: true
    role: openminaseed
    name: openmina-seed-1
    values:
      daemon:
        env:
          OPENMINA_FQDN: seed.example.com
        service:
          type: LoadBalancer
          annotations:
            external-dns.alpha.kubernetes.io/hostname: openmina-seed-1.example.com
```

### Backwards Compatibility Notes
- OpenMina nodes use different command structures (`openmina node` vs `mina daemon`)
- Secret management patterns differ (environment variables vs mounted files)
- Template structure follows existing patterns but with OpenMina-specific customizations
- All conditional logic uses `hasKey` patterns for consistency with mina-standard-node compatibility
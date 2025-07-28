# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Helm chart for Mina Daemon - a baseline Helm chart for deploying Mina blockchain nodes on Kubernetes. The chart provides a flexible foundation that other charts and orchestration tools can build upon.

> **Note**: This chart is forked from o1Labs' mina-standard-daemon chart and has been generalized for community use.

## Architecture

The chart follows a layered architecture approach:
1. **Orchestration level**: Users interact with high-level APIs (like helmfile configurations)
2. **Node level**: Specific node type configurations with custom templates
3. **Baseline level**: This `mina-daemon-chart` chart provides the core Kubernetes manifests

## Key Components

### Core Files
- `Chart.yaml`: Chart metadata and PostgreSQL dependency (v16.4.7 from Bitnami)
- `values.yaml`: Default configuration values
- `ct-values.yaml`: Extended values for chart testing (GitHub Actions)

### Templates
- `deployment.yaml`: Main deployment template with container orchestration
- `_helpers.tpl`: Helm template helpers for naming, labels, and service accounts
- `_container.tpl`: Reusable container template for daemon, archive, and extra containers
- `service.yaml`: Service definitions
- `ingress.yaml`: Ingress configuration
- `extraIngress.yaml`: Additional ingress resources
- `secrets.yaml`: Secret management
- `pvc.yaml`: Persistent volume claims
- `serviceaccount.yaml`: Service account configuration

### Configuration Structure

The chart supports multiple container types:
- **daemon**: Main Mina daemon container (required)
- **archive**: Optional archive container (enabled via `archive.enable`)
- **initContainers**: Initialization containers
- **extraContainers**: Additional sidecar containers

### Supported Node Roles
- `plain`: Basic node
- `coordinator`: Coordinator node
- `snarkWorker`: SNARK worker (supports replicas)
- `seed`: Seed node
- `archive`: Archive node

## Development Commands

This is a Helm chart project. Common commands:

```bash
# Validate the chart
helm lint .

# Test template rendering
helm template . --values values.yaml

# Test with ct-values
helm template . --values ct-values.yaml

# Package the chart
helm package .

# Install locally for testing
helm install mina-daemon . --values values.yaml

# Upgrade
helm upgrade mina-daemon . --values values.yaml
```

## Key Configuration Patterns

### Container Configuration
All containers use the `_container.tpl` template which supports:
- Image configuration (`repository`, `tag`, `pullPolicy`)
- Commands and arguments (`command`, `args`, `extraArgs`)
- Environment variables (`env`, `extraEnv`)
- Ports (`ports`, `extraPorts`)
- Volume mounts (`volumeMounts`, `extraVolumeMounts`)
- Probes (`livenessProbe`, `readinessProbe`)
- Resources and security contexts

### Extensibility
The chart is designed for maximum configurability:
- `extra*` fields for additional resources (containers, volumes, services, ingress)
- Template functions for consistent labeling and naming
- Backwards compatibility labels (`app`, `version`, `role`, `testnet`)

### Network Configuration
- Default network: `devnet`
- Configurable via `daemon.network`
- Used in labels for node identification

## Testing

The chart includes `ct-values.yaml` for comprehensive testing with chart-testing (ct) tool, which includes examples of:
- Multiple containers and init containers
- Archive container configuration
- Service and ingress configurations
- Volume and secret management
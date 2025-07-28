# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Helmfile-based Kubernetes chart that generates values for the `mina-daemon-chart` Helm Chart. It provides Node-level abstraction for deploying various types of Mina blockchain nodes (plain, blockProducer, coordinator, snarkWorker, seed, archive).

> **Note**: This chart is forked from o1Labs' mina-standard-node chart and has been generalized for community use.

## Architecture

The project follows a hierarchical template structure:
- **Node-level abstraction**: This chart generates values for downstream Charts
- **Templates**: Go template files (`.gotmpl`) that render Kubernetes manifests
- **Environment configuration**: Default values and schema definition
- **Orchestration**: DAG-based deployment using Helmfile with dependencies

## Key Files and Directories

- `helmfile.yaml.gotmpl`: Main orchestration file that generates helmfile releases for each node type
- `environment/defaults.yaml`: Default values and node-level API schema (590+ lines of configuration)
- `_helpers.tpl`: Helm template helper functions for efficient YAML generation
- `templates/`: Node-specific template files:
  - `plain.yaml.gotmpl`: Base template for all node types
  - `blockProducer.yaml.gotmpl`, `coordinator.yaml.gotmpl`, etc.: Role-specific overrides

## Supported Node Types

Valid node roles (validated in helmfile): `plain`, `coordinator`, `snarkWorker`, `blockProducer`, `seed`, `archive`

Each node type has specific:
- Port configurations (external, client, graphql, metrics)
- Environment variables
- Resource requirements
- Initialization requirements (keys, libp2p, genesis)

## Working with Templates

Templates use Go template syntax with Helm functions. The context object contains:
- `.node`: Node-specific configuration
- `.root`: Root context with global values

Common helper functions in `_helpers.tpl`:
- `mina-node-orchestrator.plain.image`: Image configuration
- `mina-node-orchestrator.plain.ports`: Port merging logic
- `mina-node-orchestrator.plain.env`: Environment variable generation
- `mina-node-orchestrator.plain.initContainers`: Init container definitions

## Configuration Structure

Default configuration hierarchy:
1. `global.*`: Global settings (namespace, network)
2. `common.*`: Shared values across all nodes
3. `defaults.<role>.*`: Role-specific defaults
4. `nodes.<identifier>.*`: Instance-specific overrides

## Dependencies

- Depends on `../mina-daemon-chart` chart
- Uses external services like PostgreSQL for archive nodes
- Requires secrets for keys, genesis configs, and credentials

## Development Notes

- All templates render to values that are passed to the downstream `mina-daemon-chart` chart
- Node deployment follows DAG pattern using the `needs` dependency system
- Templates support both secret-based and generated key management
- Archive nodes have special handling for PostgreSQL integration
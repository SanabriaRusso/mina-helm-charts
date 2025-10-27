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

Valid node roles (validated in helmfile): `plain`, `coordinator`, `snarkWorker`, `blockProducer`, `seed`, `archive`, `rosetta`, `minarustplain`, `minarustseed`, `minarustdashboard`, `minarustbp`

Each node type has specific:
- Port configurations (external, client, graphql, metrics, or custom)
- Environment variables
- Resource requirements
- Initialization requirements (keys, libp2p, genesis, or producer keys for BP)

## Working with Templates

Templates use Go template syntax with Helm functions. The context object contains:
- `.node`: Node-specific configuration
- `.root`: Root context with global values

Common helper functions in `_helpers.tpl`:
- `mina-standard-node.plain.*`: Standard Mina daemon helpers (image, ports, env, initContainers, volumes)
- `mina-standard-node.minarustbp.*`: Mina Rust BP-specific helpers (initContainers, volumes, volumeMounts, ports, service, env)
- `mina-standard-node.rosetta.*`: Rosetta-specific helpers (ports, service, env)
- Template naming follows pattern: `mina-standard-node.<role>.<component>`

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

## Adding New Node Roles

When adding a new node role (e.g., `minarustbp`):

1. **Update `helmfile.yaml.gotmpl`**: Add role to `$validNodeRoles` list
2. **Add defaults in `environment/defaults.yaml`**: Create new `defaults.<role>` section with:
   - `needs`: Dependencies on other releases
   - `templates`: List of `.gotmpl` files to process (usually `plain.yaml.gotmpl` + role-specific)
   - `values`: Complete default configuration including daemon, init, volumes, resources
3. **Create helper functions in `_helpers.tpl`**: Add role-specific helpers following pattern:
   - `mina-standard-node.<role>.initContainers`: Custom init container logic
   - `mina-standard-node.<role>.volumes`: Volume definitions
   - `mina-standard-node.<role>.volumeMounts`: Volume mount configuration
   - `mina-standard-node.<role>.ports`: Port configuration
   - `mina-standard-node.<role>.service`: Service configuration
   - `mina-standard-node.<role>.env`: Environment variable merging
4. **Create template file `templates/<role>.yaml.gotmpl`**: Override sections from `plain.yaml.gotmpl`:
   - `initContainers`: Custom initialization logic
   - `daemon.command` and `daemon.args`: Role-specific startup commands
   - `daemon.env`: Environment variables using helper
   - `daemon.ports`: Ports using helper
   - `daemon.volumeMounts`: Volume mounts using helper
   - `service`: Service configuration using helper
   - `volumes`: Volumes using helper

### Example: minarustbp Role

The `minarustbp` role demonstrates custom init containers for producer key generation:

**Key Differences from Standard Roles:**
- Uses `misc mina-encrypted-key` command in init container to generate producer keys
- Stores keys in shared `mina-keys` emptyDir volume (not standard init pattern)
- Main container references `/root/.mina/producer-key` in args
- No libp2p key generation (skipped via `libp2pKeys.skip: true`)
- Supports both generated and secret-based producer keys via `producerKey.fromSecret`

**Configuration Pattern:**
```yaml
nodes:
  myBp:
    enable: true
    role: minarustbp
    name: my-bp-1
    values:
      daemon:
        args:
          - |
            exec mina node \
            --producer-key /root/.mina/producer-key \
            --peers="..."
        env:
          MINA_PRIVKEY_PASS: "password"
        init:
          enable: true
          producerKey:
            generate: true
            password: "password"
```

### Template Testing

Test new roles with:
```bash
# Add test node to defaults.yaml or create test values file
helmfile template -l name=<node-name> --skip-deps
```
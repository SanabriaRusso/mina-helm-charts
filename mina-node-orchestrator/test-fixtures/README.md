# Test Fixtures for CI/CD Validation

This directory contains sanitized deployment configurations used for automated testing in GitHub Actions.

## Purpose

These fixtures validate that changes to `mina-node-orchestrator` don't break existing deployments by:
1. Testing template rendering for 14 production-like node configurations
2. Validating YAML syntax across all roles
3. Ensuring backwards compatibility
4. Checking for common configuration errors

## Fixtures

### devnet/
**Coverage**: 10 nodes across 5 roles
- **archive**: devnetArchive
- **coordinator**: devnetCoordinator, devnetBackupCoordinator
- **snarkWorker**: devnetSnarkWorker, devnetBackupSnarkWorker
- **seed**: devnetSeed1, devnetSeed2
- **blockProducer**: devnetWhale1, devnetWhale2, devnetWhale3

**Source**: Simplified from `mina-devnet-infra-2/mina-standard-devnet`

### rust-seeds/
**Coverage**: 2 nodes across 2 roles
- **minarustplain**: minaRustPlain1
- **minarustseed**: minaRustSeed1

**Source**: Simplified from `coda-infra-east/mina-rust-standard-seeds`

### rust-bps/
**Coverage**: 2 nodes across 1 role
- **minarustbp**: minaRustBp1, minaRustBp2

**Source**: Simplified from `coda-infra-east/mina-rust-standard-block-producers`

## Secret Sanitization

All secret references have been removed or replaced with test values:
- Passwords: `"test-postgres-password"`, `"test-password"`
- Keys: `"naughty blue worm"` (test passphrase)
- No actual secrets are stored in this repository

These sanitized values allow template rendering to succeed without requiring actual secrets.

## Role Coverage

| Role | Instances | Status |
|------|-----------|--------|
| archive | 1 | ✅ Tested |
| coordinator | 2 | ✅ Tested |
| snarkWorker | 2 | ✅ Tested |
| seed | 2 | ✅ Tested |
| blockProducer | 3 | ✅ Tested |
| minarustplain | 1 | ✅ Tested |
| minarustseed | 1 | ✅ Tested |
| minarustbp | 2 | ✅ Tested |
| rosetta | 0 | ⚠️ Not tested |
| minarustdashboard | 0 | ⚠️ Not tested |

**Total Coverage**: 9/11 roles (82%)

## Usage

### Local Testing

```bash
# Navigate to mina-node-orchestrator
cd mina-node-orchestrator

# Test all fixtures
./scripts/test-templates.sh

# Test specific fixture
./scripts/test-templates.sh devnet
```

**Requirements**: podman (or docker - set `CONTAINER_CMD=docker`)

The script uses the official `ghcr.io/helmfile/helmfile` container image, so you don't need to install helmfile, helm, or yq locally.

### CI/CD Testing

GitHub Actions automatically validates all fixtures on every PR:
- Workflow: `.github/workflows/validate-templates.yml`
- Uses the same `test-templates.sh` script as local testing
- Tests run in parallel using matrix strategy (3 fixtures)
- Triggers: PRs and pushes affecting `mina-node-orchestrator/`
- Runtime: ~3-5 minutes

## Updating Fixtures

When adding new roles or making significant changes:

1. Update the relevant fixture file in `test-fixtures/<fixture>/values.yaml`
2. Test locally: `./scripts/test-templates.sh`
3. Commit changes
4. CI/CD will validate automatically

## Maintenance

These fixtures should be updated when:
- New node roles are added
- Default configurations change significantly
- Production deployments evolve

To update from production:
1. Copy latest values from gitops-infrastructure
2. Manually sanitize secrets (replace with test values)
3. Simplify to essential configuration
4. Test rendering locally: `./scripts/test-templates.sh`
5. Commit updates

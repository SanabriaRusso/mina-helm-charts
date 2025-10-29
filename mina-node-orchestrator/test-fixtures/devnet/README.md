# Devnet Test Fixture

**Nodes**: 10
**Roles**: 5 (archive, coordinator, snarkWorker, seed, blockProducer)
**Network**: devnet

## Node List

| Node Name | Role | Purpose |
|-----------|------|---------|
| devnet-archive | archive | Archive node for storing blockchain history |
| devnet-coordinator | coordinator | Primary coordinator for SNARK workers |
| devnet-backup-coordinator | coordinator | Backup coordinator |
| devnet-snark-worker | snarkWorker | SNARK computation worker |
| devnet-backup-snark-worker | snarkWorker | Backup SNARK workers (replicas: 2) |
| devnet-standard-seed-1 | seed | Seed node for peer discovery |
| devnet-standard-seed-2 | seed | Additional seed node |
| devnet-standard-whale-1 | blockProducer | Block producer node |
| devnet-standard-whale-2 | blockProducer | Block producer node |
| devnet-standard-whale-3 | blockProducer | Block producer node |

## Configuration Highlights

- **Archive**: Includes PostgreSQL with test credentials
- **Coordinators**: Both enable init containers with genesis skip
- **SNARK Workers**: Backup worker uses replicas for scalability testing
- **Seeds**: LoadBalancer services for external accessibility
- **Block Producers**: All use insecure REST server for testing

## Testing

```bash
helmfile template --skip-deps \
  --state-values-file test-fixtures/devnet/values.yaml
```

# Rust Block Producers Test Fixture

**Nodes**: 2
**Roles**: 1 (minarustbp)
**Network**: mainnet

## Node List

| Node Name | Role | Purpose |
|-----------|------|---------|
| mina-rust-bp-1 | minarustbp | Mina Rust block producer node |
| mina-rust-bp-2 | minarustbp | Mina Rust block producer node |

## Configuration Highlights

- **Block Producers**: Both nodes configured with test key management
- Uses community-standard Mina Rust block producer images
- Test passphrase: "naughty blue worm" (sanitized for CI/CD)
- Includes basic resource requests and limits
- ClusterIP services for internal communication

## Testing

```bash
helmfile template --skip-deps \
  --state-values-file test-fixtures/rust-bps/values.yaml
```

# Rust Seeds Test Fixture

**Nodes**: 2
**Roles**: 2 (minarustplain, minarustseed)
**Network**: mainnet

## Node List

| Node Name | Role | Purpose |
|-----------|------|---------|
| mina-rust-plain-1 | minarustplain | Plain Mina Rust node for network participation |
| mina-rust-seed-1 | minarustseed | Mina Rust seed node for peer discovery |

## Configuration Highlights

- **Plain Node**: Standard Mina Rust node with basic configuration
- **Seed Node**: LoadBalancer service for external accessibility with dedicated peer management
- Both nodes use community-standard Mina Rust images
- No key management or initialization containers required

## Testing

```bash
helmfile template --skip-deps \
  --state-values-file test-fixtures/rust-seeds/values.yaml
```

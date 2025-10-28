#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "====================================="
echo "Extracting roles from defaults.yaml"
echo "====================================="

# Backup current file
cp environment/defaults.yaml environment/defaults.yaml.backup
echo "✓ Backed up to defaults.yaml.backup"

# Create directories
mkdir -p environment/roles
echo "✓ Created environment/roles/"

# Extract global & common
echo ""
echo "Extracting shared config..."
yq eval 'pick(["global", "common"])' environment/defaults.yaml > environment/_shared.yaml
echo "✓ Created _shared.yaml ($(wc -l < environment/_shared.yaml) lines)"

# Extract each role
echo ""
echo "Extracting individual roles..."
ROLES="plain blockProducer coordinator snarkWorker archive seed minarustplain minarustseed minarustdashboard minarustbp rosetta"

for role in $ROLES; do
  echo "  - Extracting $role..."
  yq eval ".defaults.$role" environment/defaults.yaml > "environment/roles/${role}.yaml"
  LINE_COUNT=$(wc -l < "environment/roles/${role}.yaml")
  echo "    ✓ Created ${role}.yaml (${LINE_COUNT} lines)"
done

# Extract example nodes
echo ""
echo "Extracting example nodes..."
yq eval '.nodes' environment/defaults.yaml > environment/_nodes.yaml
echo "✓ Created _nodes.yaml ($(wc -l < environment/_nodes.yaml) lines)"

echo ""
echo "====================================="
echo "✓ Extraction complete!"
echo "====================================="
echo ""
echo "Files created:"
echo "  - environment/_shared.yaml"
echo "  - environment/roles/*.yaml (11 files)"
echo "  - environment/_nodes.yaml"
echo ""
echo "Next step: Run scripts/merge-roles.sh to regenerate defaults.yaml"

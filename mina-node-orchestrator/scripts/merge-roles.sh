#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "====================================="
echo "Merging role files → defaults.yaml"
echo "====================================="

# Backup current defaults.yaml
if [[ -f environment/defaults.yaml ]]; then
  cp environment/defaults.yaml environment/defaults.yaml.pre-merge
  echo "✓ Backed up current defaults.yaml"
fi

# Build new defaults.yaml
{
  cat <<'EOF'
---
## ====================================================================
## GENERATED FILE - DO NOT EDIT DIRECTLY
## ====================================================================
## This file is auto-generated from:
##   - environment/_shared.yaml (global & common config)
##   - environment/roles/*.yaml (per-role defaults)
##   - environment/_nodes.yaml (example node instances)
##
## To modify:
##   1. Edit files in environment/roles/
##   2. Run: scripts/merge-roles.sh
##   3. Commit both role files and regenerated defaults.yaml
## ====================================================================

EOF

  # Add shared config (global & common)
  cat environment/_shared.yaml
  echo ""

  # Add defaults section with each role
  echo "## Role-specific defaults"
  echo "defaults:"

  ROLES="plain blockProducer coordinator snarkWorker archive seed minarustplain minarustseed minarustdashboard minarustbp rosetta"
  for role in $ROLES; do
    echo "  $role:"
    # Indent role content by 4 spaces
    sed 's/^/    /' "environment/roles/${role}.yaml"
  done

  echo ""
  # Add example nodes
  cat environment/_nodes.yaml

} > environment/defaults.yaml.new

# Validate new file is valid YAML
echo ""
echo "Validating generated YAML..."
if yq eval '.' environment/defaults.yaml.new > /dev/null 2>&1; then
  mv environment/defaults.yaml.new environment/defaults.yaml
  echo "✓ Validation passed"

  # Show statistics
  echo ""
  echo "====================================="
  echo "✓ Merge complete!"
  echo "====================================="
  echo ""
  echo "Generated defaults.yaml:"
  echo "  Lines: $(wc -l < environment/defaults.yaml)"
  echo "  Size:  $(du -h environment/defaults.yaml | cut -f1)"
  echo ""
  echo "File is ready for commit"
else
  echo "✗ Validation FAILED - invalid YAML generated"
  echo "  Preserving old defaults.yaml"
  echo "  Check environment/defaults.yaml.new for errors"
  exit 1
fi

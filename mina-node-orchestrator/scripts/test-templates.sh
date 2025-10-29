#!/usr/bin/env bash
#
# Template Validation Script for mina-node-orchestrator
#
# This script validates Helm templates for test fixtures.
# It works both locally (with podman) and in CI/CD pipelines.
#
# The script uses the official helmfile container image to avoid
# requiring developers to install helmfile, helm, and yq locally.
#
# Usage:
#   ./scripts/test-templates.sh [fixture-name]
#
# Examples:
#   ./scripts/test-templates.sh              # Test all fixtures
#   ./scripts/test-templates.sh devnet       # Test only devnet fixture
#
# Requirements:
#   - podman (or docker)
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#

set -euo pipefail

# Configuration
HELMFILE_IMAGE="${HELMFILE_IMAGE:-asia-northeast3-docker.pkg.dev/o1labs-192920/gitops-images/helmfile:1.1.8}"
PLATFORM="linux/amd64"
CONTAINER_CMD="${CONTAINER_CMD:-podman}"

# Script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SCRIPT_DIR/.."

# Test fixtures
FIXTURES=("devnet" "rust-seeds" "rust-bps")
FIXTURE_INFO=(
  "devnet:10:5:archive, coordinator, snarkWorker, seed, blockProducer"
  "rust-seeds:2:2:minarustplain, minarustseed"
  "rust-bps:2:1:minarustbp"
)
FAILED=0
TOTAL=0

# Colors for output
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Check for container runtime
if ! command -v "$CONTAINER_CMD" &> /dev/null; then
  echo -e "${RED}Error: $CONTAINER_CMD is not installed${NC}"
  echo ""
  echo "Please install podman or docker:"
  echo "  - macOS: brew install podman"
  echo "  - Linux: https://podman.io/getting-started/installation"
  echo ""
  echo "Or set CONTAINER_CMD=docker if you have docker installed"
  exit 1
fi

# Parse command line arguments
if [ $# -gt 0 ]; then
  FIXTURES=("$1")
  echo -e "${BLUE}Testing single fixture: $1${NC}"
else
  echo -e "${BLUE}Testing all fixtures${NC}"
fi

echo "========================================="
echo "Mina Node Orchestrator Template Tests"
echo "========================================="
echo ""
echo "Using: $CONTAINER_CMD"
echo "Image: $HELMFILE_IMAGE"
echo "Platform: $PLATFORM"
echo ""

# Helper function to run commands in helmfile container
run_in_container() {
  local cmd="$1"
  "$CONTAINER_CMD" run \
    --platform "$PLATFORM" \
    --rm \
    -v "${REPO_ROOT}:/workspace:z" \
    -w /workspace/mina-node-orchestrator \
    "$HELMFILE_IMAGE" \
    sh -c "$cmd"
}

# Step 1: Validate defaults.yaml synchronization (if merge-roles.sh exists)
if [ -f scripts/merge-roles.sh ] && [ "${SKIP_DEFAULTS_CHECK:-}" != "true" ]; then
  echo "========================================="
  echo "Step 1: Validating defaults.yaml"
  echo "========================================="
  echo ""

  # Create temp file for comparison
  cp environment/defaults.yaml /tmp/defaults.yaml.backup

  echo "Regenerating defaults.yaml from role files..."
  MERGE_OUTPUT=$(run_in_container "./scripts/merge-roles.sh" 2>&1)
  MERGE_EXIT=$?

  if [ $MERGE_EXIT -eq 0 ]; then
    # Compare
    if diff -wB /tmp/defaults.yaml.backup environment/defaults.yaml > /dev/null; then
      echo -e "${GREEN}✓ defaults.yaml is synchronized with role files${NC}"
    else
      echo -e "${RED}✗ defaults.yaml is OUT OF SYNC with role files${NC}"
      echo ""
      echo "Please run './scripts/merge-roles.sh' and commit the result"
      echo ""
      echo "Differences:"
      diff -u /tmp/defaults.yaml.backup environment/defaults.yaml | head -30 || true
      exit 1
    fi
  else
    echo -e "${YELLOW}⚠ merge-roles.sh validation failed, skipping${NC}"
    echo ""
    echo "Error output:"
    echo "$MERGE_OUTPUT" | head -20
    echo ""
    echo "Note: Set SKIP_DEFAULTS_CHECK=true to suppress this check"
  fi
  echo ""
fi

# Step 2: Test each fixture
echo "========================================="
echo "Step 2: Testing Template Rendering"
echo "========================================="
echo ""

for fixture in "${FIXTURES[@]}"; do
  echo "-----------------------------------"
  echo "Fixture: $fixture"
  echo "-----------------------------------"

  TOTAL=$((TOTAL + 1))
  FIXTURE_FAILED=0

  # Check fixture exists
  if [[ ! -f "test-fixtures/$fixture/values.yaml" ]]; then
    echo -e "${RED}✗ Fixture file not found: test-fixtures/$fixture/values.yaml${NC}"
    FAILED=$((FAILED + 1))
    echo ""
    continue
  fi

  # Validate YAML syntax
  echo -n "  Validating YAML syntax... "
  if run_in_container "yq eval '.' test-fixtures/$fixture/values.yaml" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    FIXTURE_FAILED=1
  fi

  # Test template rendering
  if [ $FIXTURE_FAILED -eq 0 ]; then
    echo -n "  Rendering templates... "
    if run_in_container "helmfile template --skip-deps --state-values-file test-fixtures/$fixture/values.yaml" > "/tmp/${fixture}-templates.yaml" 2>&1; then
      RESOURCE_COUNT=$(grep -c '^kind:' "/tmp/${fixture}-templates.yaml" || echo "0")
      echo -e "${GREEN}✓ ($RESOURCE_COUNT resources)${NC}"
    else
      echo -e "${RED}✗${NC}"
      echo ""
      echo "Error output:"
      cat "/tmp/${fixture}-templates.yaml" | tail -30
      FIXTURE_FAILED=1
    fi
  fi

  # Additional validations
  if [ $FIXTURE_FAILED -eq 0 ]; then
    # Check for unresolved variables
    echo -n "  Checking for unresolved variables... "
    if grep -E '\{\{.*\}\}' "/tmp/${fixture}-templates.yaml" | grep -v 'helm.sh/hook' > /dev/null; then
      echo -e "${RED}✗${NC}"
      grep -E '\{\{.*\}\}' "/tmp/${fixture}-templates.yaml" | grep -v 'helm.sh/hook' | head -3
      FIXTURE_FAILED=1
    else
      echo -e "${GREEN}✓${NC}"
    fi

    # Validate rendered YAML
    echo -n "  Validating rendered YAML... "
    # Filter out helmfile status lines and pipe through yq in container for validation
    if grep -v '^Templating release=' "/tmp/${fixture}-templates.yaml" | \
       "$CONTAINER_CMD" run --platform "$PLATFORM" --rm -i "$HELMFILE_IMAGE" sh -c "yq eval-all '.' >/dev/null"; then
      echo -e "${GREEN}✓${NC}"
    else
      echo -e "${RED}✗${NC}"
      FIXTURE_FAILED=1
    fi

    # Check for secret references
    echo -n "  Checking for leaked secrets... "
    if grep -i 'ref+gcpsecrets' "/tmp/${fixture}-templates.yaml" > /dev/null; then
      echo -e "${RED}✗${NC}"
      FIXTURE_FAILED=1
    else
      echo -e "${GREEN}✓${NC}"
    fi

    # Verify Kubernetes resources
    echo -n "  Verifying Kubernetes resources... "
    if ! grep -q '^apiVersion:' "/tmp/${fixture}-templates.yaml"; then
      echo -e "${RED}✗${NC}"
      FIXTURE_FAILED=1
    else
      echo -e "${GREEN}✓${NC}"
    fi
  fi

  if [ $FIXTURE_FAILED -eq 1 ]; then
    FAILED=$((FAILED + 1))
    echo -e "${RED}✗ Fixture failed${NC}"
  else
    echo -e "${GREEN}✓ Fixture passed${NC}"
  fi

  echo ""
done

# Step 3: Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All $TOTAL fixtures validated successfully${NC}"
  echo ""
  echo "Coverage:"
  for info in "${FIXTURE_INFO[@]}"; do
    IFS=':' read -r name nodes roles role_list <<< "$info"
    if [[ " ${FIXTURES[*]} " =~ " ${name} " ]]; then
      echo "  - $name: $nodes nodes across $roles roles"
    fi
  done
  echo ""
  exit 0
else
  echo -e "${RED}❌ $FAILED/$TOTAL fixtures failed validation${NC}"
  echo ""
  echo "Please review the errors above and fix the issues."
  exit 1
fi

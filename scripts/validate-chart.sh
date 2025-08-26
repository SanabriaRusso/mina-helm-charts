#!/bin/bash
set -e

# Validation script for mina-daemon-chart
# This script replicates the GitHub Actions workflow locally for testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$REPO_ROOT/mina-daemon-chart"

echo "🔍 Validating mina-daemon-chart..."
echo "Chart directory: $CHART_DIR"
echo ""

# Check if we're in the right directory
if [[ ! -d "$CHART_DIR" ]]; then
    echo "❌ Chart directory not found: $CHART_DIR"
    exit 1
fi

cd "$CHART_DIR"

echo "📋 Step 1: Checking prerequisites..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "❌ yq is not installed. Please install yq first (https://github.com/mikefarah/yq)"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

echo "🏗️  Step 2: Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo "✅ Repositories added"
echo ""

echo "📦 Step 3: Updating dependencies..."
helm dependency update
echo "✅ Dependencies updated"
echo ""

echo "🔍 Step 4: Linting chart..."
echo "  Testing with values.yaml..."
helm lint . --values values.yaml

echo "  Testing with ct-values.yaml..."
helm lint . --values ct-values.yaml
echo "✅ Lint tests passed"
echo ""

echo "🎨 Step 5: Template rendering tests..."
echo "  Rendering with values.yaml..."
helm template test-release . --values values.yaml > /tmp/template-values.yaml

echo "  Rendering with ct-values.yaml..."
helm template test-release . --values ct-values.yaml > /tmp/template-ct-values.yaml

echo "  Validating YAML syntax..."
python3 -c "import yaml; yaml.safe_load(open('/tmp/template-values.yaml'))" 2>/dev/null || {
    echo "❌ Invalid YAML in template output (values.yaml)"
    exit 1
}

python3 -c "import yaml; yaml.safe_load(open('/tmp/template-ct-values.yaml'))" 2>/dev/null || {
    echo "❌ Invalid YAML in template output (ct-values.yaml)"
    exit 1
}

echo "  Counting rendered resources..."
template_files=$(find templates -name "*.yaml" -o -name "*.tpl" | grep -v "NOTES.txt" | wc -l)
rendered_resources_values=$(grep -c "^---" /tmp/template-values.yaml || echo "0")
rendered_resources_ct=$(grep -c "^---" /tmp/template-ct-values.yaml || echo "0")

echo "    Template files: $template_files"
echo "    Rendered resources (values.yaml): $rendered_resources_values"
echo "    Rendered resources (ct-values.yaml): $rendered_resources_ct"

echo "✅ Template rendering tests passed"
echo ""

echo "🔒 Step 6: Security validation..."
echo "  Checking for hardcoded secrets..."
if grep -r -i "password\|secret\|token\|key" templates/ 2>/dev/null | grep -v "secretName\|secret:\|\.key" | grep -v "^#"; then
    echo "⚠️  Warning: Potential hardcoded secrets found in templates"
    echo "Please review the above matches to ensure they are template references, not hardcoded values"
else
    echo "✅ No hardcoded secrets detected"
fi

echo "  Checking for privileged containers..."
if grep -r "privileged.*true" templates/ 2>/dev/null; then
    echo "❌ Privileged containers detected"
    exit 1
else
    echo "✅ No privileged containers detected"
fi

echo "  Checking for hostNetwork usage..."
if grep -r "hostNetwork.*true" templates/ 2>/dev/null; then
    echo "❌ hostNetwork usage detected"
    exit 1
else
    echo "✅ No hostNetwork usage detected"
fi
echo ""

echo "📊 Step 7: Chart metadata validation..."
# Check required fields
name=$(yq eval '.name' Chart.yaml)
version=$(yq eval '.version' Chart.yaml)
description=$(yq eval '.description' Chart.yaml)
appVersion=$(yq eval '.appVersion' Chart.yaml)

if [[ -z "$name" ]] || [[ "$name" == "null" ]]; then
    echo "❌ Chart name is missing"
    exit 1
fi

if [[ -z "$version" ]] || [[ "$version" == "null" ]]; then
    echo "❌ Chart version is missing"
    exit 1
fi

if [[ -z "$description" ]] || [[ "$description" == "null" ]]; then
    echo "❌ Chart description is missing"
    exit 1
fi

if [[ -z "$appVersion" ]] || [[ "$appVersion" == "null" ]]; then
    echo "❌ Chart appVersion is missing"
    exit 1
fi

# Validate semver
if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Chart version must follow semantic versioning (current: $version)"
    exit 1
fi

echo "✅ Chart metadata validation passed"
echo "    Name: $name"
echo "    Version: $version"
echo "    Description: $description"
echo "    App Version: $appVersion"
echo ""

echo "🎉 All validations passed!"
echo ""
echo "📥 Next steps:"
echo "1. Commit your changes and create a pull request"
echo "2. The PR validation workflow will run automatically"
echo "3. Once merged to master, the release workflow will:"
echo "   - Create tag: v$version"
echo "   - Push to OCI registry: oci://ghcr.io/$(echo "$USER" | tr '[:upper:]' '[:lower:]')/charts/$name"
echo ""

# Clean up temp files
rm -f /tmp/template-values.yaml /tmp/template-ct-values.yaml

echo "✨ Validation complete!"
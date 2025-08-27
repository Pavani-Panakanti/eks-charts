#!/bin/bash
set -e

# Validate that no instance appears in both supportedInstanceLabels and privilegedSupportedInstanceLabels

CHART_DIR="$(dirname "$0")/.."
VALUES_FILE="$CHART_DIR/values.yaml"

if [ ! -f "$VALUES_FILE" ]; then
    echo "ERROR: values.yaml not found at $VALUES_FILE"
    exit 1
fi

# Extract instance lists using yq
STANDARD_INSTANCES=$(yq '.supportedInstanceLabels.values[]' "$VALUES_FILE" 2>/dev/null || echo "")
PRIVILEGED_INSTANCES=$(yq '.privilegedSupportedInstanceLabels.values[]' "$VALUES_FILE" 2>/dev/null || echo "")

if [ -z "$STANDARD_INSTANCES" ] && [ -z "$PRIVILEGED_INSTANCES" ]; then
    echo "WARNING: Could not extract instance lists. Ensure yq is installed."
    exit 0
fi

# Check for duplicates
DUPLICATES=""
for instance in $PRIVILEGED_INSTANCES; do
    if echo "$STANDARD_INSTANCES" | grep -q "^$instance$"; then
        DUPLICATES="$DUPLICATES $instance"
    fi
done

if [ -n "$DUPLICATES" ]; then
    echo "ERROR: The following instances appear in both supportedInstanceLabels and privilegedSupportedInstanceLabels:"
    for dup in $DUPLICATES; do
        echo "  - $dup"
    done
    echo ""
    echo "Each instance should appear in exactly one list to prevent dual DaemonSets."
    exit 1
fi

echo "✅ Validation passed: No instances appear in both lists"
exit 0
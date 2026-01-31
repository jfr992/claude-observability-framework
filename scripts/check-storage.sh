#!/bin/bash
#
# Check storage usage for Claude Metrics stack
# Run periodically or when concerned about disk space
#

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$SCRIPT_DIR/data"

# Limits (should match docker-compose and loki-config)
PROMETHEUS_LIMIT="1GB"
WARN_THRESHOLD_PERCENT=80

echo "=== Claude Metrics Storage Report ==="
echo "Data directory: $DATA_DIR"
echo ""

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "Data directory not found. Stack may not have been started yet."
    exit 0
fi

# Get sizes
PROMETHEUS_SIZE=$(du -sh "$DATA_DIR/prometheus" 2>/dev/null | cut -f1)
LOKI_SIZE=$(du -sh "$DATA_DIR/loki" 2>/dev/null | cut -f1)
GRAFANA_SIZE=$(du -sh "$DATA_DIR/grafana" 2>/dev/null | cut -f1)
TOTAL_SIZE=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)

echo "Component       Size        Limit       Retention"
echo "─────────────────────────────────────────────────"
printf "%-15s %-11s %-11s %s\n" "Prometheus" "$PROMETHEUS_SIZE" "$PROMETHEUS_LIMIT" "30 days"
printf "%-15s %-11s %-11s %s\n" "Loki" "$LOKI_SIZE" "n/a" "30 days"
printf "%-15s %-11s %-11s %s\n" "Grafana" "$GRAFANA_SIZE" "n/a" "∞ (config only)"
echo "─────────────────────────────────────────────────"
printf "%-15s %-11s\n" "TOTAL" "$TOTAL_SIZE"
echo ""

# Get bytes for comparison
PROMETHEUS_BYTES=$(du -s "$DATA_DIR/prometheus" 2>/dev/null | cut -f1)
PROMETHEUS_LIMIT_BYTES=$((1024 * 1024)) # 1GB in KB

if [ -n "$PROMETHEUS_BYTES" ]; then
    PERCENT=$((PROMETHEUS_BYTES * 100 / PROMETHEUS_LIMIT_BYTES))
    if [ "$PERCENT" -gt "$WARN_THRESHOLD_PERCENT" ]; then
        echo "⚠️  WARNING: Prometheus at ${PERCENT}% of limit"
        echo "   Consider reducing retention or increasing limit"
    else
        echo "✅ Storage healthy (Prometheus at ${PERCENT}% of limit)"
    fi
fi

echo ""
echo "To reclaim space immediately:"
echo "  podman compose down"
echo "  rm -rf $DATA_DIR/prometheus/* $DATA_DIR/loki/*"
echo "  podman compose up -d"

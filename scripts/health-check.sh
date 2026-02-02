#!/bin/bash
#
# Quick health check for Claude Code metrics
# Verifies the stack is working and shows key metrics
#

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

echo "=== Claude Code Metrics Health Check ==="
echo ""

# Check if Prometheus is up
if ! curl -s "$PROMETHEUS_URL/-/healthy" > /dev/null 2>&1; then
    echo "❌ Prometheus is not reachable at $PROMETHEUS_URL"
    echo "   Run: podman compose up -d"
    exit 1
fi
echo "✅ Prometheus is healthy"

# Check Grafana
if curl -s "http://localhost:3000/api/health" > /dev/null 2>&1; then
    echo "✅ Grafana is healthy"
else
    echo "⚠️  Grafana is not reachable"
fi

# Check Loki
if curl -s "http://localhost:3100/ready" > /dev/null 2>&1; then
    echo "✅ Loki is healthy"
else
    echo "⚠️  Loki is not reachable"
fi

# Check for any Claude metrics
METRICS=$(curl -s "$PROMETHEUS_URL/api/v1/label/__name__/values" 2>/dev/null | jq -r '.data[]' 2>/dev/null | grep -c claude || echo "0")
echo ""
if [ "$METRICS" -eq 0 ]; then
    echo "⚠️  No Claude Code metrics found"
    echo "   Have you run a session with telemetry enabled?"
    echo "   Check: echo \$CLAUDE_CODE_ENABLE_TELEMETRY"
else
    echo "✅ Found $METRICS Claude Code metric types"
fi

# Get key metrics
echo ""
echo "─────────────────────────────────────"
echo "KEY METRICS"
echo "─────────────────────────────────────"

# Cost
COST=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_cost_usage_USD_total)" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
printf "Total Cost:        \$%s\n" "$COST"

# Sessions
SESSIONS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=count(count%20by%20(session_id)(claude_code_cost_usage_USD_total))" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
printf "Sessions:          %s\n" "$SESSIONS"

# Tokens
TOKENS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_token_usage_tokens_total)" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
printf "Total Tokens:      %s\n" "$TOKENS"

# Accept rate
ACCEPTS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total{decision=\"accept\"})" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
REJECTS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total{decision=\"reject\"})" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
TOTAL=$((ACCEPTS + REJECTS))

if [ "$TOTAL" -gt 0 ]; then
    RATE=$((ACCEPTS * 100 / TOTAL))
    printf "Accept Rate:       %s%% (%s/%s)\n" "$RATE" "$ACCEPTS" "$TOTAL"
else
    printf "Accept Rate:       N/A (no edit decisions yet)\n"
fi

# Cache Hit Rate
CACHE_READ=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_token_usage_tokens_total{type=\"cacheRead\"})" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
CACHE_CREATE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_token_usage_tokens_total{type=\"cacheCreation\"})" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
CACHE_TOTAL=$(awk "BEGIN {printf \"%.0f\", $CACHE_READ + $CACHE_CREATE}")
if [ "$CACHE_TOTAL" -gt 0 ]; then
    CACHE_HIT_RATE=$(awk "BEGIN {printf \"%.1f\", 100 * $CACHE_READ / $CACHE_TOTAL}")
    printf "Cache Hit Rate:    %s%%\n" "$CACHE_HIT_RATE"
else
    printf "Cache Hit Rate:    N/A\n"
fi

echo ""
echo "─────────────────────────────────────"
echo "HEALTH ASSESSMENT"
echo "─────────────────────────────────────"

# Assess accept rate
if [ "$TOTAL" -gt 0 ]; then
    if [ "$RATE" -gt 95 ]; then
        echo "⚠️  Accept Rate ${RATE}% is high - are you reviewing critically?"
    elif [ "$RATE" -lt 50 ]; then
        echo "⚠️  Accept Rate ${RATE}% is low - check your CLAUDE.md"
    elif [ "$RATE" -ge 75 ] && [ "$RATE" -le 85 ]; then
        echo "✅ Accept Rate ${RATE}% is optimal"
    else
        echo "✅ Accept Rate ${RATE}% is healthy"
    fi
fi

# Assess cache hit rate
if [ "$CACHE_TOTAL" -gt 0 ]; then
    CACHE_INT=${CACHE_HIT_RATE%.*}
    if [ "$CACHE_INT" -lt 70 ]; then
        echo "- Cache Hit Rate ${CACHE_HIT_RATE}% is low - improve your CLAUDE.md"
    elif [ "$CACHE_INT" -ge 90 ]; then
        echo "- Cache Hit Rate ${CACHE_HIT_RATE}% is excellent"
    else
        echo "- Cache Hit Rate ${CACHE_HIT_RATE}% is good"
    fi
fi

# Assess session size
if [ "$SESSIONS" -gt 0 ] && [ "${TOKENS%.*}" -gt 0 ]; then
    TOKENS_PER_SESSION=$(awk "BEGIN {printf \"%.0f\", $TOKENS / $SESSIONS}")
    if [ "$TOKENS_PER_SESSION" -gt 300000 ]; then
        echo "⚠️  Session Size ${TOKENS_PER_SESSION} tokens - consider fresh sessions"
    elif [ "$TOKENS_PER_SESSION" -lt 100000 ]; then
        echo "✅ Session Size ${TOKENS_PER_SESSION} tokens - efficient"
    else
        echo "✅ Session Size ${TOKENS_PER_SESSION} tokens - moderate"
    fi
fi

echo ""
echo "Dashboard: http://localhost:3000"
echo ""

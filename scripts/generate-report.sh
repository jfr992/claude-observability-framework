#!/bin/bash
#
# Claude Code ROI Report Generator
# Fetches metrics from Prometheus and generates a markdown report
#
# Usage:
#   ./scripts/generate-report.sh              # Last 7 days
#   RANGE=30d ./scripts/generate-report.sh    # Last 30 days
#   ./scripts/generate-report.sh > report.md  # Save to file
#

set -e

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
RANGE="${RANGE:-7d}"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }

# Helper to query Prometheus
prom_query() {
    local query="$1"
    local encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$query'''))")
    curl -s "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" | jq -r '.data.result[0].value[1] // "0"'
}

prom_query_labels() {
    local query="$1"
    local encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$query'''))")
    curl -s "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" | jq -r '.data.result'
}

log "Fetching metrics from Prometheus (range: $RANGE)..."

# Core metrics
TOTAL_COST=$(prom_query "sum(claude_code_cost_usage_USD_total)")
TOTAL_TOKENS=$(prom_query "sum(claude_code_token_usage_tokens_total)")
TOTAL_SESSIONS=$(prom_query "count(count by (session_id) (claude_code_cost_usage_USD_total))")
TOTAL_PRS=$(prom_query "sum(claude_code_pull_request_count_total)")
TOTAL_COMMITS=$(prom_query "sum(claude_code_commit_count_total)")
ACTIVE_USERS=$(prom_query "count(count by (user_email) (claude_code_cost_usage_USD_total))")

# Token breakdown
INPUT_TOKENS=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"input\"})")
OUTPUT_TOKENS=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"output\"})")
CACHE_READ=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"cacheRead\"})")
CACHE_CREATE=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"cacheCreation\"})")

# Accept rate
ACCEPTS=$(prom_query "sum(claude_code_code_edit_tool_decision_total{decision=\"accept\"})")
TOTAL_DECISIONS=$(prom_query "sum(claude_code_code_edit_tool_decision_total)")

# Calculate derived metrics
COST_PER_SESSION=$(echo "scale=4; $TOTAL_COST / ($TOTAL_SESSIONS + 0.0001)" | bc)
COST_PER_PR=$(echo "scale=2; $TOTAL_COST / ($TOTAL_PRS + 0.0001)" | bc)
COST_PER_USER=$(echo "scale=2; $TOTAL_COST / ($ACTIVE_USERS + 0.0001)" | bc)
TOKENS_PER_SESSION=$(echo "scale=0; $TOTAL_TOKENS / ($TOTAL_SESSIONS + 1)" | bc)
CACHE_RATIO=$(echo "scale=1; $CACHE_READ / ($CACHE_CREATE + 1)" | bc)
ACCEPT_RATE=$(echo "scale=1; 100 * $ACCEPTS / ($TOTAL_DECISIONS + 1)" | bc)

# Cost by model
COST_BY_MODEL=$(prom_query_labels "sum by (model) (claude_code_cost_usage_USD_total)")

# Cost by user
COST_BY_USER=$(prom_query_labels "sum by (user_email) (claude_code_cost_usage_USD_total)")

log "Generating report..."

# Generate report
cat << EOF
# Claude Code ROI Report
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Period:** Last ${RANGE}

## Executive Summary

| Metric | Value | Assessment |
|--------|-------|------------|
| **Total Cost** | \$${TOTAL_COST} | - |
| **Active Users** | ${ACTIVE_USERS} | - |
| **Total Sessions** | ${TOTAL_SESSIONS} | - |
| **Cost/Session** | \$${COST_PER_SESSION} | $([ $(echo "$COST_PER_SESSION < 0.10" | bc) -eq 1 ] && echo "Good" || echo "Monitor") |
| **Cost/User** | \$${COST_PER_USER} | - |

## Productivity Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **PRs Created** | ${TOTAL_PRS} | Via Claude Code |
| **Commits** | ${TOTAL_COMMITS} | Via Claude Code |
| **Cost/PR** | \$${COST_PER_PR} | Target: <\$5 |
| **Accept Rate** | ${ACCEPT_RATE}% | Optimal: 75-85% |

## Efficiency Indicators

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **Cache Ratio** | ${CACHE_RATIO}:1 | >20 = excellent | $([ $(echo "$CACHE_RATIO > 20" | bc) -eq 1 ] && echo "Excellent" || ([ $(echo "$CACHE_RATIO > 10" | bc) -eq 1 ] && echo "Good" || echo "Needs Work")) |
| **Tokens/Session** | ${TOKENS_PER_SESSION} | <100k = efficient | $([ $(echo "$TOKENS_PER_SESSION < 100000" | bc) -eq 1 ] && echo "Efficient" || ([ $(echo "$TOKENS_PER_SESSION < 300000" | bc) -eq 1 ] && echo "Monitor" || echo "High Risk")) |
| **Accept Rate** | ${ACCEPT_RATE}% | 75-85% = optimal | $([ $(echo "$ACCEPT_RATE >= 75 && $ACCEPT_RATE <= 85" | bc) -eq 1 ] && echo "Optimal" || ([ $(echo "$ACCEPT_RATE > 95" | bc) -eq 1 ] && echo "Rubber Stamping?" || echo "Review")) |

## Token Breakdown

| Type | Tokens | % of Total |
|------|--------|------------|
| Input | ${INPUT_TOKENS} | $(echo "scale=1; 100 * $INPUT_TOKENS / ($TOTAL_TOKENS + 1)" | bc)% |
| Output | ${OUTPUT_TOKENS} | $(echo "scale=1; 100 * $OUTPUT_TOKENS / ($TOTAL_TOKENS + 1)" | bc)% |
| Cache Read | ${CACHE_READ} | $(echo "scale=1; 100 * $CACHE_READ / ($TOTAL_TOKENS + 1)" | bc)% |
| Cache Creation | ${CACHE_CREATE} | $(echo "scale=1; 100 * $CACHE_CREATE / ($TOTAL_TOKENS + 1)" | bc)% |

## Cost by Model

$(echo "$COST_BY_MODEL" | jq -r '.[] | "| \(.metric.model) | $\(.value[1]) |"' 2>/dev/null || echo "| No data | - |")

## Cost by User

$(echo "$COST_BY_USER" | jq -r '.[] | "| \(.metric.user_email) | $\(.value[1]) |"' 2>/dev/null || echo "| No data | - |")

## Subscription Break-Even Analysis

Based on current API usage of \$${TOTAL_COST}:

| Plan | Monthly Cost | Your Usage | Recommendation |
|------|--------------|------------|----------------|
| Claude Pro | \$20/user | \$${COST_PER_USER}/user | $([ $(echo "$COST_PER_USER > 20" | bc) -eq 1 ] && echo "Consider Pro" || echo "API is cheaper") |
| Claude Max 5x | \$100/user | \$${COST_PER_USER}/user | $([ $(echo "$COST_PER_USER > 100" | bc) -eq 1 ] && echo "Consider Max 5x" || echo "API is cheaper") |
| Claude Max 20x | \$200/user | \$${COST_PER_USER}/user | $([ $(echo "$COST_PER_USER > 200" | bc) -eq 1 ] && echo "Consider Max 20x" || echo "API is cheaper") |

## Recommendations

EOF

# Generate recommendations based on metrics
if [ $(echo "$CACHE_RATIO < 10" | bc) -eq 1 ]; then
    echo "1. **Improve CLAUDE.md**: Cache ratio of ${CACHE_RATIO}:1 is low. Better project documentation will improve cache efficiency."
fi

if [ $(echo "$ACCEPT_RATE > 95" | bc) -eq 1 ]; then
    echo "2. **Review Accept Behavior**: ${ACCEPT_RATE}% accept rate suggests rubber-stamping. Encourage critical review of suggestions."
fi

if [ $(echo "$ACCEPT_RATE < 60" | bc) -eq 1 ]; then
    echo "2. **Prompt Engineering Training**: ${ACCEPT_RATE}% accept rate is low. Train developers on effective prompting."
fi

if [ $(echo "$TOKENS_PER_SESSION > 300000" | bc) -eq 1 ]; then
    echo "3. **Session Management**: ${TOKENS_PER_SESSION} tokens/session is high. Use /compact or start fresh sessions more often."
fi

if [ $(echo "$COST_PER_PR > 10" | bc) -eq 1 ]; then
    echo "4. **Cost Efficiency**: \$${COST_PER_PR}/PR is above target. Review usage patterns for optimization."
fi

cat << EOF

---
*Report generated by claude-metrics. Dashboard: http://localhost:3000*
EOF

log "Report complete."

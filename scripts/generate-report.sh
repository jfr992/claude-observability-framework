#!/bin/bash
#
# Claude Code Communication Quality Report
# Measures how well you're collaborating with Claude
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
ACTIVE_USERS=$(prom_query "count(count by (user_email) (claude_code_cost_usage_USD_total))")

# Token breakdown
INPUT_TOKENS=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"input\"})")
OUTPUT_TOKENS=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"output\"})")
CACHE_READ=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"cacheRead\"})")
CACHE_CREATE=$(prom_query "sum(claude_code_token_usage_tokens_total{type=\"cacheCreation\"})")

# Accept rate
ACCEPTS=$(prom_query "sum(claude_code_code_edit_tool_decision_total{decision=\"accept\"})")
TOTAL_DECISIONS=$(prom_query "sum(claude_code_code_edit_tool_decision_total)")

# Calculate derived metrics (the three that matter)
TOKENS_PER_SESSION=$(echo "scale=0; $TOTAL_TOKENS / ($TOTAL_SESSIONS + 1)" | bc)
CACHE_RATIO=$(echo "scale=1; $CACHE_READ / ($CACHE_CREATE + 1)" | bc)
ACCEPT_RATE=$(echo "scale=1; 100 * $ACCEPTS / ($TOTAL_DECISIONS + 1)" | bc)

# Cost metrics (informational, not for comparison)
COST_PER_SESSION=$(echo "scale=4; $TOTAL_COST / ($TOTAL_SESSIONS + 0.0001)" | bc)
COST_PER_USER=$(echo "scale=2; $TOTAL_COST / ($ACTIVE_USERS + 0.0001)" | bc)

# Cost by model
COST_BY_MODEL=$(prom_query_labels "sum by (model) (claude_code_cost_usage_USD_total)")

log "Generating report..."

# Generate report
cat << EOF
# Claude Code Communication Quality Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Period:** Last ${RANGE}

---

## Communication Quality (The Three Metrics That Matter)

| Metric | Value | Target | Assessment |
|--------|-------|--------|------------|
| **Cache Ratio** | ${CACHE_RATIO}:1 | >20:1 | $([ $(echo "$CACHE_RATIO > 20" | bc) -eq 1 ] && echo "✅ Excellent - Claude understands your context" || ([ $(echo "$CACHE_RATIO > 10" | bc) -eq 1 ] && echo "✅ Good" || echo "⚠️ Improve your CLAUDE.md")) |
| **Session Size** | ${TOKENS_PER_SESSION} tokens | <100k | $([ $(echo "$TOKENS_PER_SESSION < 100000" | bc) -eq 1 ] && echo "✅ Efficient" || ([ $(echo "$TOKENS_PER_SESSION < 300000" | bc) -eq 1 ] && echo "⚠️ Getting long" || echo "❌ Too long - start fresh more often")) |
| **Accept Rate** | ${ACCEPT_RATE}% | 75-85% | $([ $(echo "$ACCEPT_RATE >= 75 && $ACCEPT_RATE <= 85" | bc) -eq 1 ] && echo "✅ Optimal - engaged review" || ([ $(echo "$ACCEPT_RATE > 95" | bc) -eq 1 ] && echo "⚠️ Too high - are you rubber-stamping?" || ([ $(echo "$ACCEPT_RATE < 60" | bc) -eq 1 ] && echo "⚠️ Too low - Claude misunderstands you" || echo "✅ Healthy"))) |

### What These Tell You

- **Cache Ratio** = Is your CLAUDE.md communicating context effectively?
- **Session Size** = Are you being efficient or going in circles?
- **Accept Rate** = Are you still the Architect or just clicking accept?

---

## Usage Summary

| Metric | Value |
|--------|-------|
| Total Cost | \$${TOTAL_COST} |
| Total Tokens | ${TOTAL_TOKENS} |
| Sessions | ${TOTAL_SESSIONS} |
| Active Users | ${ACTIVE_USERS} |
| Cost/Session | \$${COST_PER_SESSION} |
| Cost/User | \$${COST_PER_USER} |

## Token Breakdown

| Type | Tokens | % of Total |
|------|--------|------------|
| Input | ${INPUT_TOKENS} | $(echo "scale=1; 100 * $INPUT_TOKENS / ($TOTAL_TOKENS + 1)" | bc)% |
| Output | ${OUTPUT_TOKENS} | $(echo "scale=1; 100 * $OUTPUT_TOKENS / ($TOTAL_TOKENS + 1)" | bc)% |
| Cache Read | ${CACHE_READ} | $(echo "scale=1; 100 * $CACHE_READ / ($TOTAL_TOKENS + 1)" | bc)% |
| Cache Creation | ${CACHE_CREATE} | $(echo "scale=1; 100 * $CACHE_CREATE / ($TOTAL_TOKENS + 1)" | bc)% |

## Cost by Model

| Model | Cost |
|-------|------|
$(echo "$COST_BY_MODEL" | jq -r '.[] | "| \(.metric.model) | $\(.value[1]) |"' 2>/dev/null || echo "| No data | - |")

---

## Recommendations

EOF

# Generate recommendations based on communication metrics
RECS=0

if [ $(echo "$CACHE_RATIO < 10" | bc) -eq 1 ]; then
    RECS=$((RECS + 1))
    cat << EOF
### ${RECS}. Improve Your CLAUDE.md

Cache ratio of ${CACHE_RATIO}:1 means Claude is rebuilding context frequently.

**Action:** Add to your CLAUDE.md:
- Architecture decisions and patterns
- Security requirements
- Code style preferences
- Examples of good code in your codebase

EOF
fi

if [ $(echo "$ACCEPT_RATE > 95" | bc) -eq 1 ]; then
    RECS=$((RECS + 1))
    cat << EOF
### ${RECS}. Slow Down and Review

Accept rate of ${ACCEPT_RATE}% suggests you might be rubber-stamping.

**Action:** Before accepting, ask yourself:
- Would I have written it this way?
- Does this follow our security requirements?
- Are there edge cases not handled?

EOF
fi

if [ $(echo "$ACCEPT_RATE < 60" | bc) -eq 1 ]; then
    RECS=$((RECS + 1))
    cat << EOF
### ${RECS}. Help Claude Understand You

Accept rate of ${ACCEPT_RATE}% means Claude often misunderstands your intent.

**Action:**
- Add more examples to your CLAUDE.md
- Be more specific in your prompts
- Include constraints and acceptance criteria

EOF
fi

if [ $(echo "$TOKENS_PER_SESSION > 300000" | bc) -eq 1 ]; then
    RECS=$((RECS + 1))
    cat << EOF
### ${RECS}. Start Fresh More Often

${TOKENS_PER_SESSION} tokens per session is high. Context compaction may be losing details.

**Action:**
- Start new sessions for new tasks
- Use /compact when context gets stale
- Break large tasks into phases

EOF
fi

if [ "$RECS" -eq 0 ]; then
    echo "✅ All communication metrics look healthy!"
    echo ""
fi

cat << EOF
---

*Remember: These metrics measure communication quality, not productivity.*
*The goal is better collaboration, not more output.*

*Dashboard: http://localhost:3000*
EOF

log "Report complete."

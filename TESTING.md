# Testing the Observability Framework

This guide helps you verify your Claude Code metrics setup is working correctly and demonstrates what healthy developer behavior looks like.

## Quick Verification

After setting up the stack, run this to verify metrics are flowing:

```bash
# Check all services are healthy
podman compose ps

# Verify Prometheus is receiving metrics
curl -s 'http://localhost:9090/api/v1/label/__name__/values' | jq -r '.data[]' | grep claude

# Check accept/reject tracking
curl -s 'http://localhost:9090/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total)%20by%20(decision)' | jq '.data.result'
```

## The Critical Thinking Test

This test generates realistic metrics by proposing a mix of good and bad edits. **The goal is to practice and demonstrate healthy AI collaboration patterns.**

### Setup

```bash
# Create a test project
mkdir -p /tmp/claude-test-project
cd /tmp/claude-test-project
git init

# Create a simple file to edit
cat > utils.py << 'EOF'
"""Utility functions for data processing."""

def calculate_average(numbers):
    """Calculate the average of a list of numbers."""
    if not numbers:
        return 0
    return sum(numbers) / len(numbers)


def format_currency(amount):
    """Format a number as USD currency."""
    return f"${amount:.2f}"


def validate_email(email):
    """Basic email validation."""
    return "@" in email and "." in email
EOF

git add utils.py
git commit -m "Add initial utility functions"
```

### The Test Pattern

Ask Claude to improve the code. It will propose edits - some good, some over-engineered. Your job is to critically evaluate each one.

**Prompt to use:**
```
Review utils.py and suggest improvements one at a time.
I'll accept or reject each suggestion.
```

### Edits to ACCEPT ✅

These represent genuinely valuable improvements:

| Edit | Why Accept |
|------|------------|
| Type consistency (`return 0.0` vs `return 0`) | Fixes subtle type bugs |
| Edge case handling (negative numbers, division by zero) | Real bug prevention |
| Simple, focused utility functions (`clamp`, `percentage`) | Genuinely useful, no overhead |
| Actual bug fixes | Always accept real fixes |

**Pattern:** Accept edits that fix real problems or add clear value without complexity.

### Edits to REJECT ❌

These represent over-engineering or unnecessary changes:

| Edit | Why Reject |
|------|------------|
| Complex regex replacing simple validation | Over-engineering |
| Adding type hints to simple internal functions | Unnecessary ceremony |
| Wrapping functions in classes | Premature abstraction |
| Adding logging to pure functions | Infrastructure coupling |
| Extensive docstrings on obvious functions | Documentation bloat |
| Adding dependencies for simple operations | Dependency creep |

**Pattern:** Reject edits that add complexity without proportional value.

### Expected Metrics

After the test, you should see:

| Metric | Healthy Range | What It Means |
|--------|---------------|---------------|
| Accept Rate | 60-80% | You're thinking critically |
| Commits | 1-3 | Changes were committed |
| Session tokens | <100k | Efficient session |

Check with:
```bash
# Accept rate
curl -s 'http://localhost:9090/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total)%20by%20(decision)' | jq '.data.result'

# Commit count
curl -s 'http://localhost:9090/api/v1/query?query=sum(claude_code_commit_count_total)' | jq '.data.result[0].value[1]'
```

## Red Flags in Your Metrics

### Accept Rate > 95%
**Problem:** Rubber-stamping without reading.

**Test:** Ask Claude to introduce a subtle bug. If you accept it, your review process needs work.

```
# Ask Claude to "optimize" something and watch for:
# - Removing "unnecessary" error handling
# - Changing logic subtly
# - Adding complexity disguised as improvement
```

### Accept Rate < 50%
**Problem:** Claude doesn't understand your context, or you're being overly critical.

**Test:** Check if rejections are for good reasons:
- If Claude keeps missing your patterns → improve your CLAUDE.md
- If you're rejecting style-only issues → configure Claude's style preferences

### Cache Ratio < 10:1
**Problem:** Context isn't being reused efficiently.

**Test:** Start a session, make a change, then ask a follow-up question. If Claude seems to have forgotten context, your CLAUDE.md may need work.

### Tokens/Session > 300k
**Problem:** Sessions running too long, context being compacted.

**Test:** Break work into smaller tasks. Use `/compact` proactively.

## Automated Health Check Script

Save this as `scripts/health-check.sh`:

```bash
#!/bin/bash
# Quick health check for Claude Code metrics

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

echo "=== Claude Code Metrics Health Check ==="
echo ""

# Check if Prometheus is up
if ! curl -s "$PROMETHEUS_URL/-/healthy" > /dev/null; then
    echo "❌ Prometheus is not reachable at $PROMETHEUS_URL"
    exit 1
fi
echo "✅ Prometheus is healthy"

# Check for any Claude metrics
METRICS=$(curl -s "$PROMETHEUS_URL/api/v1/label/__name__/values" | jq -r '.data[]' | grep -c claude)
if [ "$METRICS" -eq 0 ]; then
    echo "⚠️  No Claude Code metrics found. Have you run a session with telemetry enabled?"
else
    echo "✅ Found $METRICS Claude Code metric types"
fi

# Get accept rate
ACCEPTS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total{decision=\"accept\"})" | jq -r '.data.result[0].value[1] // "0"')
REJECTS=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total{decision=\"reject\"})" | jq -r '.data.result[0].value[1] // "0"')
TOTAL=$((ACCEPTS + REJECTS))

if [ "$TOTAL" -gt 0 ]; then
    RATE=$((ACCEPTS * 100 / TOTAL))
    echo ""
    echo "Edit Decisions: $ACCEPTS accepts, $REJECTS rejects"
    if [ "$RATE" -gt 95 ]; then
        echo "⚠️  Accept Rate: ${RATE}% (possible rubber-stamping)"
    elif [ "$RATE" -lt 50 ]; then
        echo "⚠️  Accept Rate: ${RATE}% (very low - check CLAUDE.md)"
    else
        echo "✅ Accept Rate: ${RATE}% (healthy range)"
    fi
fi

# Get cost
COST=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=sum(claude_code_cost_usage_USD_total)" | jq -r '.data.result[0].value[1] // "0"')
echo ""
echo "Total Cost: \$$COST"

echo ""
echo "=== Health Check Complete ==="
```

## Cleanup

After testing:

```bash
# Remove test project
rm -rf /tmp/claude-test-project

# Optionally reset metrics (loses all data)
podman compose down
rm -rf data/prometheus/* data/loki/*
podman compose up -d
```

## What Good Looks Like

After a week of normal usage, a healthy developer profile shows:

```
Accept Rate:     75-85%     # Critical but trusting
Cache Ratio:     >20:1      # Good context reuse
Tokens/Session:  <100k      # Efficient sessions
Cost/PR:         <$5        # Good ROI
Commits:         Growing    # Productive output
```

This indicates:
- **Engaged review** - not rubber-stamping
- **Clear communication** - Claude understands context
- **Efficient sessions** - not going in circles
- **Value delivery** - producing meaningful output

---

*The goal isn't perfect metrics - it's awareness. Use the data to improve your collaboration with AI, not to optimize for numbers.*

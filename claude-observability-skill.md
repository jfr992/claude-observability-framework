---
name: claude-observability
description: |
  Team/org productivity framework for Claude Code observability. Use when:
  (1) Setting up metrics collection for Claude Code usage
  (2) Analyzing accept rate, cache hit rate, session efficiency
  (3) Interpreting AI collaboration metrics (growth mindset)
  (4) Troubleshooting OTEL/Prometheus/Grafana/Loki setup
  (5) Generating ROI reports for AI tool usage
  (6) Optimizing CLAUDE.md based on metrics feedback
  (7) Understanding healthy vs unhealthy usage patterns
---

# Claude Observability Framework

Team/org productivity framework for tracking Claude Code usage, cost, and ROI.

**Full docs:** See GUIDE.md for philosophy, CLAUDE.md for technical reference.

## Philosophy

**Metrics are mirrors, not judges.** This framework measures growth, not compliance.

| Metric | What It Reveals |
|--------|-----------------|
| Accept Rate | Critical engagement with AI suggestions |
| Cache Hit Rate | How well documentation communicates context |
| Session Size | Working efficiently vs going in circles |
| Cost/PR | Value delivered per dollar spent |

## Key Benchmarks

| Metric | Optimal | Warning | Concern |
|--------|---------|---------|---------|
| Accept Rate | 75-85% | 60-75% or 85-95% | <60% or >95% |
| Cache Hit Rate | >90% | 70-90% | <70% |
| Session Size | <100k tokens | 100-300k | >300k |
| Cost/PR | <$5 | $5-10 | >$10 |

## Setup

### Required Environment Variables

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

### Start Stack

```bash
cd ~/Repos/claude-metrics  # or your installation path
podman compose up -d
```

### Access

- Grafana: http://localhost:3000 (admin / claudecode)
- Prometheus: http://localhost:9090

## Interpreting Metrics

### Accept Rate

| Rate | Meaning | Action |
|------|---------|--------|
| <60% | Claude doesn't understand context | Improve CLAUDE.md |
| 60-75% | Healthy tension | Keep engaging critically |
| 75-85% | **Optimal** | Good prompts, active review |
| 85-95% | Getting passive | Review more critically |
| >95% | Rubber stamping | Stop and read the diffs |

### Cache Hit Rate

| Rate | Meaning | Action |
|------|---------|--------|
| <70% | Claude rebuilds context constantly | Major CLAUDE.md improvements needed |
| 70-80% | Some context reuse | Add patterns and examples |
| 80-90% | Good | Keep refining |
| >90% | **Excellent** | Documentation is working |

### Session Size

| Tokens | Meaning | Action |
|--------|---------|--------|
| <100k | Efficient | Good prompts |
| 100-200k | Getting long | Clearer initial prompts |
| 200-300k | Compaction likely | Use /compact, break up tasks |
| >300k | Inefficient | Start fresh sessions |

## Anti-Patterns

### The Rubber Stamper (>95% Accept)
Accepting without reading. Fix: Read diffs, ask "Would I have written it this way?"

### The Micromanager (<60% Accept)
Rejecting everything. Fix: Invest in CLAUDE.md, give Claude better context.

### The Context Burner (>300k tokens)
Sessions hitting limits. Fix: Fresh sessions, /compact, break tasks into phases.

## Quick Commands

```bash
# Health check
./scripts/health-check.sh

# Check storage
./scripts/check-storage.sh

# Generate report
./scripts/generate-report.sh

# Query accept rate
curl -s 'http://localhost:9090/api/v1/query?query=sum(claude_code_code_edit_tool_decision_total)%20by%20(decision)' | jq
```

## Troubleshooting

### No data in Grafana
1. Check telemetry: `echo $CLAUDE_CODE_ENABLE_TELEMETRY` (should be 1)
2. Check collector: `podman logs claude-otel-collector`
3. Check targets: http://localhost:9090/targets

### Metrics showing 0
- Prometheus marks stale after 5 min of no updates
- Check time range selector in Grafana
- Dashboard uses `max_over_time()` for infrequent metrics

### Stack won't start
```bash
podman machine start  # if using podman
podman compose down && podman compose up -d
```

## The Growth Mindset

Ask yourself:
1. **Am I learning?** Can I write the code Claude wrote?
2. **Am I curious?** Do I ask Claude to explain its reasoning?
3. **Am I improving?** Is my prompting more effective over time?
4. **Am I in control?** Do I decide architecture and constraints?

**You bring judgment. Claude brings speed. Together, unstoppable.**

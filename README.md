# Claude Observability Framework

A team/org productivity framework for tracking Claude Code usage, cost, and ROI via OpenTelemetry.

**Philosophy:** Metrics are mirrors, not judges. This framework measures growth, not compliance.

```
You + Claude = Better than either alone
```

## Quick Start

```bash
# Clone
git clone https://github.com/your-org/claude-metrics.git
cd claude-metrics

# Start stack
podman compose up -d  # or docker compose

# Configure Claude Code
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# Access dashboards
open http://localhost:3000  # Grafana (admin / claudecode)
```

Or use the interactive setup: `./scripts/setup-mac.sh`

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐     ┌─────────────┐
│   Claude Code   │────▶│  OTEL Collector  │────▶│  Prometheus │────▶│   Grafana   │
│  (your terminal)│     │   :4317/:4318    │     │    :9090    │     │    :3000    │
└─────────────────┘     └────────┬─────────┘     └─────────────┘     └─────────────┘
                                 │
                                 ▼
                          ┌─────────────┐
                          │    Loki     │  (tool usage logs)
                          │    :3100    │
                          └─────────────┘
```

## Dashboards

### Personal Dashboard
Track your individual AI collaboration patterns:
- **Cost & Usage:** Total cost, tokens, sessions, active time
- **Efficiency Gauges:** Accept Rate, Cache Ratio, Session Size
- **Breakdowns:** By model, token type, terminal
- **Tool Usage:** Which Claude Code tools you use most

### Team Dashboard
Organization-wide visibility:
- **Overview:** Total cost, active users, PRs, commits
- **ROI Metrics:** Cost/PR, Cost/Session, Cost/Commit
- **Developer Leaderboard:** Per-user metrics
- **Productivity:** Lines added/removed, active time

## Key Metrics & What They Mean

| Metric | Optimal | What It Reveals |
|--------|---------|-----------------|
| **Accept Rate** | 75-85% | Your critical engagement with AI suggestions |
| **Cache Ratio** | >20:1 | How well your CLAUDE.md communicates context |
| **Session Size** | <100k tokens | Whether you're working efficiently |
| **Cost/PR** | <$5 | Value delivered per dollar spent |

### Accept Rate Interpretation

| Rate | Meaning | Action |
|------|---------|--------|
| <60% | Claude doesn't understand your context | Improve CLAUDE.md, add examples |
| 60-75% | Healthy tension | You're engaged, suggestions need work |
| **75-85%** | **Optimal** | Good prompts, active review |
| 85-95% | Getting passive | Review more critically |
| >95% | Rubber stamping | Stop and read the diffs |

## Anti-Patterns to Avoid

### The Rubber Stamper (>95% Accept)
**Problem:** Accepting everything without reading.
**Cost:** You stop learning. Skills atrophy.
**Fix:** Read diffs. Ask "Would I have written it this way?"

### The Micromanager (<60% Accept)
**Problem:** Rejecting most suggestions.
**Cost:** Not getting the speed benefit.
**Fix:** Invest in context. Better CLAUDE.md. Give Claude a chance.

### The Context Burner (>300k tokens)
**Problem:** Sessions running until they hit limits.
**Cost:** Context compacted. Quality degrades.
**Fix:** Fresh sessions. Use `/compact`. Break tasks into phases.

## Available Scripts

```bash
./scripts/setup-mac.sh      # Interactive Mac setup
./scripts/health-check.sh   # Quick metrics health check
./scripts/check-storage.sh  # Storage usage monitor
./scripts/generate-report.sh # CLI ROI report
```

## Storage & Retention

| Component | Time Limit | Size Limit |
|-----------|------------|------------|
| Prometheus | 30 days | 1 GB |
| Loki | 30 days | Ingestion throttled |
| Grafana | Unlimited | ~5 MB (config only) |

## Documentation

| Document | Purpose |
|----------|---------|
| [CLAUDE.md](CLAUDE.md) | Technical reference for Claude Code |
| [GUIDE.md](GUIDE.md) | Co-intelligence philosophy & optimization |
| [TESTING.md](TESTING.md) | Testing framework & patterns |
| [PROPOSAL-CENTRALIZED.md](PROPOSAL-CENTRALIZED.md) | Enterprise deployment proposal |

## Claude Code Skill

A skill file is included for Claude Code users:

```bash
# Install the skill
cp claude-observability.skill ~/.claude/skills/
unzip -d ~/.claude/skills/claude-observability ~/.claude/skills/claude-observability.skill
```

This enables Claude to help with metrics interpretation and troubleshooting.

## The Philosophy

This isn't surveillance. It's not blame. It's not catching anyone doing something wrong.

**We measure to learn.**

When you track your Claude Code usage, you're developing a feedback loop for growth. Like an athlete watching game film or a musician recording practice sessions, observability gives you data to improve your craft.

The goal: **become a better engineer who happens to use AI, not an AI operator who used to be an engineer.**

### The Commitment

1. **Stay curious** - Ask why, not just whether it works
2. **Stay critical** - Read diffs, push back when needed
3. **Stay learning** - Absorb good patterns from Claude
4. **Stay in charge** - You decide architecture and direction
5. **Stay humble** - Sometimes Claude's way is better

## References

- [Claude Code Monitoring Docs](https://docs.anthropic.com/en/docs/claude-code/monitoring)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)

---

*"The best engineers don't just use AI - they collaborate with it. They bring judgment, context, and vision. AI brings speed, breadth, and tireless patience. Together, they create things neither could alone."*

# Proposal: Centralized Claude Code Monitoring

## Executive Summary

Deploy a shared observability stack that all developers point their Claude Code telemetry to. This enables:
- **Org-wide visibility** into AI tool adoption and ROI
- **Per-developer metrics** for coaching and optimization
- **Team-level aggregation** for budget allocation
- **Cost tracking** across Bedrock/API/Subscription usage

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Machines                          │
├─────────────────┬─────────────────┬─────────────────┬───────────────┤
│   Dev 1 (Mac)   │   Dev 2 (Linux) │   Dev 3 (WSL)   │    Dev N      │
│   Claude Code   │   Claude Code   │   Claude Code   │  Claude Code  │
└────────┬────────┴────────┬────────┴────────┬────────┴───────┬───────┘
         │                 │                 │                │
         │    OTLP/gRPC    │                 │                │
         └────────────────┬┴─────────────────┴────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Load Balancer       │
              │   (HTTPS + Auth)      │
              │   otel.company.com    │
              └───────────┬───────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ OTEL        │  │ OTEL        │  │ OTEL        │
│ Collector 1 │  │ Collector 2 │  │ Collector N │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       └────────────────┼────────────────┘
                        ▼
              ┌───────────────────────┐
              │     Prometheus        │
              │   (HA with Thanos     │
              │    or Cortex)         │
              └───────────┬───────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
     ┌─────────────┐         ┌─────────────┐
     │   Grafana   │         │   Alerting  │
     │ (Dashboards)│         │  (Slack/PD) │
     └─────────────┘         └─────────────┘
```

## Deployment Options

### Option A: Cloud-Hosted (Recommended for <100 devs)

| Component | Service | Est. Cost/Month |
|-----------|---------|-----------------|
| OTEL Collector | AWS ECS / GCP Cloud Run | $20-50 |
| Prometheus | Grafana Cloud / Amazon Managed Prometheus | $50-200 |
| Grafana | Grafana Cloud (free tier) | $0-50 |
| Load Balancer | AWS ALB / GCP LB | $20 |
| **Total** | | **$90-320/month** |

### Option B: Self-Hosted Kubernetes

```yaml
# helm install example
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm install otel open-telemetry/opentelemetry-collector
helm install prometheus prometheus-community/kube-prometheus-stack
helm install grafana grafana/grafana
```

### Option C: Managed Observability Platform

| Platform | Pros | Cons | Est. Cost |
|----------|------|------|-----------|
| **Datadog** | Full-featured, easy setup | Expensive at scale | $15/host + metrics |
| **Grafana Cloud** | Native Prometheus, generous free tier | Limited alerting on free | $0-500 |
| **Honeycomb** | Great for debugging | Learning curve | $100+ |
| **New Relic** | All-in-one | Complex pricing | $0-300 |

## Developer Onboarding

### One-Time Setup Script

Create `setup-claude-telemetry.sh` for developers:

```bash
#!/bin/bash
# Distributed to all developers

# Company OTEL endpoint
OTEL_ENDPOINT="https://otel.company.com:4317"
AUTH_TOKEN="${CLAUDE_METRICS_TOKEN}"  # From 1Password/Vault

# Add to shell profile
cat >> ~/.zshrc << 'EOF'
# Claude Code Telemetry
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otel.company.com:4317"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer ${CLAUDE_METRICS_TOKEN}"
EOF

echo "Done! Restart your terminal and run 'claude' to start sending metrics."
```

### MDM/Fleet Deployment

For managed devices, use the Claude Code managed settings:

```json
// /Library/Application Support/ClaudeCode/managed-settings.json (macOS)
// /etc/claude-code/managed-settings.json (Linux)
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "https://otel.company.com:4317",
    "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer ${CLAUDE_METRICS_TOKEN}"
  }
}
```

## Dashboard Design

### 1. Executive Overview

| Panel | Query | Purpose |
|-------|-------|---------|
| Total Cost (All Users) | `sum(increase(claude_code_cost_usage_USD_total[30d]))` | Budget tracking |
| Active Users | `count(count by (user_email) (claude_code_session_count_total))` | Adoption |
| Avg Cost/User | `sum(cost) / count(users)` | Per-seat cost |
| Total PRs Created | `sum(increase(claude_code_pull_request_count_total[30d]))` | Output |
| Org Accept Rate | `sum(accepts) / sum(total)` | Quality signal |

### 2. Per-Developer View

| Panel | Purpose |
|-------|---------|
| Cost Trend | Track individual spend over time |
| Session Count | Usage frequency |
| Accept Rate | Are they using suggestions well? |
| Top Models Used | Opus vs Sonnet preference |
| Active Time | Engagement depth |

### 3. Team Comparison

```promql
# Cost by team (requires team label via OTEL_RESOURCE_ATTRIBUTES)
sum by (team) (increase(claude_code_cost_usage_USD_total[30d]))

# Or by email domain pattern
sum by (team) (
  label_replace(
    claude_code_cost_usage_USD_total,
    "team", "$1", "user_email", ".*@(.+)\\.company\\.com"
  )
)
```

### 4. Leaderboard

| Developer | PRs | Commits | Cost | Cost/PR | Accept % |
|-----------|-----|---------|------|---------|----------|
| alice@... | 23 | 89 | $45 | $1.96 | 94% |
| bob@... | 18 | 52 | $78 | $4.33 | 81% |
| carol@... | 31 | 124 | $62 | $2.00 | 88% |

## Custom Labels for Team Tracking

Have developers set team/department via `OTEL_RESOURCE_ATTRIBUTES`:

```bash
export OTEL_RESOURCE_ATTRIBUTES="team=platform,department=engineering,cost_center=ENG-001"
```

Or auto-detect from email domain in OTEL collector:

```yaml
# otel-config.yaml
processors:
  attributes:
    actions:
      - key: team
        from_attribute: user_email
        pattern: ".*@(?P<team>[^.]+)\\.company\\.com"
        action: extract
```

## Security & Privacy

### Authentication

```yaml
# OTEL Collector with bearer token auth
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        auth:
          authenticator: bearertoken
extensions:
  bearertoken:
    token: ${OTEL_AUTH_TOKEN}
```

### Data Privacy

| Data Point | Collected | Sensitive? | Mitigation |
|------------|-----------|------------|------------|
| user_email | Yes | Medium | Hash if needed |
| session_id | Yes | Low | Auto-generated UUID |
| organization_id | Yes | Low | Internal ID |
| Prompt content | **No** | High | Never collected by default |
| Code content | **No** | High | Not in metrics |

### Access Control

- **Developers**: See only their own metrics
- **Team Leads**: See team aggregate + individuals
- **Eng Managers**: See department-wide
- **Finance**: See cost data only

Implement via Grafana teams + row-level security.

## Alerting

### Cost Alerts

```yaml
# Alert if daily spend exceeds threshold
- alert: HighDailyClaudeCost
  expr: sum(increase(claude_code_cost_usage_USD_total[24h])) > 500
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Claude Code daily spend exceeded $500"

# Alert if single user spends too much
- alert: HighUserClaudeCost
  expr: sum by (user_email) (increase(claude_code_cost_usage_USD_total[24h])) > 50
  for: 1h
  labels:
    severity: info
  annotations:
    summary: "User {{ $labels.user_email }} spent over $50 today"
```

### Adoption Alerts

```yaml
# Alert if usage drops significantly
- alert: LowClaudeAdoption
  expr: count(count by (user_email) (increase(claude_code_session_count_total[7d]) > 0)) < 10
  for: 1d
  labels:
    severity: info
  annotations:
    summary: "Less than 10 active Claude Code users this week"
```

## Reporting

### Weekly Automated Report

```bash
#!/bin/bash
# weekly-report.sh - Run via cron every Monday

PROMETHEUS_URL="https://prometheus.company.com"

# Fetch metrics
TOTAL_COST=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=sum(increase(claude_code_cost_usage_USD_total[7d]))" | jq -r '.data.result[0].value[1]')
ACTIVE_USERS=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=count(count by (user_email)(increase(claude_code_cost_usage_USD_total[7d]) > 0))" | jq -r '.data.result[0].value[1]')
TOTAL_PRS=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=sum(increase(claude_code_pull_request_count_total[7d]))" | jq -r '.data.result[0].value[1]')

# Generate report
cat << EOF | mail -s "Weekly Claude Code Report" engineering-leads@company.com
# Claude Code Weekly Report
Week of $(date -d 'last monday' +%Y-%m-%d)

## Summary
- Total Cost: \$${TOTAL_COST}
- Active Users: ${ACTIVE_USERS}
- PRs Created: ${TOTAL_PRS}
- Cost per PR: \$$(echo "scale=2; $TOTAL_COST / $TOTAL_PRS" | bc)
- Cost per User: \$$(echo "scale=2; $TOTAL_COST / $ACTIVE_USERS" | bc)

## Dashboard
https://grafana.company.com/d/claude-code

EOF
```

## Implementation Timeline

| Week | Milestone |
|------|-----------|
| 1 | Deploy OTEL Collector + Prometheus in staging |
| 2 | Create Grafana dashboards, test with 5 pilot devs |
| 3 | Add authentication, alerting rules |
| 4 | Roll out to all developers via setup script |
| 5 | First weekly report, iterate on dashboards |
| 6 | Add team-level views, cost allocation |

## Success Metrics

| Metric | Target | Why |
|--------|--------|-----|
| Developer adoption | >80% within 30 days | Tool is being used |
| Avg accept rate | >75% | Suggestions are useful |
| Cost per PR | <$10 | Efficient usage |
| Weekly active users | Stable or growing | Sustained value |

## Cost-Benefit Analysis

### Costs
- Infrastructure: $100-300/month
- Setup time: 2-3 days engineering
- Maintenance: 2-4 hours/month

### Benefits
- **Visibility**: Know exactly where AI spend goes
- **Optimization**: Identify training opportunities
- **Justification**: Data for budget discussions
- **Accountability**: Per-team cost allocation

### Break-even
If monitoring helps identify just one developer misusing the tool ($50/month waste) or optimizes usage patterns to save 10% on API costs, it pays for itself.

## Next Steps

1. [ ] Choose deployment option (Cloud vs K8s vs Managed)
2. [ ] Provision infrastructure
3. [ ] Create onboarding script/MDM config
4. [ ] Build dashboards
5. [ ] Pilot with one team
6. [ ] Roll out org-wide
7. [ ] Set up weekly reporting

---

**Questions?** Contact: platform-team@company.com

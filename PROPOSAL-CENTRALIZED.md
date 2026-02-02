# Centralized Claude Code Monitoring

Deploy a shared observability stack for org-wide Claude Code telemetry. The idea would be to track growth and adoption, not surveillance.

**Philosophy:** See [GUIDE.md](GUIDE.md) for why we measure communication quality, not productivity.

---

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

---

## Deployment Options

### Option A: Self-Hosted K8s - this stack toolset
The following instructions are just reference.
```bash
# Add repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

# Install stack
helm install otel open-telemetry/opentelemetry-collector \
  --set mode=deployment \
  --set config.receivers.otlp.protocols.grpc.endpoint="0.0.0.0:4317"

helm install prometheus prometheus-community/kube-prometheus-stack

helm install loki grafana/loki-stack
```

### Option B: Self-Hosted K8s - ClickStack / ClickHouse in k8s

For high-volume deployments:

```yaml
# clickhouse-otel-config.yaml
exporters:
  clickhouse:
    endpoint: tcp://clickhouse:9000
    database: otel
    logs_table_name: claude_logs
    metrics_table_name: claude_metrics
    ttl_days: 30
```

---

## Developer Onboarding

### Environment Variables

```bash
# Required for all developers
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otel.company.com:4317"

# CRITICAL: Identity tracking
export OTEL_RESOURCE_ATTRIBUTES="user_email=$(git config user.email),team=YOUR_TEAM"
```

### MDM Deployment (Managed Devices)

```json
// macOS: /Library/Application Support/ClaudeCode/managed-settings.json
// Linux: /etc/claude-code/managed-settings.json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "https://otel.company.com:4317",
    "OTEL_RESOURCE_ATTRIBUTES": "user_email=${USER_EMAIL},team=${TEAM}"
  }
}
```

---

## OTEL Collector Config

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  loki:
    endpoint: "http://loki:3100/loki/api/v1/push"

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [loki]
```

---

## Security

### Authentication

```yaml
# OTEL Collector with bearer token
receivers:
  otlp:
    protocols:
      grpc:
        auth:
          authenticator: bearertoken
extensions:
  bearertoken:
    token: ${OTEL_AUTH_TOKEN}
```

### Ingress (K8s)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: otel-collector
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts: [otel.company.com]
      secretName: otel-tls
  rules:
    - host: otel.company.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: otel-collector
                port:
                  number: 4317
```

### Data Privacy

| Data | Collected | Sensitive |
|------|-----------|-----------|
| user_email | Yes | Medium (hash if needed) |
| session_id | Yes | Low (auto-generated UUID) |
| Prompt content | **No** | N/A |
| Code content | **No** | N/A |

---

## Alerting

```yaml
# prometheus-alerts.yaml
groups:
  - name: claude-code
    rules:
      - alert: HighDailySpend
        expr: sum(increase(claude_code_cost_usage_USD_total[24h])) > 500
        for: 1h
        annotations:
          summary: "Claude Code daily spend exceeded $500"

      - alert: LowAdoption
        expr: count(count by (user_email) (increase(claude_code_session_count_total[7d]) > 0)) < 10
        for: 1d
        annotations:
          summary: "Less than 10 active users this week"
```

---

## Dashboards

Import the included Grafana dashboards:
- `grafana/dashboards/claude-code.json` - Personal view
- `grafana/dashboards/team-overview.json` - Team view with developer filter

---
---

## References

- [Claude Code Monitoring Docs](https://docs.anthropic.com/en/docs/claude-code/monitoring)
- [Anthropic ROI Guide](https://github.com/anthropics/claude-code-monitoring-guide)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [HyperDX](https://www.hyperdx.io/)
- [SigNoz](https://signoz.io/)

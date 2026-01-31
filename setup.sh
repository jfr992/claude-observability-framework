#!/bin/bash
set -e

echo "=== Claude Code Metrics Stack Setup ==="
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Start the stack
echo "Starting Docker containers..."
docker compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 5

# Check health
echo ""
echo "Service Status:"
docker compose ps

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Access Points:"
echo "  Grafana:    http://localhost:3000  (admin / claudecode)"
echo "  Prometheus: http://localhost:9090"
echo "  OTEL gRPC:  localhost:4317"
echo "  OTEL HTTP:  localhost:4318"
echo ""
echo "Add this to your shell profile (~/.zshrc or ~/.bashrc):"
echo ""
echo '  # Claude Code Telemetry'
echo '  export CLAUDE_CODE_ENABLE_TELEMETRY=1'
echo '  export OTEL_METRICS_EXPORTER=otlp'
echo '  export OTEL_EXPORTER_OTLP_PROTOCOL=grpc'
echo '  export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317'
echo ""
echo "Then run: source ~/.zshrc"
echo ""

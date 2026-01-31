#!/bin/bash
#
# Claude Code Metrics - Mac Onboarding Script
# Sets up telemetry, monitoring stack, and identity tracking
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/your-org/claude-metrics/main/scripts/setup-mac.sh | bash
#   or
#   ./scripts/setup-mac.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Claude Code Metrics - Mac Setup                        ║"
echo "║       Track usage, cost, and ROI for AI-assisted coding      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

echo -e "${YELLOW}Detected shell: $SHELL_NAME (config: $SHELL_RC)${NC}"
echo ""

# Step 1: Get user identity
echo -e "${BLUE}Step 1: Setting up your identity${NC}"
echo "─────────────────────────────────"

# Try to get email from git config
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_EMAIL" ]; then
    echo -e "${YELLOW}Git email not configured.${NC}"
    read -p "Enter your email address: " USER_EMAIL

    # Also set git email
    read -p "Set this as your git email? [Y/n] " SET_GIT
    if [ "$SET_GIT" != "n" ] && [ "$SET_GIT" != "N" ]; then
        git config --global user.email "$USER_EMAIL"
        echo -e "${GREEN}Git email configured.${NC}"
    fi
else
    USER_EMAIL="$GIT_EMAIL"
    echo -e "${GREEN}Found git email: $USER_EMAIL${NC}"
fi

# Get team name
echo ""
read -p "Enter your team name (e.g., platform, frontend, backend): " TEAM_NAME
TEAM_NAME=${TEAM_NAME:-unknown}

# Get provider
echo ""
echo "Which Claude provider do you use?"
echo "  1) Anthropic API / Claude Max subscription"
echo "  2) AWS Bedrock"
echo "  3) Google Vertex AI"
read -p "Enter choice [1-3]: " PROVIDER_CHOICE

case $PROVIDER_CHOICE in
    2) PROVIDER="bedrock" ;;
    3) PROVIDER="vertex" ;;
    *) PROVIDER="anthropic" ;;
esac

echo -e "${GREEN}Provider set to: $PROVIDER${NC}"
echo ""

# Step 2: Configure OTEL endpoint
echo -e "${BLUE}Step 2: Configure telemetry endpoint${NC}"
echo "─────────────────────────────────────"

echo "Where should metrics be sent?"
echo "  1) Local monitoring stack (localhost:4317)"
echo "  2) Company/centralized endpoint"
read -p "Enter choice [1-2]: " ENDPOINT_CHOICE

if [ "$ENDPOINT_CHOICE" = "2" ]; then
    read -p "Enter OTEL endpoint URL (e.g., https://otel.company.com:4317): " OTEL_ENDPOINT
else
    OTEL_ENDPOINT="http://localhost:4317"
fi

echo -e "${GREEN}Endpoint set to: $OTEL_ENDPOINT${NC}"
echo ""

# Step 3: Check for existing config
echo -e "${BLUE}Step 3: Updating shell configuration${NC}"
echo "─────────────────────────────────────"

# Check if already configured
if grep -q "CLAUDE_CODE_ENABLE_TELEMETRY" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}Existing Claude Code telemetry config found in $SHELL_RC${NC}"
    read -p "Replace existing config? [y/N] " REPLACE
    if [ "$REPLACE" != "y" ] && [ "$REPLACE" != "Y" ]; then
        echo "Skipping shell config update."
    else
        # Remove old config
        sed -i.bak '/# Claude Code Telemetry/,/^$/d' "$SHELL_RC"
        ADD_CONFIG=true
    fi
else
    ADD_CONFIG=true
fi

if [ "$ADD_CONFIG" = true ]; then
    cat >> "$SHELL_RC" << EOF

# Claude Code Telemetry - Added by setup-mac.sh on $(date +%Y-%m-%d)
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT="$OTEL_ENDPOINT"

# Identity tracking for per-developer metrics
export OTEL_RESOURCE_ATTRIBUTES="user_email=$USER_EMAIL,provider=$PROVIDER,team=$TEAM_NAME"

EOF
    echo -e "${GREEN}Shell configuration added to $SHELL_RC${NC}"
fi

echo ""

# Step 4: Optionally start local monitoring stack
echo -e "${BLUE}Step 4: Local monitoring stack${NC}"
echo "──────────────────────────────"

if [ "$OTEL_ENDPOINT" = "http://localhost:4317" ]; then
    echo "You've selected local monitoring. Would you like to start the stack?"
    echo ""

    # Check for Docker/Podman
    if command -v docker &> /dev/null; then
        CONTAINER_CMD="docker"
    elif command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        echo -e "${YELLOW}Neither Docker nor Podman found.${NC}"
        echo "Install Docker Desktop or Podman to run the local monitoring stack."
        echo "https://www.docker.com/products/docker-desktop/"
        CONTAINER_CMD=""
    fi

    if [ -n "$CONTAINER_CMD" ]; then
        read -p "Start local monitoring stack with $CONTAINER_CMD? [y/N] " START_STACK
        if [ "$START_STACK" = "y" ] || [ "$START_STACK" = "Y" ]; then
            # Check if we're in the repo directory
            if [ -f "docker-compose.yaml" ]; then
                echo "Starting monitoring stack..."
                $CONTAINER_CMD compose up -d
                echo -e "${GREEN}Stack started!${NC}"
                echo ""
                echo "Access dashboards at:"
                echo "  Grafana:    http://localhost:3000 (admin / claudecode)"
                echo "  Prometheus: http://localhost:9090"
            else
                echo -e "${YELLOW}docker-compose.yaml not found in current directory.${NC}"
                echo "To start the stack later:"
                echo "  cd /path/to/claude-metrics"
                echo "  $CONTAINER_CMD compose up -d"
            fi
        fi
    fi
else
    echo "Using centralized endpoint: $OTEL_ENDPOINT"
    echo "No local stack needed."
fi

echo ""

# Step 5: Summary
echo -e "${BLUE}Setup Complete!${NC}"
echo "═══════════════"
echo ""
echo "Configuration summary:"
echo "  Email:    $USER_EMAIL"
echo "  Team:     $TEAM_NAME"
echo "  Provider: $PROVIDER"
echo "  Endpoint: $OTEL_ENDPOINT"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart your terminal or run: source $SHELL_RC"
echo "  2. Run 'claude' to start a session"
echo "  3. View metrics at http://localhost:3000 (if using local stack)"
echo ""
echo -e "${GREEN}Your Claude Code usage will now be tracked!${NC}"
echo ""

# Verification helper
echo "To verify your setup, run:"
echo "  echo \$OTEL_RESOURCE_ATTRIBUTES"
echo ""
echo "Should show: user_email=$USER_EMAIL,provider=$PROVIDER,team=$TEAM_NAME"

#!/bin/bash

# MCP Servers Setup Script
# This script configures recommended MCP servers for the Adyela project

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Adyela MCP Servers Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect OS and set config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_DIR="$HOME/.config/claude"
else
    echo -e "${RED}Unsupported operating system${NC}"
    exit 1
fi

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

echo -e "${YELLOW}Config directory: $CONFIG_DIR${NC}"
echo -e "${YELLOW}Config file: $CONFIG_FILE${NC}"
echo ""

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Backing up existing config to: $BACKUP_FILE${NC}"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create MCP configuration
cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp-server"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$PROJECT_ROOT"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "\${GITHUB_TOKEN}"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "taskmaster": {
      "command": "npx",
      "args": ["-y", "@taskmaster/mcp-server"],
      "env": {
        "TASKMASTER_DATA_DIR": "$PROJECT_ROOT/.taskmaster"
      }
    }
  },
  "globalShortcut": "CommandOrControl+Shift+Space"
}
EOF

echo -e "${GREEN}✓ MCP configuration created${NC}"
echo ""

# Install recommended global tools
echo -e "${BLUE}Installing recommended testing tools...${NC}"

# Lighthouse
if ! command -v lighthouse &> /dev/null; then
    echo -e "${YELLOW}Installing Lighthouse...${NC}"
    npm install -g lighthouse
    echo -e "${GREEN}✓ Lighthouse installed${NC}"
else
    echo -e "${GREEN}✓ Lighthouse already installed${NC}"
fi

# Playwright
if ! command -v playwright &> /dev/null; then
    echo -e "${YELLOW}Installing Playwright...${NC}"
    pnpm add -D @playwright/test playwright
    echo -e "${GREEN}✓ Playwright installed${NC}"
else
    echo -e "${GREEN}✓ Playwright already installed${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  MCP Servers Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Configured MCP Servers:${NC}"
echo "  • Playwright - Browser automation and E2E testing"
echo "  • Filesystem - Advanced file operations"
echo "  • GitHub - Repository operations and PR management"
echo "  • Sequential Thinking - Complex problem solving"
echo "  • Taskmaster AI - Project and task management"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Restart Claude Desktop/Code to load the new configuration"
echo "  2. Run 'pnpm playwright install' to install browser drivers"
echo "  3. Check available MCP servers in Claude"
echo ""
echo -e "${YELLOW}Optional Integrations:${NC}"
echo "  • Set GITHUB_TOKEN for GitHub MCP"
echo "  • Configure Sentry DSN for error monitoring"
echo "  • Set up Google Cloud credentials for GCP MCP"
echo ""
echo -e "${GREEN}Configuration saved to: $CONFIG_FILE${NC}"
echo ""

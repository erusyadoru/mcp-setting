#!/bin/bash
# MCP Servers Setup Script
# This script configures all MCP servers for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MCP Servers Setup ===${NC}"

# Configuration
PIO_MCP_DIR="${PIO_MCP_DIR:-$HOME/pio-mcp-server}"
ROS_MCP_DIR="${ROS_MCP_DIR:-$HOME/ros-mcp-server}"
CLAUDE_SETTINGS_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_SETTINGS_DIR/settings.json"

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"

    if ! command -v uv &> /dev/null; then
        echo -e "${RED}Error: uv is not installed. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
        exit 1
    fi

    if ! command -v uvx &> /dev/null; then
        echo -e "${RED}Error: uvx is not installed (part of uv)${NC}"
        exit 1
    fi

    echo -e "${GREEN}Dependencies OK${NC}"
}

# Setup pio-mcp-server
setup_pio_mcp() {
    echo -e "${YELLOW}Setting up pio-mcp-server...${NC}"

    if [ ! -d "$PIO_MCP_DIR" ]; then
        echo -e "${YELLOW}Cloning pio-mcp-server...${NC}"
        git clone https://github.com/pcdshub/pio-mcp-server.git "$PIO_MCP_DIR" 2>/dev/null || {
            echo -e "${RED}Warning: Could not clone pio-mcp-server. Please clone it manually to $PIO_MCP_DIR${NC}"
            return 1
        }
    fi

    if [ ! -d "$PIO_MCP_DIR/venv" ]; then
        echo -e "${YELLOW}Creating virtual environment for pio-mcp...${NC}"
        python3 -m venv "$PIO_MCP_DIR/venv"
        "$PIO_MCP_DIR/venv/bin/pip" install -r "$PIO_MCP_DIR/requirements.txt" 2>/dev/null || {
            "$PIO_MCP_DIR/venv/bin/pip" install platformio mcp
        }
    fi

    echo -e "${GREEN}pio-mcp-server setup complete${NC}"
}

# Setup ros-mcp-server
setup_ros_mcp() {
    echo -e "${YELLOW}Setting up ros-mcp-server...${NC}"

    if [ ! -d "$ROS_MCP_DIR" ]; then
        echo -e "${YELLOW}Cloning ros-mcp-server...${NC}"
        git clone https://github.com/robotmcp/ros-mcp-server.git "$ROS_MCP_DIR"
    fi

    cd "$ROS_MCP_DIR"
    uv sync

    echo -e "${GREEN}ros-mcp-server setup complete${NC}"
}

# Generate Claude Code global settings
generate_claude_settings() {
    echo -e "${YELLOW}Generating Claude Code settings...${NC}"

    mkdir -p "$CLAUDE_SETTINGS_DIR"

    cat > "$CLAUDE_SETTINGS_FILE" << EOF
{
  "mcpServers": {
    "pio-mcp": {
      "type": "stdio",
      "command": "$PIO_MCP_DIR/venv/bin/python",
      "args": ["$PIO_MCP_DIR/server.py"],
      "env": {}
    },
    "ros-mcp": {
      "type": "stdio",
      "command": "uv",
      "args": ["--directory", "$ROS_MCP_DIR", "run", "python", "server.py", "--transport=stdio"],
      "env": {}
    }
  }
}
EOF

    echo -e "${GREEN}Claude settings written to $CLAUDE_SETTINGS_FILE${NC}"
}

# Generate project-local .mcp.json with Serena
generate_project_mcp_json() {
    local project_dir="${1:-$(pwd)}"

    echo -e "${YELLOW}Generating .mcp.json for $project_dir...${NC}"

    cat > "$project_dir/.mcp.json" << EOF
{
  "mcpServers": {
    "serena": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/oraios/serena",
        "serena", "start-mcp-server",
        "--context", "claude-code",
        "--project", "$project_dir"
      ]
    },
    "ros-mcp": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "--directory", "$ROS_MCP_DIR",
        "run", "python", "server.py", "--transport=stdio"
      ]
    }
  }
}
EOF

    echo -e "${GREEN}.mcp.json created in $project_dir${NC}"
}

# Install serena-init helper script
install_serena_init() {
    echo -e "${YELLOW}Installing serena-init helper...${NC}"

    mkdir -p "$HOME/.local/bin"

    cat > "$HOME/.local/bin/serena-init" << 'EOF'
#!/bin/bash
# Create .mcp.json with Serena for current directory

PROJECT_DIR="$(pwd)"
ROS_MCP_DIR="${ROS_MCP_DIR:-$HOME/ros-mcp-server}"

cat > .mcp.json << EOFJ
{
  "mcpServers": {
    "serena": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/oraios/serena",
        "serena", "start-mcp-server",
        "--context", "claude-code",
        "--project", "$PROJECT_DIR"
      ]
    },
    "ros-mcp": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "--directory", "$ROS_MCP_DIR",
        "run", "python", "server.py", "--transport=stdio"
      ]
    }
  }
}
EOFJ

echo "Created .mcp.json for Serena + ROS-MCP in $PROJECT_DIR"
EOF

    chmod +x "$HOME/.local/bin/serena-init"
    echo -e "${GREEN}serena-init installed to ~/.local/bin/${NC}"
}

# Main
main() {
    check_dependencies

    case "${1:-all}" in
        all)
            setup_pio_mcp
            setup_ros_mcp
            generate_claude_settings
            install_serena_init
            echo ""
            echo -e "${GREEN}=== Setup Complete ===${NC}"
            echo "Global MCP servers (pio-mcp, ros-mcp) configured in ~/.claude/settings.json"
            echo "Run 'serena-init' in any project directory to add Serena support"
            ;;
        pio)
            setup_pio_mcp
            ;;
        ros)
            setup_ros_mcp
            ;;
        settings)
            generate_claude_settings
            ;;
        project)
            generate_project_mcp_json "${2:-$(pwd)}"
            ;;
        serena-init)
            install_serena_init
            ;;
        *)
            echo "Usage: $0 [all|pio|ros|settings|project [dir]|serena-init]"
            exit 1
            ;;
    esac
}

main "$@"

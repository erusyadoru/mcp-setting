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

    if ! command -v npx &> /dev/null; then
        echo -e "${YELLOW}Warning: npx not found. Some MCP servers (filesystem, git) require Node.js${NC}"
    fi

    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Warning: docker not found. Docker MCP server requires Docker${NC}"
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

# Setup official MCP servers (filesystem, git, github, docker)
setup_official_mcp_servers() {
    echo -e "${YELLOW}Setting up official MCP servers...${NC}"

    # Check for npx (Node.js)
    if command -v npx &> /dev/null; then
        echo -e "${GREEN}Node.js found - filesystem and git MCP servers available${NC}"
    else
        echo -e "${YELLOW}Installing Node.js for filesystem/git MCP servers...${NC}"
        # Try to install via package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y nodejs npm
        elif command -v brew &> /dev/null; then
            brew install node
        else
            echo -e "${RED}Please install Node.js manually${NC}"
        fi
    fi

    # Check for GitHub CLI (for GitHub MCP)
    if command -v gh &> /dev/null; then
        echo -e "${GREEN}GitHub CLI found - github MCP server available${NC}"
    else
        echo -e "${YELLOW}Installing GitHub CLI...${NC}"
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update && sudo apt-get install -y gh
        elif command -v brew &> /dev/null; then
            brew install gh
        else
            echo -e "${YELLOW}Please install GitHub CLI manually: https://cli.github.com/${NC}"
        fi
    fi

    echo -e "${GREEN}Official MCP servers setup complete${NC}"
}

# Generate Claude Code global settings
generate_claude_settings() {
    echo -e "${YELLOW}Generating Claude Code settings...${NC}"

    mkdir -p "$CLAUDE_SETTINGS_DIR"

    # Get GitHub token if available
    local github_token=""
    if command -v gh &> /dev/null; then
        github_token=$(gh auth token 2>/dev/null || echo "")
    fi

    cat > "$CLAUDE_SETTINGS_FILE" << EOF
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$HOME"],
      "env": {}
    },
    "git": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "env": {}
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${github_token:-YOUR_GITHUB_TOKEN}"
      }
    },
    "docker": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--from", "git+https://github.com/QuantGeekDev/docker-mcp", "docker-mcp"],
      "env": {}
    },
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

    if [ -z "$github_token" ] || [ "$github_token" = "YOUR_GITHUB_TOKEN" ]; then
        echo -e "${YELLOW}Note: GitHub MCP requires authentication. Run 'gh auth login' then re-run this script.${NC}"
    fi
}

# Generate project-local .mcp.json with Serena
generate_project_mcp_json() {
    local project_dir="${1:-$(pwd)}"

    echo -e "${YELLOW}Generating .mcp.json for $project_dir...${NC}"

    # Get GitHub token if available
    local github_token=""
    if command -v gh &> /dev/null; then
        github_token=$(gh auth token 2>/dev/null || echo "")
    fi

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
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$project_dir"]
    },
    "git": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${github_token:-YOUR_GITHUB_TOKEN}"
      }
    },
    "docker": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--from", "git+https://github.com/QuantGeekDev/docker-mcp", "docker-mcp"]
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

    cat > "$HOME/.local/bin/serena-init" << 'INITEOF'
#!/bin/bash
# Create .mcp.json with all MCP servers for current directory

PROJECT_DIR="$(pwd)"
ROS_MCP_DIR="${ROS_MCP_DIR:-$HOME/ros-mcp-server}"

# Get GitHub token if available
GITHUB_TOKEN=""
if command -v gh &> /dev/null; then
    GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "YOUR_GITHUB_TOKEN")
fi

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
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$PROJECT_DIR"]
    },
    "git": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_TOKEN"
      }
    },
    "docker": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--from", "git+https://github.com/QuantGeekDev/docker-mcp", "docker-mcp"]
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

echo "Created .mcp.json with all MCP servers in $PROJECT_DIR"
echo "Servers: serena, filesystem, git, github, docker, ros-mcp"
INITEOF

    chmod +x "$HOME/.local/bin/serena-init"
    echo -e "${GREEN}serena-init installed to ~/.local/bin/${NC}"
}

# Main
main() {
    check_dependencies

    case "${1:-all}" in
        all)
            setup_official_mcp_servers
            setup_pio_mcp
            setup_ros_mcp
            generate_claude_settings
            install_serena_init
            echo ""
            echo -e "${GREEN}=== Setup Complete ===${NC}"
            echo "MCP servers configured in ~/.claude/settings.json:"
            echo "  - filesystem: File system operations"
            echo "  - git: Git repository operations"
            echo "  - github: GitHub API integration"
            echo "  - docker: Docker container management"
            echo "  - pio-mcp: PlatformIO for embedded development"
            echo "  - ros-mcp: ROS robot control"
            echo ""
            echo "Run 'serena-init' in any project directory to add Serena + all MCP servers"
            ;;
        pio)
            setup_pio_mcp
            ;;
        ros)
            setup_ros_mcp
            ;;
        official)
            setup_official_mcp_servers
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
            echo "Usage: $0 [all|pio|ros|official|settings|project [dir]|serena-init]"
            exit 1
            ;;
    esac
}

main "$@"

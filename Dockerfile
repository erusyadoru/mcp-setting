FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Copy setup script
WORKDIR /root
COPY setup-mcp.sh /root/mcp-setup/setup-mcp.sh
COPY README.md /root/mcp-setup/README.md
RUN chmod +x /root/mcp-setup/setup-mcp.sh

# Run setup (skip pio-mcp for simplicity, focus on ros-mcp)
RUN cd /root/mcp-setup && ./setup-mcp.sh ros && ./setup-mcp.sh settings && ./setup-mcp.sh serena-init

CMD ["/bin/bash"]

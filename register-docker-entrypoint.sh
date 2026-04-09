#!/bin/bash

# Entrypoint for running registration from host
# Usage: docker run -it --rm -v ~/.config:/root/.config phanikumarvankadaricode/vsp:latest register

if [ "$1" = "register" ]; then
    # Mount host config directories to make registration persist
    # This allows the container to auto-register with host MCP clients

    if [ -z "$VSP_MODE" ]; then
        VSP_MODE="${VSP_MODE:-hyperfocused}"
    fi

    if [ -z "$DOCKER_SETUP_METHOD" ]; then
        DOCKER_SETUP_METHOD="${DOCKER_SETUP_METHOD:-1}"  # Default: Docker Compose
    fi

    if [ -z "$MCP_CLIENT" ]; then
        # Auto-detect available clients
        echo "vsp MCP Server Registration"
        echo "============================"

        # Check for Claude
        if [ -d "/root/Library/Application Support/Claude" ] || [ -d "/root/.config/Claude" ]; then
            echo "✓ Claude Desktop detected"
        fi

        # Check for Gemini
        if [ -d "/root/.gemini" ] || [ -d "/root/.config/gemini" ]; then
            echo "✓ Google Gemini detected"
        fi

        # Check for Copilot
        if [ -d "/root/.copilot" ] || [ -d "/root/.config/copilot" ]; then
            echo "✓ GitHub Copilot detected"
        fi

        echo ""
        echo "Set MCP_CLIENT environment variable to auto-register:"
        echo "  docker run -e MCP_CLIENT=claude -e VSP_MODE=hyperfocused ... register"
        echo "  docker run -e MCP_CLIENT=gemini ... register"
        echo "  docker run -e MCP_CLIENT=copilot ... register"
        exit 1
    fi

    # Generate config based on Docker setup method
    case "$DOCKER_SETUP_METHOD" in
        1)
            # Docker Compose
            config='{
  "command": "docker",
  "args": ["exec", "-i", "vsp", "vsp"],
  "env": {
    "VSP_MODE": "'$VSP_MODE'"
  }
}'
            ;;
        2)
            # Direct Docker
            config='{
  "command": "docker",
  "args": ["run", "--rm", "-i", "--env-file", "/path/to/.env.docker", "phanikumarvankadaricode/vsp:latest"],
  "env": {
    "VSP_MODE": "'$VSP_MODE'"
  }
}'
            ;;
        3)
            # Local binary
            config='{
  "command": "/usr/local/bin/vsp",
  "env": {
    "SAP_URL": "${SAP_URL}",
    "SAP_USER": "${SAP_USER}",
    "SAP_PASSWORD": "${SAP_PASSWORD}",
    "SAP_CLIENT": "001",
    "VSP_MODE": "'$VSP_MODE'"
  }
}'
            ;;
        *)
            config='{
  "command": "docker",
  "args": ["exec", "-i", "vsp", "vsp"],
  "env": {
    "VSP_MODE": "'$VSP_MODE'"
  }
}'
            ;;
    esac

    # Register with appropriate client
    case "$MCP_CLIENT" in
        claude)
            # Claude Desktop config location varies by OS
            if [ -d "/root/Library" ]; then
                config_path="/root/Library/Application Support/Claude/claude_desktop_config.json"
            else
                config_path="/root/.config/Claude/claude_desktop_config.json"
            fi
            ;;
        gemini)
            config_path="/root/.gemini/mcp-config.json"
            [ -d "/root/.config/gemini" ] && config_path="/root/.config/gemini/mcp-config.json"
            ;;
        copilot)
            config_path="/root/.copilot/mcp-config.json"
            [ -d "/root/.config/copilot" ] && config_path="/root/.config/copilot/mcp-config.json"
            ;;
        *)
            echo "Error: Unknown client '$MCP_CLIENT'"
            echo "Supported: claude, gemini, copilot"
            exit 1
            ;;
    esac

    # Create directories
    mkdir -p "$(dirname "$config_path")"

    # Merge or create config
    if [ -f "$config_path" ]; then
        jq --argjson vsp "$config" '.mcpServers.vsp = $vsp' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
        echo "✓ Updated: $config_path"
    else
        echo "$config" | jq '{mcpServers: {vsp: .}}' > "$config_path"
        echo "✓ Created: $config_path"
    fi

    echo ""
    echo "Registration complete!"
    echo "Restart your $MCP_CLIENT client and ask: 'List the tools available from the SAP(vsp) server'"

else
    # Default: Run MCP server
    exec vsp "$@"
fi

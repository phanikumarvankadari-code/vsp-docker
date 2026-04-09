#!/bin/bash

# Auto-register vsp MCP server with Claude Desktop, Google Gemini, and GitHub Copilot
# Reads .mcp-manifest.json and updates client configs

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect platform
detect_platform() {
    case "$OSTYPE" in
        darwin*)   echo "darwin" ;;
        linux*)    echo "linux" ;;
        msys*)     echo "windows" ;;
        cygwin*)   echo "windows" ;;
        *)         echo "unknown" ;;
    esac
}

# Get config paths for all clients
get_config_paths() {
    local platform="$1"
    declare -A paths

    # Claude Desktop
    case "$platform" in
        darwin)
            paths["claude"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
            paths["gemini"]="$HOME/.gemini/mcp-config.json"
            paths["copilot"]="$HOME/.copilot/mcp-config.json"
            ;;
        linux)
            paths["claude"]="$HOME/.config/Claude/claude_desktop_config.json"
            paths["gemini"]="$HOME/.config/gemini/mcp-config.json"
            paths["copilot"]="$HOME/.config/copilot/mcp-config.json"
            ;;
        windows)
            paths["claude"]="$APPDATA/Claude/claude_desktop_config.json"
            paths["gemini"]="$APPDATA/Gemini/mcp-config.json"
            paths["copilot"]="$APPDATA/GitHub/Copilot/mcp-config.json"
            ;;
    esac

    for client in "${!paths[@]}"; do
        echo "${paths[$client]}"
    done
}

# Check if client is installed
is_client_installed() {
    local client="$1"
    local platform="$2"
    local config_path="$3"

    # Check if config directory exists
    local config_dir=$(dirname "$config_path")
    if [ -d "$config_dir" ]; then
        return 0
    fi

    # Additional checks
    case "$client" in
        claude)
            if [ "$platform" = "darwin" ] && [ -d "$HOME/Applications/Claude.app" ]; then
                return 0
            fi
            ;;
        gemini)
            # Gemini web app doesn't have local installation check
            return 0
            ;;
        copilot)
            # Check for VS Code extension
            if [ -d "$HOME/.vscode/extensions" ] && ls "$HOME/.vscode/extensions" | grep -q copilot; then
                return 0
            fi
            ;;
    esac

    return 1
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo "Install with:"
        echo "  macOS: brew install jq"
        echo "  Ubuntu: sudo apt-get install jq"
        echo "  Alpine: apk add jq"
        exit 1
    fi
}

# Read manifest
read_manifest() {
    local manifest_file=".mcp-manifest.json"
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: $manifest_file not found in current directory${NC}"
        exit 1
    fi
    cat "$manifest_file"
}

# Prompt for mode selection
select_mode() {
    echo -e "\n${YELLOW}Available vsp modes:${NC}"
    echo "1) hyperfocused (1 universal tool - recommended)"
    echo "2) focused (81 essential tools)"
    echo "3) expert (122 all tools, including experimental)"
    read -p "Select mode [1]: " mode_choice
    mode_choice=${mode_choice:-1}

    case "$mode_choice" in
        1) echo "hyperfocused" ;;
        2) echo "focused" ;;
        3) echo "expert" ;;
        *) echo "hyperfocused" ;;
    esac
}

# Prompt for setup method
select_setup_method() {
    echo -e "\n${YELLOW}How would you like to run vsp?${NC}"
    echo "1) Docker Compose (recommended - container name: vsp)"
    echo "2) Direct Docker (docker run)"
    echo "3) Local binary (CLI mode)"
    read -p "Select setup method [1]: " method_choice
    method_choice=${method_choice:-1}
    echo "$method_choice"
}

# Prompt for client selection
select_clients() {
    local platform="$1"
    echo -e "\n${YELLOW}Select clients to register with:${NC}"

    local claude_available=0
    local gemini_available=0
    local copilot_available=0

    # Check what's installed
    if [ -d "$HOME/Library/Application Support/Claude" ] || [ -d "$HOME/.config/Claude" ] || [ -d "$APPDATA/Claude" ] 2>/dev/null; then
        claude_available=1
    fi
    if command -v gemini &> /dev/null || [ -d "$HOME/.gemini" ] 2>/dev/null; then
        gemini_available=1
    fi
    if [ -d "$HOME/.vscode/extensions" ] 2>/dev/null || [ -d "$HOME/.config/copilot" ] 2>/dev/null; then
        copilot_available=1
    fi

    local idx=1
    declare -a clients

    if [ $claude_available -eq 1 ]; then
        echo "$idx) Claude Desktop ${GREEN}(detected)${NC}"
        clients[$idx]="claude"
        ((idx++))
    else
        echo "$idx) Claude Desktop"
        clients[$idx]="claude"
        ((idx++))
    fi

    if [ $gemini_available -eq 1 ]; then
        echo "$idx) Google Gemini ${GREEN}(detected)${NC}"
        clients[$idx]="gemini"
        ((idx++))
    else
        echo "$idx) Google Gemini"
        clients[$idx]="gemini"
        ((idx++))
    fi

    if [ $copilot_available -eq 1 ]; then
        echo "$idx) GitHub Copilot ${GREEN}(detected)${NC}"
        clients[$idx]="copilot"
        ((idx++))
    else
        echo "$idx) GitHub Copilot"
        clients[$idx]="copilot"
        ((idx++))
    fi

    read -p "Select clients to register (comma-separated, e.g., 1,2,3) [1]: " client_choice
    client_choice=${client_choice:-1}

    # Parse choices
    IFS=',' read -ra choices <<< "$client_choice"
    for choice in "${choices[@]}"; do
        choice=$(echo "$choice" | xargs) # trim whitespace
        if [ -n "${clients[$choice]}" ]; then
            echo "${clients[$choice]}"
        fi
    done
}

# Generate config for Docker Compose
generate_docker_compose_config() {
    local mode="$1"
    cat <<EOF
{
  "command": "docker",
  "args": ["exec", "-i", "vsp", "vsp"],
  "env": {
    "VSP_MODE": "$mode"
  }
}
EOF
}

# Generate config for direct Docker
generate_direct_docker_config() {
    local mode="$1"
    cat <<EOF
{
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "--env-file", "\${HOME}/.env.docker",
    "phanikumarvankadaricode/vsp:latest"
  ],
  "env": {
    "VSP_MODE": "$mode"
  }
}
EOF
}

# Generate config for local binary
generate_local_binary_config() {
    local mode="$1"
    local vsp_path="${VSP_BINARY_PATH:-/usr/local/bin/vsp}"
    cat <<EOF
{
  "command": "$vsp_path",
  "env": {
    "SAP_URL": "\${SAP_URL}",
    "SAP_USER": "\${SAP_USER}",
    "SAP_PASSWORD": "\${SAP_PASSWORD}",
    "SAP_CLIENT": "001",
    "VSP_MODE": "$mode"
  }
}
EOF
}

# Create or update config file
update_config() {
    local client="$1"
    local config_path="$2"
    local vsp_config="$3"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_path")"

    # If config doesn't exist, create it
    if [ ! -f "$config_path" ]; then
        echo -e "${YELLOW}Creating new $client MCP config...${NC}"
        echo "$vsp_config" | jq '{mcpServers: {vsp: .}}' > "$config_path"
    else
        # Backup original
        cp "$config_path" "${config_path}.backup.$(date +%s)"
        echo -e "${YELLOW}Backed up existing config to ${config_path}.backup.*${NC}"

        # Merge vsp config into existing config
        jq --argjson vsp_cfg "$vsp_config" '.mcpServers.vsp = $vsp_cfg' "$config_path" > "${config_path}.tmp"
        mv "${config_path}.tmp" "$config_path"
    fi

    echo -e "${GREEN}✓ $client config updated: $config_path${NC}"
}

# Get setup instructions for client
get_setup_instructions() {
    local client="$1"
    local method="$2"

    case "$client" in
        claude)
            case "$method" in
                1)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Run: docker-compose up -d"
                    ;;
                2)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Build: docker build -t vsp:latest ."
                    ;;
                3)
                    echo "1. Build vsp: go build -o vsp ./cmd/vsp"
                    echo "2. Add to PATH or specify full path in config"
                    echo "3. Set SAP environment variables"
                    ;;
            esac
            echo "4. Restart Claude Desktop completely"
            echo "5. Ask: \"List the tools available from the SAP(vsp) server\""
            ;;
        gemini)
            case "$method" in
                1)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Run: docker-compose up -d"
                    ;;
                2)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Build: docker build -t vsp:latest ."
                    ;;
                3)
                    echo "1. Build vsp: go build -o vsp ./cmd/vsp"
                    echo "2. Set SAP environment variables"
                    ;;
            esac
            echo "4. In Gemini (gemini.google.com), enable MCP in settings"
            echo "5. Add the vsp server configuration"
            echo "6. Reload the page and ask: \"List the tools available from the SAP(vsp) server\""
            ;;
        copilot)
            case "$method" in
                1)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Run: docker-compose up -d"
                    ;;
                2)
                    echo "1. Copy .env.docker.example to .env.docker"
                    echo "2. Fill in SAP credentials in .env.docker"
                    echo "3. Build: docker build -t vsp:latest ."
                    ;;
                3)
                    echo "1. Build vsp: go build -o vsp ./cmd/vsp"
                    echo "2. Set SAP environment variables"
                    ;;
            esac
            echo "4. In VS Code/JetBrains, open GitHub Copilot Chat"
            echo "5. Add vsp to Copilot's MCP server list in extension settings"
            echo "6. Reload and ask: \"List the tools available from the SAP(vsp) server\""
            ;;
    esac
}

# Main flow
main() {
    local platform=$(detect_platform)

    if [ "$platform" = "unknown" ]; then
        echo -e "${RED}Error: Unsupported platform (OS not recognized)${NC}"
        exit 1
    fi

    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${GREEN}vsp MCP Server Auto-Registration${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo "Platform: ${YELLOW}$platform${NC}"

    # Check dependencies
    check_jq

    # Read manifest
    local manifest=$(read_manifest)
    echo -e "${GREEN}✓ Manifest loaded${NC}"

    # Select mode
    local mode=$(select_mode)
    echo -e "${GREEN}✓ Selected mode: $mode${NC}"

    # Select setup method
    local method=$(select_setup_method)
    local vsp_config=""

    case "$method" in
        1)
            echo -e "${GREEN}✓ Setup method: Docker Compose${NC}"
            vsp_config=$(generate_docker_compose_config "$mode")
            ;;
        2)
            echo -e "${GREEN}✓ Setup method: Direct Docker${NC}"
            vsp_config=$(generate_direct_docker_config "$mode")
            ;;
        3)
            echo -e "${GREEN}✓ Setup method: Local Binary${NC}"
            vsp_config=$(generate_local_binary_config "$mode")
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            exit 1
            ;;
    esac

    # Select clients
    IFS=$'\n' read -r -d '' -a selected_clients < <(select_clients "$platform") || true

    if [ ${#selected_clients[@]} -eq 0 ]; then
        echo -e "${RED}No clients selected${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}Config preview:${NC}"
    echo "$vsp_config" | jq .

    # Register with each selected client
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"

    for client in "${selected_clients[@]}"; do
        client=$(echo "$client" | xargs) # trim whitespace

        case "$client" in
            claude)
                config_path="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
                if [ "$platform" = "linux" ]; then
                    config_path="$HOME/.config/Claude/claude_desktop_config.json"
                elif [ "$platform" = "windows" ]; then
                    config_path="$APPDATA/Claude/claude_desktop_config.json"
                fi
                ;;
            gemini)
                config_path="$HOME/.gemini/mcp-config.json"
                if [ "$platform" = "linux" ]; then
                    config_path="$HOME/.config/gemini/mcp-config.json"
                elif [ "$platform" = "windows" ]; then
                    config_path="$APPDATA/Gemini/mcp-config.json"
                fi
                ;;
            copilot)
                config_path="$HOME/.copilot/mcp-config.json"
                if [ "$platform" = "linux" ]; then
                    config_path="$HOME/.config/copilot/mcp-config.json"
                elif [ "$platform" = "windows" ]; then
                    config_path="$APPDATA/GitHub/Copilot/mcp-config.json"
                fi
                ;;
            *)
                continue
                ;;
        esac

        echo -e "\n${BLUE}Registering with $(echo $client | sed 's/./\U&/')...${NC}"
        echo "Config: $config_path"

        read -p "Update config? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_config "$client" "$config_path" "$vsp_config"

            echo -e "\n${YELLOW}Setup instructions for $(echo $client | sed 's/./\U&/'):${NC}"
            get_setup_instructions "$client" "$method"
        else
            echo "Skipped $client"
        fi
    done

    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Registration complete!${NC}"
    echo -e "\n${YELLOW}Documentation:${NC}"
    echo "  Quick start: https://github.com/phanikumarvankadari/vsp-docker#30-second-start"
    echo "  Full setup:  https://github.com/phanikumarvankadari/vsp-docker/blob/main/DOCKER.md"
}

main "$@"

# Auto-Discovery & Multi-Client Registration

vsp MCP server supports automatic discovery and registration with multiple AI clients. No manual config editing needed.

## Overview

When you pull the vsp Docker image, it includes:
1. **`.mcp-manifest.json`** — Self-describing server metadata
2. **`register-mcp.sh`** — Interactive registration script (runs on host)
3. **Registry entrypoint** — Enables container-based registration for remote systems

---

## Registration Approaches

### Approach 1: Host-Based (Interactive, Recommended)

**Use when:** Setting up locally on your machine

**Process:**
```bash
# 1. Start container
docker-compose up -d

# 2. Run interactive registration
bash register-mcp.sh
```

**What it does:**
- Detects installed AI clients (Claude, Gemini, Copilot)
- Lets you choose which to register
- Automatically updates their config files
- No container network access needed

**Advantages:**
- Interactive — user controls which clients to register
- Runs on host with direct file access
- Works offline
- Fast feedback

**Disadvantages:**
- Requires manual script execution
- Must be run on each machine separately

---

### Approach 2: Container-Based (Non-Interactive)

**Use when:** Registering on remote systems or in CI/CD

**Process:**
```bash
# 1. Mount your config directories
docker run -it --rm \
  -v ~/.config:/root/.config \
  -v ~/"Library/Application Support":/root/"Library/Application Support" \
  -e MCP_CLIENT=claude \
  -e VSP_MODE=hyperfocused \
  phanikumarvankadaricode/vsp:latest register
```

**What it does:**
- Container reads host config directories (via volume mounts)
- Automatically detects or uses specified client
- Updates config files via mounted volumes
- Returns immediately after registration

**Advantages:**
- Non-interactive — suitable for automation
- Works with remote Docker (via Docker API)
- No host dependencies (script runs in container)
- Repeatable/idempotent

**Disadvantages:**
- Requires volume mount setup
- Requires setting environment variables
- Less user feedback

---

### Approach 3: Manual Config

**Use when:** You prefer full control or have custom setup

**Process:**
1. Read `.mcp-manifest.json` from the container or GitHub
2. Manually edit your client config file
3. Restart your client

```bash
# Extract manifest
docker run --rm --entrypoint cat phanikumarvankadaricode/vsp:latest /mcp-manifest.json
```

**Advantages:**
- Maximum control
- Works with any client
- No script execution

**Disadvantages:**
- Manual, error-prone
- Repetitive across systems

---

## Usage Examples

### Example 1: Claude Desktop (Local Machine)

**Interactive approach (recommended):**
```bash
docker-compose up -d
bash register-mcp.sh
# Select: 1 (hyperfocused), 1 (Docker Compose), 1 (Claude)
# Restart Claude Desktop
```

### Example 2: Gemini (Local Machine)

```bash
bash register-mcp.sh
# Select: 1 (hyperfocused), 1 (Docker Compose), 2 (Gemini)
# Go to gemini.google.com → Settings → enable MCP
```

### Example 3: Copilot in VS Code (Remote Docker)

```bash
# On remote machine with Docker
docker run -it --rm \
  -v ~/.config:/root/.config \
  -e MCP_CLIENT=copilot \
  phanikumarvankadaricode/vsp:latest register

# Or with environment file
docker run -it --rm \
  -v ~/.config:/root/.config \
  --env-file .env.docker \
  -e MCP_CLIENT=copilot \
  -e VSP_MODE=hyperfocused \
  phanikumarvankadaricode/vsp:latest register
```

### Example 4: All Clients (Local Machine, One Command)

```bash
# Register with all three clients
docker run -it --rm \
  -v ~/.config:/root/.config \
  -v ~/"Library/Application Support":/root/"Library/Application Support" \
  phanikumarvankadaricode/vsp:latest register

# Then for each client, select during interactive prompts
```

---

## Manifest Format

The `.mcp-manifest.json` is embedded in the Docker image and can be read by clients:

```json
{
  "name": "vsp",
  "description": "Go-native MCP server for SAP ABAP Development Tools",
  "version": "1.0.0",
  "clients": [
    {
      "name": "Claude Desktop",
      "supported": true,
      "configFile": "claude_desktop_config.json",
      "platforms": {
        "darwin": "$HOME/Library/Application Support/Claude/claude_desktop_config.json",
        "linux": "$HOME/.config/Claude/claude_desktop_config.json",
        "windows": "$APPDATA/Claude/claude_desktop_config.json"
      }
    },
    ...
  ],
  "mcpServer": {
    "type": "docker",
    "container": "phanikumarvankadaricode/vsp:latest",
    "modes": [
      {
        "name": "hyperfocused",
        "description": "1 universal tool (recommended)",
        "command": "docker",
        "args": ["exec", "-i", "vsp", "vsp"],
        "env": { "VSP_MODE": "hyperfocused" }
      },
      ...
    ]
  }
}
```

Clients can:
1. Parse this manifest to auto-discover vsp
2. Extract config templates and platform-specific paths
3. Auto-populate their MCP server registry

---

## Environment Variables

### For Host-Based Registration

**`register-mcp.sh`** respects these env vars (optional):

```bash
VSP_MODE=hyperfocused      # focused, expert, or hyperfocused
VSP_BINARY_PATH=/path/to/vsp  # For local binary mode
```

### For Container-Based Registration

**`docker run ... register`** requires:

```bash
MCP_CLIENT=claude          # Required: claude, gemini, or copilot
VSP_MODE=hyperfocused      # Optional: tool mode
DOCKER_SETUP_METHOD=1      # Optional: 1=Compose, 2=Direct, 3=Local
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Script not found: `bash register-mcp.sh` | Run from repo root where `register-mcp.sh` exists |
| "No such container" when running in Docker | Mount volume: `-v ~/.config:/root/.config` |
| Config file not updated | Check volume mount permissions; ensure path is correct |
| Client not detected | Check config directory path; may vary by platform |
| "jq: not found" | Install jq: `apt-get install jq` or use container-based approach |

---

## CLI Reference

### Host-Based Script

```bash
# Interactive (guided)
bash register-mcp.sh

# With pre-set mode
VSP_MODE=focused bash register-mcp.sh

# For local binary mode
VSP_BINARY_PATH=/usr/local/bin/vsp bash register-mcp.sh
```

### Container-Based

```bash
# Show available clients
docker run -it --rm \
  -v ~/.config:/root/.config \
  phanikumarvankadaricode/vsp:latest register

# Register with specific client
docker run -it --rm \
  -v ~/.config:/root/.config \
  -e MCP_CLIENT=claude \
  phanikumarvankadaricode/vsp:latest register

# With custom mode and setup method
docker run -it --rm \
  -v ~/.config:/root/.config \
  -e MCP_CLIENT=gemini \
  -e VSP_MODE=expert \
  -e DOCKER_SETUP_METHOD=2 \
  phanikumarvankadaricode/vsp:latest register
```

---

## For MCP Client Developers

If you're building an MCP client, you can:

1. **Auto-discover** vsp by checking for `.mcp-manifest.json` in standard locations
2. **Parse the manifest** to extract:
   - Supported platforms
   - Config file locations
   - Server command templates
   - Required environment variables
3. **Auto-register** by:
   - Creating config directories
   - Templating the config from manifest
   - Writing to the appropriate config file

**Manifest path in image:** `/mcp-manifest.json`

**Docker entrypoint:** Accepts `register` command with env vars for automation

---

## Future Enhancements

Potential improvements:
- [ ] Web UI for registration (scan QR code → configure)
- [ ] MCP registry integration (publish vsp to a registry)
- [ ] GitHub Actions for auto-installing via secrets
- [ ] VS Code extension for one-click setup
- [ ] Kubernetes Helm chart with built-in registration hooks

---

## Next Steps

1. **Try interactive approach:** `bash register-mcp.sh`
2. **For remote systems:** Use `docker run ... register` with volume mounts
3. **For CI/CD:** Embed registration in your deployment pipeline
4. **For custom clients:** Parse `.mcp-manifest.json` and auto-register

---

See also:
- [DOCKER.md](DOCKER.md) — Docker setup
- [CLAUDE.md](../CLAUDE.md) — Claude Desktop integration
- [GEMINI.md](GEMINI.md) — Google Gemini setup
- [COPILOT.md](COPILOT.md) — GitHub Copilot setup

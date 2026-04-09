# Docker & Claude Desktop Setup

Run vsp as a containerized MCP server that integrates with **Claude Desktop** and **mcp-toolkit**.

## Quick Start (5 minutes)

### 1. Prepare Environment

```bash
cp .env.docker.example .env.docker
# Edit .env.docker with your SAP credentials
vim .env.docker
```

Required fields:
- `SAP_URL` — SAP ADT REST API endpoint (e.g., `http://host:50000`)
- `SAP_USER` — SAP username
- `SAP_PASSWORD` — SAP password
- `SAP_CLIENT` — SAP client (defaults to 001)

### 2. Build and Start Container

```bash
docker-compose up -d
```

This:
- Builds the vsp Docker image (multi-stage, ~50MB)
- Starts a container listening on stdio
- Loads SAP credentials from `.env.docker`

### 3. Register with Claude Desktop

Edit your Claude Desktop config:

**macOS:**
```bash
# Open in your editor
$EDITOR ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Windows:**
```powershell
# Open in your editor
notepad $env:APPDATA\Claude\claude_desktop_config.json
```

**Linux:**
```bash
$EDITOR ~/.config/Claude/claude_desktop_config.json
```

Add this to the `mcpServers` section:
```json
"vsp": {
  "command": "docker",
  "args": ["exec", "-i", "vibing-steampunk-vsp-1", "vsp"],
  "env": {
    "VSP_MODE": "hyperfocused"
  }
}
```

### 4. Restart Claude Desktop

Close and reopen Claude Desktop. In a new chat, ask:

```
List the tools available from the SAP(vsp) server
```

You should see the hyperfocused universal `SAP(action, target, params)` tool with all available actions.

---

## Setup Options

### Option A: Docker Compose (Recommended)
- Best for local development
- Container starts automatically
- Easy credential management via `.env.docker`
- Resource limits built-in

```bash
docker-compose up -d
docker-compose logs -f vsp          # Watch logs
docker-compose down                 # Stop container
```

### Option B: Direct Docker (No Compose)

Build the image:
```bash
docker build -t vsp:latest .
```

Run the container:
```bash
docker run --rm -i \
  --env-file .env.docker \
  vsp:latest
```

Register with Claude Desktop:
```json
"vsp": {
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "--env-file", "/path/to/.env.docker",
    "vsp:latest"
  ]
}
```

### Option C: Local Binary (No Docker)

```bash
go build -o vsp ./cmd/vsp
export SAP_URL="http://host:50000"
export SAP_USER="DEVELOPER"
export SAP_PASSWORD="password"
export SAP_CLIENT="001"
./vsp --mode hyperfocused
```

Register with Claude Desktop:
```json
"vsp": {
  "command": "/full/path/to/vsp",
  "env": {
    "SAP_URL": "http://host:50000",
    "SAP_USER": "DEVELOPER",
    "SAP_PASSWORD": "password",
    "SAP_CLIENT": "001",
    "VSP_MODE": "hyperfocused"
  }
}
```

---

## Tool Modes

### Hyperfocused (Recommended)
**1 universal tool** — `SAP(action, target, params)`
- Tokens: ~200 (vs ~40K for all tools)
- 99.5% reduction in schema size
- Maximum capability per token

```bash
# Usage in Claude:
SAP(action="read", target="CLAS ZCL_TRAVEL")
SAP(action="edit", target="CLAS ZCL_TRAVEL", params={"source": "..."})
SAP(action="create", target="DEVC", params={"name": "$ZOZIK"})
SAP(action="analyze", params={"type": "health", "package": "$ZDEV"})
```

### Focused Mode
**81 essential tools** — named tools (GetSource, WriteSource, CreateClass, etc.)
- Better for discovery and learning
- Higher token overhead
- Set `VSP_MODE=focused` in environment or docker-compose

### Expert Mode
**122 all tools** — includes experimental and advanced features
- Full surface area
- Some tools unreliable on older SAP versions
- Set `VSP_MODE=expert` in environment or docker-compose

---

## Environment Variables

### SAP Connection
| Variable | Required | Example | Purpose |
|----------|----------|---------|---------|
| `SAP_URL` | Yes | `http://dev.example.com:50000` | ADT REST API endpoint |
| `SAP_USER` | Yes | `DEVELOPER` | SAP username |
| `SAP_PASSWORD` | Yes | (secret) | SAP password |
| `SAP_CLIENT` | No | `001` | SAP client (default: 001) |
| `SAP_LANGUAGE` | No | `EN` | SAP language (default: EN) |
| `SAP_INSECURE` | No | `true` | Skip TLS verification |

### vsp Configuration
| Variable | Default | Purpose |
|----------|---------|---------|
| `VSP_MODE` | hyperfocused | Tool mode: `focused`, `expert`, `hyperfocused` |
| `VSP_READ_ONLY` | false | Block all writes |
| `VSP_ALLOWED_PACKAGES` | (none) | Allowlist: `Z*,$TMP` |
| `VSP_DISABLED_GROUPS` | (none) | Disable groups: `5THDICGRX` |
| `VERBOSE` | false | Enable debug logging |

---

## Troubleshooting

### "Connection refused" or "No such container"
```bash
# Check if container is running
docker ps | grep vsp

# Check logs
docker-compose logs vsp

# Restart container
docker-compose restart vsp
```

### "Authentication failed"
- Verify `SAP_URL` is correct (check with `curl -I $SAP_URL`)
- Verify `SAP_USER` and `SAP_PASSWORD` are correct
- Verify `SAP_CLIENT` matches your system

### Claude Desktop doesn't see vsp
- Restart Claude Desktop completely
- Verify JSON syntax in `claude_desktop_config.json` (use jsonlint.com)
- Check container is running: `docker ps`
- For Docker Compose, ensure container name is correct: `docker-compose ps`

### Port 50000 already in use
vsp doesn't need port 50000 locally — it communicates via stdio. This error usually means your SAP system URL is wrong (check `SAP_URL` in `.env.docker`).

### Large ABAP source takes too long
Hyperfocused mode is recommended. For very large classes:
- Use `--allowed-packages` to limit scope
- Use method-level surgery: `SAP(action="read", target="CLAS ZCL_FOO", params={"method": "BAR"})`
- Enable caching (built-in SQLite via `--cache`)

---

## Multi-System Setup

If you have multiple SAP systems, use `.vsp.json` system profiles:

```json
{
  "default": "dev",
  "systems": {
    "dev": {
      "url": "http://dev.example.com:50000",
      "user": "DEVELOPER",
      "client": "001"
    },
    "prod": {
      "url": "https://prod.example.com:44300",
      "user": "READONLY",
      "client": "100",
      "read_only": true
    }
  }
}
```

Then run vsp with CLI mode:
```bash
vsp -s dev search "ZCL_*"
vsp -s prod source CLAS ZCL_REPORT
```

For MCP server mode, create separate containers via multiple docker-compose services or docker-compose profiles.

---

## Next Steps

1. **Read:** `vsp --help` for full CLI options
2. **Explore:** `SAP(action="help", target="debug")` in Claude for action reference
3. **Security:** Use `--read-only` flag for safe exploration
4. **Advanced:** See [CLAUDE.md](CLAUDE.md) for codebase context, [README.md](README.md) for feature reference

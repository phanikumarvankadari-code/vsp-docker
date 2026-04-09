# Docker Setup for Multiple AI Clients

Run vsp as a containerized MCP server integrated with **Claude Desktop**, **Google Gemini**, and **GitHub Copilot**.

**👉 NEW HERE?** Start with [QUICKSTART.md](QUICKSTART.md) (5 minutes) or [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md) (printable).

## Overview

vsp communicates with AI agents via **Model Context Protocol (MCP)** over stdio. This Docker setup containerizes vsp to work seamlessly with:
- **Claude Desktop** (macOS, Windows, Linux)
- **Google Gemini** (Web-based, gemini.google.com)
- **GitHub Copilot** (VS Code, JetBrains IDEs)
- **Docker Desktop** (local development)

---

## 30-Second Start

### Automatic Registration (Recommended)

```bash
# 1. Copy credentials template
cp .env.docker.example .env.docker

# 2. Edit with your SAP details
vim .env.docker  # Fill in SAP_URL, SAP_USER, SAP_PASSWORD, SAP_CLIENT

# 3. Start container
docker-compose up -d

# 4. Auto-register with your AI client(s)
bash register-mcp.sh
```

The script will:
- Detect installed AI clients (Claude, Gemini, Copilot)
- Let you choose which to register with
- Automatically update their configurations

Then restart your AI client and ask: **"List the tools available from the SAP(vsp) server"**

### Manual Registration (Alternative)

If you prefer manual setup, see [Claude Desktop](#claude-desktop-integration), [Gemini](GEMINI.md), or [Copilot](COPILOT.md) sections below.

---

## Multi-Client Support

vsp works with multiple AI agents. Choose your setup:

| Client | Status | Setup Time | Complexity |
|--------|--------|-----------|-----------|
| **Claude Desktop** | ✅ Recommended | 2 min | Easy |
| **Google Gemini** | ✅ Supported | 3 min | Medium |
| **GitHub Copilot** | ✅ Supported (IDE) | 5 min | Medium-Hard |

**Use `register-mcp.sh`** to auto-configure all at once, or follow client-specific guides below.

---

## Claude Desktop Integration

### Step 1: Find Your Config File

**macOS:**
```bash
open ~/Library/Application\ Support/Claude/
# File: claude_desktop_config.json
```

**Windows:**
```cmd
explorer %APPDATA%\Claude\
REM File: claude_desktop_config.json
```

**Linux:**
```bash
cat ~/.config/Claude/claude_desktop_config.json
```

### Step 2: Add vsp Server

Add this to the `"mcpServers"` section of your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "vsp": {
      "command": "docker",
      "args": ["exec", "-i", "vibing-steampunk-vsp-1", "vsp"],
      "env": {
        "VSP_MODE": "hyperfocused"
      }
    }
  }
}
```

**Full example (if you don't have other MCP servers):**

```json
{
  "mcpServers": {
    "vsp": {
      "command": "docker",
      "args": ["exec", "-i", "vibing-steampunk-vsp-1", "vsp"],
      "env": {
        "VSP_MODE": "hyperfocused"
      }
    }
  }
}
```

### Step 3: Restart Claude Desktop

Close Claude Desktop completely, then reopen it. You should now have access to the SAP tools.

---

## Google Gemini Integration

For full setup, see [GEMINI.md](GEMINI.md).

### Quick Setup

1. Start the container (see 30-second start above)
2. Run `bash register-mcp.sh` and select Gemini
3. Go to **gemini.google.com** → Settings → enable "Model Context Protocol"
4. Add vsp from `~/.gemini/mcp-config.json`

### Test

In a Gemini chat:
```
List the tools available from the SAP(vsp) server
```

---

## GitHub Copilot Integration

For full setup with VS Code and JetBrains, see [COPILOT.md](COPILOT.md).

### Quick Setup

1. Start the container (see 30-second start above)
2. Run `bash register-mcp.sh` and select Copilot
3. In VS Code/JetBrains, enable MCP in GitHub Copilot settings
4. Add vsp from `~/.copilot/mcp-config.json`

### Test

In Copilot Chat:
```
@vsp list available tools
```

---

## What You Get

### Hyperfocused Mode (Recommended)
**1 universal tool:** `SAP(action="...", target="...", params={...})`

Usage in Claude:
```
Read a class:
  SAP(action="read", target="CLAS ZCL_TRAVEL")

Edit a method:
  SAP(action="edit", target="CLAS ZCL_TRAVEL", params={
    "method": "GET_DATA",
    "source": "  METHOD get_data.\n    ...\n  ENDMETHOD."
  })

Create a package:
  SAP(action="create", target="DEVC", params={
    "name": "$ZOZIK",
    "description": "Development package"
  })

Analyze package health:
  SAP(action="analyze", params={
    "type": "health",
    "package": "$ZDEV"
  })

Get help:
  SAP(action="help", target="debug")
```

### Focused Mode (81 tools)
Named tools: GetSource, WriteSource, CreateClass, SearchObjects, etc.
- Better for discovery
- Higher token overhead
- Set `VSP_MODE=focused` in `.env.docker`

### Expert Mode (122 tools)
All tools including experimental features.
- Full surface area
- Some features unreliable on older SAP versions
- Set `VSP_MODE=expert` in `.env.docker`

---

## Environment Setup

### Prerequisites
- Docker Desktop installed and running
- SAP system with ADT REST API enabled (ECC, S/4HANA, A4H, BTP)
- SAP username/password with ADT access

### File: .env.docker

```bash
cp .env.docker.example .env.docker
vim .env.docker
```

**Required fields:**
```env
# SAP Connection
SAP_URL=http://your-sap-host:50000          # ADT REST API endpoint
SAP_USER=DEVELOPER                           # SAP username
SAP_PASSWORD=your_password                   # SAP password
SAP_CLIENT=001                               # Client number (optional, default 001)

# VSP Configuration
VSP_MODE=hyperfocused                        # focused, expert, or hyperfocused
```

**Optional fields:**
```env
SAP_LANGUAGE=EN                              # Language (default: EN)
VSP_READ_ONLY=false                          # Block all writes (default: false)
VSP_ALLOWED_PACKAGES=Z*,$TMP                 # Allowlist packages (optional)
VSP_DISABLED_GROUPS=                         # Disable tool groups: 5THDICGRX (optional)
VERBOSE=false                                # Debug logging (default: false)
```

---

## Running vsp

### Docker Compose (Recommended)

```bash
# Start
docker-compose up -d

# View logs
docker-compose logs -f vsp

# Stop
docker-compose down

# Rebuild
docker-compose build --no-cache
docker-compose up -d
```

### Direct Docker

```bash
# Build
docker build -t vsp:latest .

# Run
docker run --rm -i \
  --env-file .env.docker \
  vsp:latest
```

### Local Binary (No Docker)

```bash
go build -o vsp ./cmd/vsp
export SAP_URL="http://host:50000"
export SAP_USER="DEVELOPER"
export SAP_PASSWORD="password"
./vsp --mode hyperfocused
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Claude Desktop can't find vsp | Restart Claude Desktop completely; verify JSON syntax in config |
| "No such container" error | Run `docker-compose up -d` to start the container |
| Authentication failed | Verify `SAP_URL`, `SAP_USER`, `SAP_PASSWORD` in `.env.docker` |
| Container exits immediately | Check logs: `docker-compose logs vsp` |
| Connection refused | Verify SAP system is reachable: `curl -I $SAP_URL` |
| Very slow on large classes | Use method-level surgery or `--allowed-packages` to limit scope |

---

## Architecture

```
┌─────────────────────────┐
│   Claude Desktop        │
│   (or other AI agent)   │
└────────────┬────────────┘
             │ MCP (stdio)
             ▼
┌─────────────────────────┐
│  Docker Container       │
│  ┌─────────────────────┐│
│  │  vsp MCP Server     ││
│  │  (hyperfocused mode)││
│  └────────┬────────────┘│
│           │ ADT REST API│
└───────────┼─────────────┘
            │
            ▼
      ┌─────────────┐
      │ SAP System  │
      │   (ADT)     │
      └─────────────┘
```

---

## Features

| Feature | Support | Notes |
|---------|---------|-------|
| Read ABAP source | ✅ | Full source + context compression |
| Edit ABAP code | ✅ | Syntax check, lock/unlock, activate |
| Create objects | ✅ | Classes, packages, CDS, etc. |
| Delete objects | ✅ | Guarded with `--read-only` flag |
| Run tests | ✅ | Unit tests, ATC checks |
| Debug ABAP | ✅ | Breakpoints, step, inspect variables |
| Analyze code | ✅ | Dependencies, boundaries, co-change |
| Transport mgmt | ✅ | List, create, release, import |
| Deploy files | ✅ | Upload ABAP source files directly |

---

## Advanced: Multi-System Setup

Use `.vsp.json` for CLI mode (not MCP server):

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

Then use CLI:
```bash
vsp -s dev search "ZCL_*"
vsp -s prod source CLAS ZCL_REPORT
```

For MCP server with multiple systems, create separate docker-compose services or Docker Compose profiles.

---

## Registration & Discovery

### Two Methods Available

1. **Host-Based (Interactive)** — `bash register-mcp.sh`
   - Guided setup with client selection
   - Works locally with direct file access
   - Recommended for initial setup

2. **Container-Based (Automated)** — `docker run ... register`
   - Non-interactive, suitable for remote/CI systems
   - Uses volume mounts for config persistence
   - Repeatable and idempotent

See [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md) for details on both approaches and advanced usage.

---

## Next Steps

1. **Auto-register:** Use `bash register-mcp.sh` (local) or `docker run ... register` (remote)
2. **Choose your client:**
   - Claude Desktop: native integration, desktop app
   - Gemini: web-based, real-time collaboration
   - Copilot: IDE-native, inline code assist
3. **Explore:** Ask your client `SAP(action="help", target="debug")`
4. **Detailed setup:** 
   - Auto-discovery & registration: [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md)
   - Claude: [DOCKER.md](DOCKER.md)
   - Gemini: [GEMINI.md](GEMINI.md)
   - Copilot: [COPILOT.md](COPILOT.md)
5. **Full feature reference:** [README.md](README.md)
6. **Codebase context:** [CLAUDE.md](CLAUDE.md)

---

## FAQ

**Q: Is this safe to run on prod systems?**  
A: Yes, use `VSP_READ_ONLY=true` or `--read-only` flag to block all writes.

**Q: What versions of SAP are supported?**  
A: ECC, S/4HANA, A4H, and BTP — anywhere ADT REST API is available.

**Q: Can I use basic auth + cookies together?**  
A: No, use one or the other. If using SSO, use `--browser-auth` in CLI mode.

**Q: How are credentials stored?**  
A: In `.env.docker` (local), never committed. For production, use Docker secrets or mounted volumes.

**Q: What if my SAP password contains special characters?**  
A: Enclose it in quotes: `SAP_PASSWORD="my$ecret&pass"`

**Q: Can I connect to a local SAP instance (VM)?**  
A: Yes, use the VM's IP in `SAP_URL`. Ensure Docker Desktop can reach it.

---

## Support

- **Docker issues:** Check [DOCKER.md](DOCKER.md) troubleshooting section
- **vsp features:** See [README.md](README.md) or `SAP(action="help", target="...")`
- **Development:** See [CLAUDE.md](CLAUDE.md) for codebase structure

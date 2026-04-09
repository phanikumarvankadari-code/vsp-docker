# Google Gemini + vsp Setup

Run vsp as an MCP server integrated with **Google Gemini** (gemini.google.com).

## Quick Start (5 minutes)

### 1. Prepare Docker Container

```bash
# Copy and edit credentials
cp .env.docker.example .env.docker
vim .env.docker  # Fill in SAP_URL, SAP_USER, SAP_PASSWORD

# Start container
docker-compose up -d
```

### 2. Register vsp with Gemini

```bash
bash register-mcp.sh
```

Select:
- Mode: `1` (hyperfocused - recommended)
- Setup method: `1` (Docker Compose)
- Client: `2` (Google Gemini)

### 3. Enable MCP in Gemini

Go to **gemini.google.com**:
1. Click your profile → **Settings**
2. Look for "Model Context Protocol" or "MCP" section
3. Enable MCP servers
4. Add the vsp server configuration from `~/.gemini/mcp-config.json`

### 4. Test

In a Gemini chat, ask:
```
List the tools available from the SAP(vsp) server
```

---

## Manual Setup (If auto-registration fails)

### 1. Create Gemini MCP Config

Create `~/.gemini/mcp-config.json`:

**Option A: Docker Compose**
```json
{
  "mcpServers": {
    "vsp": {
      "command": "docker",
      "args": ["exec", "-i", "vsp", "vsp"],
      "env": {
        "VSP_MODE": "hyperfocused"
      }
    }
  }
}
```

**Option B: Direct Docker**
```json
{
  "mcpServers": {
    "vsp": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env-file", "/path/to/.env.docker",
        "phanikumarvankadaricode/vsp:latest"
      ]
    }
  }
}
```

**Option C: Local Binary**
```json
{
  "mcpServers": {
    "vsp": {
      "command": "/path/to/vsp",
      "env": {
        "SAP_URL": "http://host:50000",
        "SAP_USER": "DEVELOPER",
        "SAP_PASSWORD": "password",
        "SAP_CLIENT": "001",
        "VSP_MODE": "hyperfocused"
      }
    }
  }
}
```

### 2. Enable in Gemini Settings

- Go to gemini.google.com → Settings
- Enable "Model Context Protocol" or "External Tools"
- Point to your MCP config

### 3. Reload and Test

Refresh Gemini and ask:
```
What SAP tools are available?
```

---

## Tool Modes

### Hyperfocused (Recommended)
**1 universal tool** — `SAP(action, target, params)`

```
SAP(action="read", target="CLAS ZCL_TRAVEL")
SAP(action="edit", target="CLAS ZCL_TRAVEL", params={"source": "..."})
SAP(action="analyze", params={"type": "health", "package": "$ZDEV"})
```

### Focused Mode
**81 essential tools** — named tools (GetSource, WriteSource, etc.)

Set `VSP_MODE=focused` in `.env.docker`

### Expert Mode
**122 all tools** — includes experimental features

Set `VSP_MODE=expert` in `.env.docker`

---

## Usage Examples

### Read ABAP Source
```
SAP(action="read", target="CLAS ZCL_TRAVEL")
```

### Edit a Method
```
SAP(action="edit", target="CLAS ZCL_TRAVEL", params={
  "method": "GET_DATA",
  "source": "  METHOD get_data.\n    ...\n  ENDMETHOD."
})
```

### Run Unit Tests
```
SAP(action="test", target="CLAS ZCL_TRAVEL")
```

### Analyze Code
```
SAP(action="analyze", params={
  "type": "health",
  "package": "$ZDEV"
})
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| MCP not showing in Gemini | Reload page; check Settings → MCP enabled |
| "No such container" error | Run `docker-compose up -d` |
| Authentication failed | Verify SAP credentials in `.env.docker` |
| Connection refused | Verify SAP system is reachable: `curl -I $SAP_URL` |
| Gemini can't see vsp tools | Check Docker container is running: `docker ps` |

---

## Comparison: Gemini vs Claude vs Copilot

| Feature | Gemini | Claude | Copilot |
|---------|--------|--------|---------|
| MCP Support | ✅ Yes | ✅ Yes | ✅ Yes (IDE) |
| Web-based | ✅ Yes | ❌ Desktop app | ❌ IDE extension |
| Token efficiency | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Setup complexity | Medium | Easy | Hard (IDE-dependent) |
| Real-time collab | ✅ Yes | ❌ No | ✅ Yes (shared IDE) |

---

## Next Steps

1. **Explore:** Ask Gemini `SAP(action="help", target="debug")` to see available actions
2. **Read ABAP:** Try reading a complex class to understand dependencies
3. **Run tests:** Use `action="test"` to validate ABAP code
4. **Analyze:** Use `action="analyze"` to understand package health

---

## Support

- **Setup issues:** See [DOCKER.md](DOCKER.md) troubleshooting
- **vsp features:** See [README.md](README.md) or ask `SAP(action="help", target="...")`

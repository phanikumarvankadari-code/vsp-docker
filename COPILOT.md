# GitHub Copilot + vsp Setup

Run vsp as an MCP server integrated with **GitHub Copilot** in VS Code, JetBrains IDEs, or other supported editors.

## Prerequisites

- GitHub Copilot extension installed (or GitHub Copilot Pro subscription)
- VS Code, JetBrains IDE (IntelliJ, WebStorm, PyCharm, etc.), or other Copilot-supported editor
- Docker Desktop running with vsp container

## Quick Start (5 minutes)

### 1. Prepare Docker Container

```bash
# Copy and edit credentials
cp .env.docker.example .env.docker
vim .env.docker  # Fill in SAP_URL, SAP_USER, SAP_PASSWORD

# Start container
docker-compose up -d
```

### 2. Register vsp with Copilot

```bash
bash register-mcp.sh
```

Select:
- Mode: `1` (hyperfocused - recommended)
- Setup method: `1` (Docker Compose)
- Client: `3` (GitHub Copilot)

### 3. Configure in Your IDE

#### VS Code

1. Open **Settings** (Cmd+, or Ctrl+,)
2. Search for "copilot"
3. Find **GitHub Copilot: Model Context Protocol**
4. Enable it
5. Add the vsp server from your `~/.copilot/mcp-config.json`
6. Reload VS Code

#### JetBrains (IntelliJ, WebStorm, PyCharm, etc.)

1. Open **Settings** → **Tools** → **GitHub Copilot**
2. Enable "Model Context Protocol (MCP)"
3. Add vsp server configuration
4. Restart IDE

### 4. Test in Copilot Chat

In Copilot Chat:
```
List the tools available from the SAP(vsp) server
```

---

## Manual Setup (If auto-registration fails)

### 1. Create Copilot MCP Config

Create `~/.copilot/mcp-config.json`:

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

### 2. Configure in IDE

**VS Code:**
```json
// .vscode/settings.json
{
  "github.copilot.mcp.servers": {
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

**JetBrains:**
- Settings → Tools → GitHub Copilot → MCP Servers
- Add server with name "vsp"
- Point to `~/.copilot/mcp-config.json`

### 3. Reload IDE

- VS Code: Ctrl+Shift+P → "Developer: Reload Window"
- JetBrains: File → Invalidate Caches → Restart

### 4. Test

Open Copilot Chat and ask:
```
What SAP tools are available?
```

---

## Tool Modes

### Hyperfocused (Recommended)
**1 universal tool** — `SAP(action, target, params)`

Minimal token overhead, maximum capability.

```
SAP(action="read", target="CLAS ZCL_TRAVEL")
SAP(action="edit", target="CLAS ZCL_TRAVEL", params={"source": "..."})
SAP(action="analyze", params={"type": "health", "package": "$ZDEV"})
```

### Focused Mode
**81 essential tools** — named tools (GetSource, WriteSource, etc.)

Better for discovery, higher token cost.

Set `VSP_MODE=focused` in `.env.docker`

### Expert Mode
**122 all tools** — includes experimental features

Full surface area, some unreliability on older SAP versions.

Set `VSP_MODE=expert` in `.env.docker`

---

## IDE-Specific Setup

### VS Code

**Requirements:**
- VS Code 1.90+
- GitHub Copilot extension (Copilot Chat)
- Docker extension (optional, for container management)

**Setup:**
1. Install GitHub Copilot extension from marketplace
2. Sign in with GitHub account
3. Open Settings (Cmd+, or Ctrl+,)
4. Search "github.copilot.mcp"
5. Add vsp server JSON
6. Open Copilot Chat (Cmd+Shift+L or Ctrl+Shift+L)
7. Ask "List SAP tools"

**Tips:**
- Use `@vsp` prefix in Copilot Chat to explicitly route to vsp
- Copilot Chat window stays in-editor
- Inline suggestions work with vsp tools in comments

---

### JetBrains IDEs

**Supported IDEs:**
- IntelliJ IDEA (2024.1+)
- WebStorm (2024.1+)
- PyCharm (2024.1+)
- GoLand (2024.1+)
- DataGrip (2024.1+)
- All other JetBrains IDEs (2024.1+)

**Setup:**
1. Install GitHub Copilot plugin from JetBrains marketplace
2. Sign in with GitHub account
3. Settings → Tools → GitHub Copilot → MCP Servers
4. Click "+" to add vsp server
5. Reload IDE (File → Invalidate Caches → Restart)
6. Open Copilot Chat (Tools → GitHub Copilot → Chat)
7. Ask "List SAP tools"

**Tips:**
- Use `@vsp` prefix in Copilot Chat
- Context menu: right-click → "Ask Copilot" with vsp tools available
- Inline suggestions work in all file types

---

## Usage Examples

### In Copilot Chat

**Read ABAP Class:**
```
@vsp read class ZCL_TRAVEL
```

**Edit Method:**
```
@vsp edit ZCL_TRAVEL method GET_DATA
```

**Run Tests:**
```
@vsp test ZCL_TRAVEL
```

**Analyze Package Health:**
```
@vsp analyze health for package $ZDEV
```

### In Code Editor

Use Copilot inline suggestions:
```abap
* Read a class using vsp:
* @vsp read CLAS ZCL_TRAVEL
```

Ask Copilot to use vsp tools in comments or in Chat.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| MCP not showing in Copilot Chat | Restart IDE; check Copilot extension enabled |
| "No such container" error | Run `docker-compose up -d` |
| "docker: command not found" | Install Docker Desktop; add Docker to PATH |
| Authentication failed | Verify SAP credentials in `.env.docker` |
| Connection refused | Verify SAP system is reachable: `curl -I $SAP_URL` |
| Copilot can't call vsp tools | Check Docker container running: `docker ps` |
| "MCP not available" in IDE settings | Update IDE to 2024.1+; reinstall Copilot plugin |

---

## Performance Tips

1. **Use hyperfocused mode** — lowest token overhead
2. **Limit context** — use `--allowed-packages` to reduce scope
3. **Method-level edits** — read/edit individual methods instead of full classes
4. **Cache results** — Copilot Chat caches context within conversation
5. **Inline suggestions** — prefer Chat over inline for complex queries

---

## Comparison: Copilot vs Claude vs Gemini

| Feature | Copilot | Claude | Gemini |
|---------|---------|--------|--------|
| MCP Support | ✅ Yes | ✅ Yes | ✅ Yes |
| IDE integration | ✅ Native | ❌ Desktop app | ❌ Web-based |
| Chat interface | ✅ In IDE | ✅ Desktop | ✅ Web |
| Inline code assist | ✅ Yes | ❌ No | ❌ No |
| Copilot Pro required | ✅ Yes (Pro) | ❌ No | ⭐ Depends |
| Real-time collab | ✅ Yes (shared IDE) | ❌ No | ✅ Yes |

---

## Next Steps

1. **Explore:** In Copilot Chat, ask `@vsp help debug`
2. **Read ABAP:** Try reading a complex class
3. **Run Tests:** Use `@vsp test` to validate code
4. **Analyze:** Use `@vsp analyze` to understand dependencies
5. **Join Community:** Share feedback in GitHub Issues

---

## Support

- **IDE setup issues:** Check your IDE's extension documentation
- **Docker issues:** See [DOCKER.md](DOCKER.md) troubleshooting
- **vsp features:** See [README.md](README.md) or ask `SAP(action="help")`

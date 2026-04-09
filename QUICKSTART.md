# Quick Start: vsp MCP on Your Machine (5 minutes)

## Step 1: Pull the Image

```bash
docker pull phanikumarvankadaricode/vsp:latest
```

Or with compose (recommended):

```bash
# Clone or download the repo
git clone https://github.com/phanikumarvankadari/vsp-docker.git
cd vsp-docker/vibing-steampunk
```

---

## Step 2: Setup SAP Credentials

```bash
# Copy template
cp .env.docker.example .env.docker

# Edit with your SAP details
vim .env.docker
```

**Fill in these 4 fields:**
```env
SAP_URL=http://your-sap-host:50000
SAP_USER=DEVELOPER
SAP_PASSWORD=your_password_here
SAP_CLIENT=001
```

---

## Step 3: Start the Container

### Option A: Docker Compose (Recommended)

```bash
docker-compose up -d
```

Verify it's running:
```bash
docker-compose ps
# Should show: vsp  Running
```

### Option B: Direct Docker

```bash
docker run -d \
  --name vsp \
  --env-file .env.docker \
  phanikumarvankadaricode/vsp:latest \
  --mode hyperfocused
```

---

## Step 4: Register with Your AI Client

Run the interactive registration script:

```bash
bash register-mcp.sh
```

**Prompts you'll see:**
1. **"Select mode"** → Choose `1` (hyperfocused - recommended)
2. **"How would you like to run vsp?"** → Choose `1` (Docker Compose) or `2` (Direct Docker)
3. **"Select clients to register with"** → Choose which AI clients you have installed:
   - `1` = Claude Desktop
   - `2` = Google Gemini
   - `3` = GitHub Copilot

The script will:
- Auto-detect your installed clients
- Update their config files automatically
- Show you what's being installed

---

## Step 5: Restart Your AI Client

Close and reopen your AI client completely:

- **Claude Desktop:** Quit and reopen
- **Google Gemini:** Reload browser (gemini.google.com)
- **GitHub Copilot:** Reload VS Code or restart IDE

---

## Step 6: Test It Works

Ask your AI client:

```
List the tools available from the SAP(vsp) server
```

You should see the hyperfocused universal `SAP(action, target, params)` tool.

---

## Common Use Cases

### Read an ABAP Class
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

### Analyze Code Health
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
| **Docker not installed** | Install [Docker Desktop](https://www.docker.com/products/docker-desktop) |
| **"No such container"** | Run `docker-compose up -d` first |
| **Authentication failed** | Check SAP_URL, SAP_USER, SAP_PASSWORD in `.env.docker` |
| **Client doesn't see vsp** | Restart client completely (not just minimize) |
| **Script not found** | Make sure you're in the repo directory where `register-mcp.sh` lives |
| **jq not installed** | Install: `brew install jq` (macOS) or `apt-get install jq` (Linux) |

---

## File Structure

```
vsp-docker/vibing-steampunk/
├── .env.docker.example       ← Copy this & fill in SAP creds
├── docker-compose.yml        ← Orchestration
├── Dockerfile                ← Multi-stage Go build
├── register-mcp.sh           ← Run this to register ✨
├── .mcp-manifest.json        ← Server metadata
├── docker-readme.md          ← Full Docker guide
├── QUICKSTART.md             ← You are here
├── DOCKER.md                 ← Detailed setup
├── AUTO-DISCOVERY.md         ← Advanced registration
├── CLAUDE.md                 ← Claude Desktop details
├── GEMINI.md                 ← Gemini setup
└── COPILOT.md                ← Copilot setup
```

---

## What Happens After Registration?

1. **Config files are updated** with vsp server details
2. **Your AI client** reads the updated config
3. **Next time you chat**, vsp tools are available
4. **All operations** go through the Docker container → SAP system

```
Your AI Client (Claude/Gemini/Copilot)
    ↓ MCP (JSON-RPC via stdio)
Docker Container (vsp)
    ↓ HTTP
SAP ADT REST API
    ↓
ABAP Code
```

---

## Next Steps

1. ✅ **Pull image** — `docker pull phanikumarvankadaricode/vsp:latest`
2. ✅ **Setup creds** — Edit `.env.docker` with your SAP details
3. ✅ **Start container** — `docker-compose up -d`
4. ✅ **Register** — `bash register-mcp.sh`
5. ✅ **Restart client** — Close & reopen your AI client
6. ✅ **Test** — Ask for tool list, then start using SAP tools

---

## Get Help

- **Setup issues?** See [DOCKER.md](DOCKER.md)
- **Claude Desktop?** See [CLAUDE.md](../CLAUDE.md) or [DOCKER.md](DOCKER.md)
- **Gemini?** See [GEMINI.md](GEMINI.md)
- **Copilot?** See [COPILOT.md](COPILOT.md)
- **Advanced?** See [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md)
- **Feature reference?** See [README.md](README.md)

---

## FAQ

**Q: Do I need Docker Desktop?**  
A: Yes, for local development. For remote Docker, you only need Docker CLI.

**Q: Will my SAP password be stored locally?**  
A: Yes, in `.env.docker` (which is in `.gitignore` — never committed). For production, use Docker secrets or environment variable overrides.

**Q: Can I use this on production SAP systems?**  
A: Yes, but use `VSP_READ_ONLY=true` in `.env.docker` to block all writes.

**Q: What if I have multiple SAP systems?**  
A: Create multiple `.env.docker.XXX` files and multiple Docker containers, or use `.vsp.json` for CLI mode.

**Q: Can I use this without Docker?**  
A: Yes, build the binary locally: `go build -o vsp ./cmd/vsp` and configure your AI client to use `/path/to/vsp` directly.

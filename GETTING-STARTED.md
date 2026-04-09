# Getting Started with vsp MCP

**TL;DR:** Pull image → Add SAP creds → Start container → Run registration script → Restart AI client

---

## 60-Second Setup

```bash
# 1. Get the image
docker pull phanikumarvankadaricode/vsp:latest

# 2. Get the repo (contains compose file and scripts)
git clone https://github.com/phanikumarvankadari/vsp-docker.git
cd vsp-docker/vibing-steampunk

# 3. Configure SAP
cp .env.docker.example .env.docker
# Edit .env.docker with your SAP_URL, SAP_USER, SAP_PASSWORD

# 4. Start container
docker-compose up -d

# 5. Register with AI clients
bash register-mcp.sh
# Answer: mode=1, setup=1, client=1 (Claude) or 2 (Gemini) or 3 (Copilot)

# 6. Restart your AI client completely
# Then ask: "List the tools available from the SAP(vsp) server"
```

Done! ✅

---

## Step-by-Step (Detailed)

### Step 1: Install Docker

If you don't have Docker:
- **macOS/Windows:** Download [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux:** `sudo apt-get install docker.io docker-compose`

Verify:
```bash
docker --version
docker-compose --version
```

---

### Step 2: Get the Image

**Option A: Clone the full repo** (recommended)
```bash
git clone https://github.com/phanikumarvankadari/vsp-docker.git
cd vsp-docker/vibing-steampunk
```

**Option B: Pull just the image**
```bash
docker pull phanikumarvankadaricode/vsp:latest
```

---

### Step 3: Setup SAP Credentials

Create `.env.docker`:
```bash
cp .env.docker.example .env.docker
```

Edit it with your SAP details:
```env
SAP_URL=http://your-sap-host:50000
SAP_USER=DEVELOPER
SAP_PASSWORD=your_password
SAP_CLIENT=001
```

**Test your credentials:**
```bash
curl -I -u $SAP_USER:$SAP_PASSWORD $SAP_URL
# Should NOT give 403 or timeout
```

---

### Step 4: Start the Container

```bash
docker-compose up -d
```

Check it's running:
```bash
docker-compose ps
# vsp should be "Up"
```

View logs if needed:
```bash
docker-compose logs -f vsp
```

---

### Step 5: Register with Your AI Client

```bash
bash register-mcp.sh
```

The script will ask:

1. **"Select mode"**
   - Press `1` (hyperfocused - recommended)
   
2. **"How would you like to run vsp?"**
   - Press `1` (Docker Compose - if you used `docker-compose up`)
   - Or `2` (Direct Docker - if you used `docker run`)
   
3. **"Select clients to register"**
   - Press `1` for Claude Desktop
   - Press `2` for Google Gemini
   - Press `3` for GitHub Copilot
   - (You can pick multiple or all)

4. **"Update config?"**
   - Press `y` to confirm

✅ The script automatically updates your AI client configs!

---

### Step 6: Restart Your AI Client

**Claude Desktop:**
- Cmd+Q to quit completely
- Reopen Claude Desktop

**Google Gemini:**
- Go to gemini.google.com
- Look for Settings → MCP or Model Context Protocol
- Verify vsp is listed

**GitHub Copilot (VS Code):**
- Ctrl+Shift+P → "Developer: Reload Window"

**GitHub Copilot (JetBrains):**
- File → Invalidate Caches → Restart

---

### Step 7: Verify It Works

Ask your AI client:

```
List the tools available from the SAP(vsp) server
```

You should see:
```
SAP(action="...", target="...", params={...})
```

---

## Now You're Ready!

### Try These Examples

**Read ABAP class:**
```
SAP(action="read", target="CLAS ZCL_TRAVEL")
```

**Search for objects:**
```
SAP(action="search", params={"type": "CLAS", "name": "ZCL_*"})
```

**Edit code:**
```
SAP(action="edit", target="CLAS ZCL_TRAVEL", params={
  "method": "GET_DATA",
  "source": "METHOD get_data.\nENDMETHOD."
})
```

**Run tests:**
```
SAP(action="test", target="CLAS ZCL_TRAVEL")
```

**Get help:**
```
SAP(action="help", target="debug")
```

---

## Documentation Map

| Doc | Purpose |
|-----|---------|
| **QUICKSTART.md** | 5-min quick start with all options |
| **SETUP-CHECKLIST.md** | Printable checklist for setup |
| **AUTO-DISCOVERY.md** | How registration works, advanced options |
| **DOCKER.md** | Detailed Docker configuration |
| **CLAUDE.md** | Claude Desktop specifics |
| **GEMINI.md** | Google Gemini setup |
| **COPILOT.md** | GitHub Copilot setup |
| **README.md** | Full feature reference |

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **Docker not installed** | Download [Docker Desktop](https://www.docker.com/products/docker-desktop) |
| **"docker: command not found"** | Add Docker to PATH or use Docker Desktop GUI |
| **"jq: command not found"** | `brew install jq` (macOS) or `apt-get install jq` (Linux) |
| **"No such container"** | Run `docker-compose up -d` first |
| **Auth fails (403)** | Check SAP_URL, SAP_USER, SAP_PASSWORD in `.env.docker` |
| **SAP connection times out** | Verify SAP system is reachable: `curl -I $SAP_URL` |
| **AI client doesn't see vsp** | Fully restart client (not just minimize) |
| **"register-mcp.sh not found"** | Make sure you're in the repo directory with `docker-compose.yml` |

---

## Next Steps

1. ✅ Follow the 60-second setup above
2. ✅ Try a few examples (read, search, test)
3. ✅ Read [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md) for advanced options
4. ✅ Check [README.md](README.md) for full feature list
5. ✅ Explore SAP objects with `SAP(action="help", ...)`

---

## Need Help?

- **Setup stuck?** → See [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md)
- **Want more details?** → See [QUICKSTART.md](QUICKSTART.md)
- **Automation/CI?** → See [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md)
- **Your specific AI client?** → See [CLAUDE.md](CLAUDE.md), [GEMINI.md](GEMINI.md), or [COPILOT.md](COPILOT.md)
- **All features?** → See [README.md](README.md)

---

## Questions?

- GitHub Issues: [phanikumarvankadari/vsp-docker](https://github.com/phanikumarvankadari/vsp-docker/issues)
- Docker Hub: [phanikumarvankadaricode/vsp](https://hub.docker.com/r/phanikumarvankadaricode/vsp)

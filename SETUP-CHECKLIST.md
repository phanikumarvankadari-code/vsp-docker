# vsp MCP Setup Checklist

Use this checklist when setting up vsp on a new machine.

---

## Prerequisites
- [ ] Docker Desktop installed and running
- [ ] Access to SAP system with ADT REST API enabled
- [ ] SAP username and password
- [ ] jq installed (`brew install jq` or `apt-get install jq`)

---

## Setup (5 minutes)

### 1. Get the Code/Image

Choose ONE:

- [ ] **Clone the repo:**
  ```bash
  git clone https://github.com/phanikumarvankadari/vsp-docker.git
  cd vsp-docker/vibing-steampunk
  ```

- [ ] **Or just pull the Docker image:**
  ```bash
  docker pull phanikumarvankadaricode/vsp:latest
  # Then create docker-compose.yml manually
  ```

---

### 2. Configure SAP Credentials

- [ ] Copy template:
  ```bash
  cp .env.docker.example .env.docker
  ```

- [ ] Edit `.env.docker`:
  ```bash
  vim .env.docker
  ```

- [ ] Fill in these fields:
  - [ ] `SAP_URL` = Your SAP ADT endpoint (e.g., `http://host:50000`)
  - [ ] `SAP_USER` = Your SAP username
  - [ ] `SAP_PASSWORD` = Your SAP password
  - [ ] `SAP_CLIENT` = Your SAP client (usually `001`)

- [ ] **Verify credentials work:**
  ```bash
  curl -I -u $SAP_USER:$SAP_PASSWORD $SAP_URL
  # Should return 200 OK or 401/403
  ```

---

### 3. Start the Container

Choose ONE approach:

#### Option A: Docker Compose (Recommended)
- [ ] Run:
  ```bash
  docker-compose up -d
  ```

- [ ] Verify running:
  ```bash
  docker-compose ps
  ```

#### Option B: Direct Docker
- [ ] Run:
  ```bash
  docker run -d \
    --name vsp \
    --env-file .env.docker \
    phanikumarvankadaricode/vsp:latest \
    --mode hyperfocused
  ```

- [ ] Verify running:
  ```bash
  docker ps | grep vsp
  ```

#### Option C: Local Binary (Advanced)
- [ ] Build:
  ```bash
  go build -o vsp ./cmd/vsp
  ```

- [ ] Test:
  ```bash
  ./vsp --help
  ```

---

### 4. Register with AI Clients

- [ ] Run registration script:
  ```bash
  bash register-mcp.sh
  ```

- [ ] Answer prompts:
  - [ ] Mode: Select `1` (hyperfocused - recommended)
  - [ ] Setup method: Select your choice (`1`, `2`, or `3`)
  - [ ] Client(s): Select which you have installed:
    - [ ] Claude Desktop (`1`)
    - [ ] Google Gemini (`2`)
    - [ ] GitHub Copilot (`3`)

- [ ] Confirm updates when prompted

---

### 5. Restart Your AI Client

- [ ] **Claude Desktop:** Quit completely, then reopen
  - [ ] Check: Settings → Developer → check for vsp server

- [ ] **Google Gemini:** 
  - [ ] Go to gemini.google.com
  - [ ] Settings → enable "Model Context Protocol"
  - [ ] Reload page

- [ ] **GitHub Copilot:**
  - [ ] VS Code: Reload window (Ctrl+Shift+P → "Reload Window")
  - [ ] JetBrains: File → Invalidate Caches → Restart

---

## Verification

- [ ] In your AI client, ask:
  ```
  List the tools available from the SAP(vsp) server
  ```

- [ ] You should see the hyperfocused tool:
  ```
  SAP(action="...", target="...", params={...})
  ```

---

## Test Drive

Try one of these:

- [ ] **Read a class:**
  ```
  SAP(action="read", target="CLAS ZCL_TRAVEL")
  ```

- [ ] **Search for objects:**
  ```
  SAP(action="search", params={"type": "CLAS", "name": "ZCL_*"})
  ```

- [ ] **Get help:**
  ```
  SAP(action="help", target="debug")
  ```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Docker not found | Install [Docker Desktop](https://www.docker.com/products/docker-desktop) |
| "No such container" | Run `docker-compose up -d` or `docker run ...` |
| Auth failed | Verify SAP credentials; test with `curl -I` |
| Client doesn't see vsp | Fully close and reopen client (not just minimize) |
| Script not found | Make sure you're in the repo directory |
| jq not found | `brew install jq` (macOS) or `apt-get install jq` (Linux) |

---

## Common Commands

```bash
# View logs
docker-compose logs -f vsp

# Stop container
docker-compose down

# Rebuild image
docker-compose build --no-cache

# Run registration again
bash register-mcp.sh

# Re-register specific client
MCP_CLIENT=claude bash register-mcp.sh
```

---

## Next: Start Using SAP Tools

Once verified, you can:

1. **Read ABAP code** for analysis
2. **Edit and create** ABAP objects
3. **Run tests** and ATC checks
4. **Analyze dependencies** and health
5. **Debug ABAP** with breakpoints
6. **Manage transports**

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

---

## Support

- **Setup help:** [DOCKER.md](DOCKER.md)
- **Multi-client:** [AUTO-DISCOVERY.md](AUTO-DISCOVERY.md)
- **Features:** [README.md](README.md)
- **Client-specific:**
  - Claude: [DOCKER.md](DOCKER.md)
  - Gemini: [GEMINI.md](GEMINI.md)
  - Copilot: [COPILOT.md](COPILOT.md)

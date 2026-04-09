# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**vsp** — Go-native MCP server and CLI for SAP ABAP Development Tools (ADT). Single binary, 9 platforms, zero dependencies. Exposes 81–147 tools (or 1 universal tool) over JSON-RPC/stdio.

> **Doc intent:** CLAUDE.md = dev context. README.md = user onboarding. reports/ = research/history. contexts/ = session handoff.

---

## Build, Test, Lint

```bash
# Build
go build -o vsp ./cmd/vsp

# Unit tests
go test ./...
go test -run TestSafetyReadOnly -v ./pkg/adt/           # Single test by name
go test -v ./pkg/cache/                                  # Single package

# Integration tests (require SAP_* env vars: URL, USER, PASSWORD, CLIENT)
go test -tags=integration -v ./pkg/adt/

# Lint
golangci-lint run ./...                                 # Full linting with .golangci.yml

# Format
gofumpt -w .                                            # gofumpt (preferred over go fmt)
```

Key build flags: `--mode focused|expert|hyperfocused`, `--read-only`, `--allowed-packages "Z*"`, `--disabled-groups 5THDICGRX`

---

## Docker & mcp-toolkit Setup

vsp runs as a containerized stdio MCP server that integrates with **Claude Desktop** and **mcp-toolkit**.

### Quick Start (Docker Compose)

```bash
# 1. Create .env.docker from example
cp .env.docker.example .env.docker

# 2. Edit .env.docker with your SAP credentials
vim .env.docker

# 3. Build and start container
docker-compose up -d

# 4. Register with Claude Desktop (see below)
```

### Register with Claude Desktop

vsp runs as an MCP server on stdio. Claude Desktop discovers it via JSON config in:
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux:** `~/.config/Claude/claude_desktop_config.json`

**Option A: Docker Compose (recommended for local dev)**

Start container: `docker-compose up -d`

Add to `claude_desktop_config.json`:
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

**Option B: Direct Docker (no compose)**

Build image: `docker build -t vsp:latest .`

Add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "vsp": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env-file", "/path/to/.env.docker",
        "vsp:latest"
      ]
    }
  }
}
```

**Option C: Local Binary (no Docker)**

Build: `go build -o vsp ./cmd/vsp`

Add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "vsp": {
      "command": "/path/to/vsp",
      "env": {
        "SAP_URL": "http://your-host:50000",
        "SAP_USER": "DEVELOPER",
        "SAP_PASSWORD": "password",
        "SAP_CLIENT": "001",
        "VSP_MODE": "hyperfocused"
      }
    }
  }
}
```

After restarting Claude Desktop, ask: **"List the tools available from the SAP(vsp) server"** — you should see the hyperfocused universal tool.

### Docker Environment Variables

All standard SAP connection flags work as env vars inside the container:

| Env Var | Default | Purpose |
|---------|---------|---------|
| `SAP_URL` | (required) | SAP ADT REST API endpoint |
| `SAP_USER` | (required) | SAP username |
| `SAP_PASSWORD` | (required) | SAP password |
| `SAP_CLIENT` | 001 | SAP client number |
| `SAP_LANGUAGE` | EN | SAP language |
| `SAP_INSECURE` | false | Skip TLS verification |
| `VSP_MODE` | hyperfocused | Tool mode: `focused`, `expert`, or `hyperfocused` |
| `VSP_READ_ONLY` | false | Block all write operations |
| `VSP_ALLOWED_PACKAGES` | (none) | Allowlist: `Z*,$TMP` |
| `VSP_DISABLED_GROUPS` | (none) | Disable tool groups: `5THDICGRX` |

### Dockerfile Notes

- Multi-stage build: Go 1.23 → Alpine runtime
- Minimal size: `~50MB` with CA certs only
- Runs `vsp --mode hyperfocused` by default (can override in docker-compose)
- No port exposure needed (MCP uses stdio)

---

## Current Priorities

### 1. Graph Engine (`pkg/graph/`) — In Progress
Sequence: unify existing dep logic → SQL/ADT adapters → impact/path queries.
- **Done:** core types, parser dep extraction, boundary analyzer (11 tests)
- **Pending:** SQL adapters (CROSS/WBCROSSGT/D010INC), ADT adapters, unify `cli_deps.go` + `cli_extra.go` + `ctxcomp/analyzer.go`
- **Design:** [002](reports/2026-04-05-002-graph-engine-design.md), [003](reports/2026-04-05-003-graph-engine-alignment-for-claude.md)

### 2. GUI Debugger (Issue #2) — Strategic
Plan: MCP debug sessions → DAP → Web UI. ADT REST API mapped from `CL_TPDA_ADT_RES_APP`.  
**Design:** [001](reports/2026-04-05-001-gui-debugger-design.md)

### 3. Open Issues
- **#88** Lock handle bug (EditSource/WriteSource) — real user report
- **#55** RunReport in APC — architectural limit
- **#46, #45** Sync script — low effort

---

## Architecture & Codebase

### High-Level Flow

```
AI Agent (Claude, Gemini, etc.)
  → MCP Server (internal/mcp)
    → ADT Client (pkg/adt)
      → HTTP Transport (HTTP, CSRF, sessions)
        → SAP ADT REST API
```

**Write operations follow lifecycle:** GetSource → SyntaxCheck → Lock → UpdateSource → Unlock → Activate. The `EditSource` and `WriteSource` workflows in `pkg/adt/workflows.go` automate this.

### Package Organization

| Path | Purpose |
|------|---------|
| `cmd/vsp/` | CLI entry (cobra + viper), 28 commands |
| `internal/mcp/` | MCP server, handlers, tool registration |
| `pkg/adt/` | ADT client facade, HTTP transport, CRUD lifecycle, workflows |
| `pkg/graph/` | Dependency graph engine (in progress) |
| `pkg/ctxcomp/` | Context compression (dep resolution for read) |
| `pkg/abaplint/` | ABAP lexer + parser (91 statements, 8 lint rules) |
| `pkg/dsl/` | Fluent API, YAML workflows, batch ops |
| `pkg/cache/` | In-memory + SQLite caching |
| `pkg/scripting/` | Lua scripting engine (50+ ADT bindings) |

### Handler Files (38 files)

Handlers are organized by domain in `internal/mcp/handlers_*.go`:

| Category | Files | Purpose |
|----------|-------|---------|
| **Core** | `handlers_source.go`, `handlers_read.go` | Source read/get operations |
| **Write** | `handlers_crud.go`, `handlers_classinclude.go` | Create, update, delete, activate |
| **Search** | `handlers_search.go`, `handlers_grep.go` | Object/code search |
| **Analysis** | `handlers_analysis.go`, `handlers_health.go`, `handlers_codeanalysis.go` | Package health, boundaries, co-change |
| **Graph** | `handlers_graph.go`, `handlers_transport_analysis.go` | Dependency graphs, transport correlation |
| **Debug** | `handlers_debugger.go`, `handlers_debugger_legacy.go`, `handlers_amdp.go` | Breakpoints, step, inspect |
| **Test/QA** | `handlers_testing.go`, `handlers_atc.go` | Unit tests, ATC checks |
| **Deploy** | `handlers_deploy.go`, `handlers_install.go` | File deployment, bootstrap |
| **DevOps** | `handlers_transport.go`, `handlers_gcts.go`, `handlers_git.go` | Transport management, Git integration |
| **Advanced** | `handlers_workflow.go`, `handlers_cds.go`, `handlers_servicebinding.go` | YAML workflows, CDS, RAP |
| **Diagnostics** | `handlers_dumps.go`, `handlers_traces.go`, `handlers_sqltrace.go` | Dump analysis, trace collection |
| **Other** | `handlers_devtools.go`, `handlers_codeintel.go`, `handlers_context.go`, `handlers_fileio.go`, `handlers_ui5.go`, `handlers_report.go`, `handlers_revisions.go`, `handlers_i18n.go`, `handlers_help.go`, `handlers_system.go` | Various operations |
| **Hyperfocused** | `handlers_universal.go` | Single `SAP(action, target, params)` tool |

---

## Tool Modes

### Focused Mode (Default)
**81 essential tools.** Whitelist-based; see `tools_focused.go` for the list.
- MCP schema tokens: ~14,000
- Best for Claude (balances capability and token efficiency)
- Some experimental/advanced tools disabled

```bash
vsp --mode focused
```

### Expert Mode
**122 all tools.** Includes every handler, experimental features, advanced debugger tools.
- MCP schema tokens: ~40,000
- Full surface area
- Some tools unreliable or require specific SAP versions

```bash
vsp --mode expert
```

### Hyperfocused Mode (Recommended for Most)
**1 universal tool.** `SAP(action="...", target="...", params={...})` replaces all 122 tools.
- MCP schema tokens: **~200** (99.5% reduction)
- Maximum capability per token
- All safety controls work identically

```bash
vsp --mode hyperfocused

# Usage:
# SAP(action="read", target="CLAS ZCL_TRAVEL")
# SAP(action="edit", target="CLAS ZCL_TRAVEL", params={"source": "..."})
# SAP(action="create", target="DEVC", params={"name": "$ZOZIK"})
```

---

## Adding a New MCP Tool

### 1. Add ADT Client Method (if needed)
Create or extend a method in `pkg/adt/`:
- **Read ops** → `client.go`
- **Write ops** → `crud.go`
- **Dev tools** → `devtools.go`
- **Code intelligence** → `codeintel.go`
- **Debugger** → `debugger.go` (REST) or `websocket_debug.go` (WebSocket)

**Pattern for read:**
```go
func (c *Client) GetSomething(ctx context.Context, name string) (*Result, error) {
    url := fmt.Sprintf("/sap/bc/adt/path/%s", name)
    resp, err := c.http.Get(ctx, url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    // Parse XML/JSON response
    var result Result
    // ... XML unmarshaling or parsing ...
    return &result, nil
}
```

**Pattern for write:**
```go
func (c *Client) UpdateSomething(ctx context.Context, name, content string) error {
    url := fmt.Sprintf("/sap/bc/adt/path/%s", name)
    return c.http.Put(ctx, url, "text/plain", strings.NewReader(content))
}
```

### 2. Add Handler
Create or extend a handler file in `internal/mcp/handlers_<category>.go`:

```go
func (s *Server) handleNewTool(ctx context.Context, args map[string]any) (*mcp.CallToolResult, error) {
    name, _ := getString(args, "name")
    result, err := s.adtClient.NewMethod(ctx, name)
    if err != nil {
        return mcp.NewToolResultError(err.Error()), nil
    }
    return mcp.NewToolResultText(formatResult(result)), nil
}
```

**Important:** Handlers always return `(result, nil)` — errors go through `mcp.NewToolResultError()`, never as Go errors.

### 3. Register Tool
Add to `internal/mcp/tools_register.go` in the appropriate `registerXTools()` function:

```go
if shouldRegister("NewTool") {
    s.AddTool(mcp.NewTool(
        "new_tool",                                    // MCP tool name
        "Human description",                           // Description for Claude
        map[string]mcp.ToolParameter{
            "name": {
                Type:        "string",
                Description: "The name of the thing",
                Required:    true,
            },
        },
        s.handleNewTool,
    ))
}
```

### 4. Add to Focused Mode (if appropriate)
In `internal/mcp/tools_focused.go`:
```go
"NewTool": true,
```

### 5. Add to Tool Group (if applicable)
In `internal/mcp/tools_groups.go`, add to a group map or create new:
```go
"T": []string{"RunUnitTests", "RunATCCheck", "NewTool"},
```

---

## Safety System

All write operations check `SafetyConfig` before execution. Operation types are single-letter codes:

| Code | Type | Examples |
|------|------|----------|
| **R** | Read | GetSource, GetObject |
| **S** | Search | SearchObjects, SearchCode |
| **Q** | Query | QueryTable |
| **F** | Free SQL | ExecuteSQL |
| **C** | Create | CreateClass, CreatePackage |
| **U** | Update | UpdateSource, ModifyObject |
| **D** | Delete | DeleteObject, DeletePackage |
| **A** | Activate | ActivateObject |
| **T** | Test | RunUnitTest, RunATCCheck |
| **L** | Lock | LockObject (internal) |
| **I** | Intelligence | ParseCode, AnalyzeCode (read-only analysis) |
| **W** | Workflow | ExecuteWorkflow, DeployFile |
| **X** | Transport | TransportObject, CreateTransport |

Configuration priority: CLI flags > environment variables > `.env` file > defaults.

```bash
vsp --read-only                              # Disable all writes (R/S/Q/I only)
vsp --allowed-ops "RSQ"                      # Whitelist only Read, Search, Query
vsp --allowed-packages "Z*" "$ZDEV"          # Only these packages
vsp --disabled-groups "5THD"                 # Disable UI5(5), Test(T), HANA(H), Debug(D)
```

---

## Configuration Pattern (Functional Options)

ADT client uses functional options for flexible configuration:

```go
client := adt.NewClient(
    "http://dev.example.com:50000",
    adt.WithUser("DEVELOPER"),
    adt.WithPassword("password"),
    adt.WithClient("001"),
    adt.WithInsecureSkipVerify(),           // Skip TLS verification
    adt.WithCustomHTTPClient(customClient),
)
```

See `pkg/adt/config.go` for all available options.

---

## Integration Tests

Integration tests require a live SAP system via environment variables:

```bash
export SAP_URL="http://dev.example.com:50000"
export SAP_USER="DEVELOPER"
export SAP_PASSWORD="password"
export SAP_CLIENT="001"

go test -tags=integration -v ./pkg/adt/
```

**Test behavior:**
- Tests create temporary objects in the `$TMP` package
- Tests automatically clean up after themselves
- If a test fails, manual cleanup in SAP may be needed
- Integration tests do NOT run without the `integration` build tag

---

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| CSRF errors | Token expired or incorrect header | Handled automatically in `http.go` — client refreshes on 403 |
| Lock conflicts | Object locked by another session | Edit handler auto-locks and unlocks; use `read-only` flag if needed |
| Session issues | Some CRUD/debugger flows are stateful | Verify stateful/stateless behavior before changing transport or auth |
| Auth failures | Using basic auth AND cookies | Use either basic auth OR cookies, not both |
| Debugger/RFC/RunReport fail | Missing ZADT_VSP custom development object | Install with `vsp install zadt-vsp` |
| REST breakpoints 403 | Newer SAP versions disabled REST debug API | Use WebSocket debug via ZADT_VSP (`handlers_debugger.go`) |

---

## Security

Never commit `.env`, `cookies.txt`, `.mcp.json`, or local agent/MCP config files — all are in `.gitignore`.

---

## Conventions

- **Reports:** `reports/YYYY-MM-DD-NNN-title.md` with sequential numbering per day
- **SAP Objects:** `ZADT_<nn>_<name>` (packages, classes), `ZCL_ADT_<name>` (classes), packages `$ZADT*`
- **Git flow:** Single commit per feature/fix with clear message; squash before merging if needed
- **Release:** GoReleaser (`.goreleaser.yml`) with git-cliff changelogs (`cliff.toml`); triggered via Release workflow dispatch

---

## Areas Requiring Care

| Area | Risk | Notes |
|------|------|-------|
| `pkg/graph/` | New, incomplete | Only parser adapter; SQL/ADT adapters pending |
| `handlers_debugger.go` | WebSocket-only | REST breakpoints 403 on newer SAP; use ZADT_VSP |
| `handlers_amdp.go` | Experimental | Session works, breakpoints unreliable |
| `pkg/adt/ui5.go` | Read-only | Write needs `/UI5/CL_REPOSITORY_LOAD` |
| `pkg/llvm2abap/`, `pkg/wasmcomp/` | Research | Not production; don't treat as stable |
| `pkg/adt/debugger.go` (REST) | Deprecated | Prefer `websocket_debug.go` |
| `docs/cli-agents/*` | Config drift | Codex TOML format may differ from Claude/Gemini JSON docs |

---

## Key Helpers & Utilities

- **String extraction:** Use `getString(args, "key")` for type-safe arg access in handlers
- **Error results:** Always use `mcp.NewToolResultError(msg)` for errors, never return Go error
- **XML parsing:** Types in `pkg/adt/xml.go` — use struct tags for unmarshaling ADT responses
- **Context deadline:** Handlers receive `ctx context.Context` — respect it for timeouts
- **Functional options:** Pass options to `NewClient()` rather than modifying after creation

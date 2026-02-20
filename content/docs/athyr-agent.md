---
title: "Athyr Agent"
description: "Define AI agents in YAML and run them without writing code"
---

Athyr Agent is a YAML-driven agent runner. Define your agent's behavior, topics, and tools in a YAML file, connect it to an Athyr server, and start processing messages — no code required.

## Installation

### Homebrew (macOS)

```bash
brew install athyr-tech/tap/athyr-agent
```

### Download Binary

Pre-built binaries are available for macOS and Linux from [GitHub Releases](https://github.com/athyr-tech/athyr-agent/releases).

**macOS:**

```bash
# Apple Silicon (M1/M2/M3/M4)
curl -LO https://github.com/athyr-tech/athyr-agent/releases/latest/download/athyr-agent-darwin-arm64.tar.gz

# Intel
curl -LO https://github.com/athyr-tech/athyr-agent/releases/latest/download/athyr-agent-darwin-amd64.tar.gz

tar xzf athyr-agent-darwin-*.tar.gz
sudo mv athyr-agent /usr/local/bin/
```

**Linux:**

```bash
# AMD64
curl -LO https://github.com/athyr-tech/athyr-agent/releases/latest/download/athyr-agent-linux-amd64.tar.gz

# ARM64
curl -LO https://github.com/athyr-tech/athyr-agent/releases/latest/download/athyr-agent-linux-arm64.tar.gz

tar xzf athyr-agent-linux-*.tar.gz
sudo mv athyr-agent /usr/local/bin/
```

### Build from Source

Requires Go 1.25+:

```bash
go install github.com/athyr-tech/athyr-agent/cmd/athyr-agent@latest
```

### Verify

```bash
athyr-agent version
```

## Quick Start

Create a file called `agent.yaml`:

```yaml
agent:
  name: my-agent
  description: A simple agent
  model: google/gemini-2.5-flash-lite
  instructions: |
    You are a helpful assistant. Respond concisely.
  topics:
    subscribe: [requests.new]
    publish: [requests.done]
```

Run it:

```bash
athyr-agent run agent.yaml --server localhost:9090
```

Or with the interactive TUI:

```bash
athyr-agent run agent.yaml --server localhost:9090 --tui
```

The agent connects to your Athyr server, subscribes to the `requests.new` topic, processes messages through the LLM, and publishes responses to `requests.done`.

## YAML Configuration

All configuration lives under the `agent` key. The three required fields are `name`, `model`, and `topics`.

### Full Example

This example shows an agent that mixes Lua plugins with Athyr topics — it watches the filesystem for new files via a plugin, also receives tasks from other agents via an Athyr topic, and publishes results to both an Athyr topic and an external webhook:

```yaml
agent:
  name: file-processor
  description: Watches for new files and posts results to a webhook
  model: google/gemini-2.5-flash-lite
  instructions: |
    You are a helpful assistant. Summarize any content you receive.

  topics:
    subscribe:
      - file-watcher    # Plugin source — polls the host filesystem for new files
      - tasks.assigned  # Athyr topic — receives messages from other agents
    publish:
      - results.ready   # Athyr topic — other agents can subscribe to this
      - webhook-output  # Plugin destination — posts to an external webhook

  memory:
    enabled: true
    profile:
      type: rolling_window
      max_tokens: 4096
      summarization_threshold: 3000

  mcp:
    servers:
      - name: docker-gateway
        command: ["docker", "mcp", "gateway", "run"]

  plugins:
    - name: file-watcher
      file: ./plugins/watcher.lua
      config:
        path: /var/log/app
        interval: 5

    - name: webhook-output
      file: ./plugins/http-output.lua
      config:
        url: https://hooks.example.com/notify

  connection:
    timeout: 60s
    max_retries: 0
    base_backoff: 1s
    max_backoff: 30s
```

### Agent Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Unique agent name for Athyr registration |
| `description` | string | no | Human-readable description |
| `model` | string | yes | LLM model identifier (e.g., `google/gemini-2.5-flash-lite`, `openai/gpt-4o-mini`) |
| `instructions` | string | no | System prompt sent with every LLM request |
| `topics` | object | yes | Pub/sub topic configuration |
| `memory` | object | no | Session memory settings |
| `mcp` | object | no | MCP tool server connections |
| `plugins` | list | no | Lua plugin definitions |
| `connection` | object | no | Connection tuning |

### Topics

Defines which topics the agent subscribes to and publishes on. Topic names can refer to Athyr topics or Lua plugin names — when a name matches a plugin's `name`, the runner routes through the plugin. Athyr topics and plugins can be mixed freely.

```yaml
topics:
  subscribe:
    - documents.new
    - documents.updated
  publish:
    - summaries.ready
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subscribe` | list | yes | Topics to receive messages from |
| `publish` | list | yes | Default topics to send responses to |
| `routes` | list | no | Dynamic routing destinations |

### Dynamic Routing

Routes let the LLM decide where to send responses. When routes are configured, routing instructions are appended to the system prompt automatically. The LLM returns a JSON response with a `route_to` field — if the route is valid, the response goes there. Otherwise it falls back to the default `publish` topics.

```yaml
agent:
  name: classifier
  description: Classifies and routes support tickets
  model: google/gemini-2.5-flash-lite
  instructions: |
    Analyze the customer's message and classify it as billing or technical.

  topics:
    subscribe:
      - ticket.new
    publish:
      - ticket.unknown    # Fallback if routing fails
    routes:
      - topic: ticket.billing
        description: Payment issues, invoices, refunds
      - topic: ticket.technical
        description: Bugs, errors, crashes, feature requests
```

### Conversation Memory

Enable multi-turn conversations by activating session memory. Messages must include a `session_id` field in their JSON payload.

```yaml
memory:
  enabled: true
  profile:
    type: rolling_window
    max_tokens: 4096
    summarization_threshold: 3000
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `false` | Enable session memory |
| `session_prefix` | string | — | Prefix for session IDs |
| `ttl` | string | — | Session expiration (e.g., `1h`, `24h`) |
| `profile.type` | string | `rolling_window` | Memory management strategy |
| `profile.max_tokens` | int | `4096` | Max tokens kept in memory |
| `profile.summarization_threshold` | int | `3000` | Token count that triggers summarization |

Messages with memory use JSON format:

```json
{"session_id": "user-123", "content": "Hello, remember me?"}
```

Plain text messages (without `session_id`) are processed normally without memory.

### MCP Tools

Connect to [MCP](https://modelcontextprotocol.io/) servers to give your agent access to external tools. Tools are discovered automatically on startup and passed to the LLM with each request.

```yaml
mcp:
  servers:
    # Local subprocess (stdio transport)
    - name: docker-gateway
      command: ["docker", "mcp", "gateway", "run"]
      env:
        API_KEY: "sk-..."

    # Remote server (HTTP transport)
    - name: remote-tools
      url: https://mcp.example.com/tools
```

Each server needs a `name` and exactly one transport — either `command` (subprocess) or `url` (HTTP endpoint). Optional `env` provides environment variables for subprocess commands.

### Connection Tuning

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `timeout` | duration | `60s` | Request timeout |
| `max_retries` | int | `0` (infinite) | Max reconnection retries |
| `base_backoff` | duration | `1s` | Initial backoff between retries |
| `max_backoff` | duration | `30s` | Maximum backoff duration |

Duration values use Go syntax: `30s`, `2m`, `1h`.

## Lua Plugins

Plugins extend the agent's transport layer — they let agents interact with the host machine and external systems alongside Athyr topics. A file-watcher plugin can trigger the agent when new files appear on the host filesystem; an HTTP plugin can post responses to an external webhook. Plugins and Athyr topics work together in the same agent.

Plugins are Lua scripts that implement a simple contract and run in a sandboxed VM.

### How It Works

A plugin's `name` must appear in `topics.subscribe` or `topics.publish` to be active:

- **Source plugin** (name in `subscribe`): The runner calls `subscribe(config, callback)`. When the Lua code calls `callback(data)`, the data enters the agent as a message — it goes through the LLM, tool calls, routing, and produces a response.
- **Destination plugin** (name in `publish`): When the agent produces a response routed to this plugin, it calls the plugin's `publish(config, data)` with the response content.

### Plugin Contract

A plugin is a Lua file that defines one or both of these functions:

```lua
-- Source: called when agent starts, runs in its own goroutine
function subscribe(config, callback)
    -- config: table with values from YAML config section
    -- callback: function(string) — sends data to the agent
end

-- Destination: called each time the agent produces a response for this plugin
function publish(config, data)
    -- config: table with values from YAML config section
    -- data: string — the agent's response content
end
```

### Example: File Watcher to Webhook

**plugins/watcher.lua** (source):

```lua
local fs = require("fs")

function subscribe(config, callback)
    local seen = {}
    local interval = config.interval or 5

    -- Build initial set of known files
    local entries = fs.list(config.path)
    for i = 1, #entries do
        seen[entries[i]] = true
    end

    while true do
        sleep(interval)
        local current = fs.list(config.path)
        for i = 1, #current do
            local name = current[i]
            if not seen[name] then
                seen[name] = true
                local content = fs.read(config.path .. "/" .. name)
                callback(content)
                log("info", "file-watcher: new file detected: " .. name)
            end
        end
    end
end
```

**plugins/http-output.lua** (destination):

```lua
local http = require("http")
local json = require("json")

function publish(config, data)
    local payload = json.encode({
        content = data,
    })

    local headers = {
        ["Content-Type"] = config.content_type or "application/json",
    }

    local resp = http.post(config.url, payload, headers)
    if resp.status >= 400 then
        log("error", "http-output: webhook returned status " .. resp.status)
    else
        log("info", "http-output: posted to " .. config.url)
    end
end
```

**agent.yaml**:

```yaml
agent:
  name: file-processor
  description: Processes new files and sends results to a webhook
  model: google/gemini-2.5-flash-lite
  instructions: |
    You receive the contents of newly created files.
    Analyze the content and provide a brief summary.

  topics:
    subscribe:
      - file-watcher
    publish:
      - http-output

  plugins:
    - name: file-watcher
      file: ./plugins/watcher.lua
      config:
        path: ./watched
        interval: 5

    - name: http-output
      file: ./plugins/http-output.lua
      config:
        url: https://httpbin.org/post
        content_type: application/json
```

### Bridge Modules

Plugins have access to these Go-backed modules:

**`fs` — File System**

```lua
local fs = require("fs")
local content = fs.read("/path/to/file")
fs.write("/path/to/file", "data")
local entries = fs.list("/path/to/dir")
```

**`http` — HTTP Client**

```lua
local http = require("http")
local resp = http.get("https://api.example.com/data")
-- resp.body, resp.status

local resp = http.post("https://api.example.com/webhook", '{"key": "value"}', {
    ["Content-Type"] = "application/json"
})
```

**`json` — JSON Encoding/Decoding**

```lua
local json = require("json")
local str = json.encode({name = "test", count = 42})
local tbl = json.decode('{"name": "test"}')
```

**Global Functions**

```lua
sleep(5)                           -- sleep 5 seconds
sleep(0.1)                         -- sleep 100 milliseconds
log("info", "processing started")  -- levels: debug, info, warn, error
```

### Plugin Restrictions

Limit what a plugin can access using the `restrict` field:

```yaml
plugins:
  - name: community-formatter
    file: ./plugins/formatter.lua
    restrict:
      - http           # Blocks all http.* functions
      - fs.write       # Blocks fs.write only
```

| Value | Effect |
|-------|--------|
| `http` | Blocks `http.get` and `http.post` |
| `fs` | Blocks all `fs.*` functions |
| `fs.write` | Blocks `fs.write` only |
| `fs.read` | Blocks `fs.read` only |
| `http.post` | Blocks `http.post` only |

### Sandbox

Each plugin runs in its own Lua VM with:

- Safe standard libraries (`base`, `table`, `string`, `math`, `os`, `package`)
- Safe `os` functions only: `os.time()`, `os.date()`, `os.clock()`, `os.difftime()` — dangerous functions like `os.execute` and `os.remove` are removed
- `dofile` and `loadfile` removed
- Separate state — plugins cannot interfere with each other

## CLI Reference

| Command | Description |
|---------|-------------|
| `run <file>` | Run an agent from a YAML config file |
| `validate <file>` | Check YAML syntax without running |
| `version` | Display version |
| `disconnect <id>` | Remove an agent from the Athyr server |

| Flag | Description |
|------|-------------|
| `--server` | Athyr server address (default: `localhost:9090`) |
| `--insecure` | Disable TLS |
| `--tui` | Enable interactive terminal UI |
| `--verbose` | Debug-level logging |
| `--log-format` | Output format: `text` or `json` |

Validate before running:

```bash
athyr-agent validate agent.yaml
```

## Examples

The [athyr-agent repository](https://github.com/athyr-tech/athyr-agent/tree/main/examples) includes ready-to-run examples:

| Example | Description |
|---------|-------------|
| `simple-test.yaml` | Basic connectivity testing |
| `summarizer.yaml` | Document summarization with structured output |
| `memory-chat.yaml` | Multi-turn conversations with session memory |
| `mcp-tools.yaml` | Research assistant with MCP tool integration |
| `plugin-agent.yaml` | File watcher → LLM → webhook pipeline |
| `demo/` | Multi-agent support system with classifier routing |

## Next Steps

- [Agents](/docs/agents/) — How agents work in Athyr
- [Configuration](/docs/configuration/) — Athyr server configuration
- [Go SDK](/docs/sdk-go/) — Build agents programmatically with Go
- [Python SDK](/docs/sdk-python/) — Build agents with Python

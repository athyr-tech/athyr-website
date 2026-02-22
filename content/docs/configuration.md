---
title: "Configuration"
description: "Athyr server configuration reference"
---

Athyr is configured via a YAML file. By default, it looks for `athyr.yaml` in the current directory or `/etc/athyr/`.

## Minimal Configuration

Athyr works with sensible defaults. A minimal config just needs LLM backends:

```yaml
llm:
  backends:
    - name: local
      type: ollama
      url: http://localhost:11434
```

## Full Configuration Reference

```yaml
# Server ports
server:
  grpc_port: 9090
  http_port: 8080

# Storage settings
storage:
  data_dir: ./data
  max_memory: 2GB
  max_storage: 50GB
  retention:
    sessions: 24h
    agents: 168h
    responses: 5m

# LLM provider configuration
llm:
  backends:
    - name: local
      type: ollama
      url: http://localhost:11434
    - name: cloud
      type: openrouter
      url: https://openrouter.ai/api/v1
      api_key: ${OPENROUTER_API_KEY}
  retry:
    max_attempts: 3
    backoff: exponential

# Memory session defaults
memory:
  default_profile: rolling_window
  max_tokens: 4096
  summarization_threshold: 3000

# Agent lifecycle settings
agents:
  heartbeat_interval: 30s
  disconnect_timeout: 60s
```

## Configuration Sections

### server

API server settings.

| Field | Default | Description |
|-------|---------|-------------|
| `grpc_port` | `9090` | Port for gRPC API |
| `http_port` | `8080` | Port for HTTP API |

### storage

Data persistence settings.

| Field | Default | Description |
|-------|---------|-------------|
| `data_dir` | `./data` | Directory for persistent data |
| `max_memory` | `2GB` | Maximum memory for caching |
| `max_storage` | `50GB` | Maximum disk storage |

#### storage.retention

Automatic cleanup policies.

| Field | Default | Description |
|-------|---------|-------------|
| `sessions` | `24h` | How long to keep inactive sessions |
| `agents` | `168h` | How long to keep disconnected agent records |
| `responses` | `5m` | How long to keep streaming response data |

Set to `0` to disable automatic cleanup.

### llm

LLM gateway configuration.

#### llm.backends

List of LLM providers. Each backend has:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier |
| `type` | Yes | Provider type (matches Lua script filename, e.g. `ollama`, `openrouter`, or [custom](/docs/custom-providers/)) |
| `url` | Yes | Provider API URL |
| `api_key` | No | API key (required for OpenRouter) |
| `priority` | No | Routing priority (lower = preferred) |

#### llm.retry

Retry behavior for failed LLM requests.

| Field | Default | Description |
|-------|---------|-------------|
| `max_attempts` | `3` | Maximum retry attempts |
| `backoff` | `exponential` | Strategy: `exponential`, `linear`, `fixed` |

### memory

Default settings for memory sessions.

| Field | Default | Description |
|-------|---------|-------------|
| `default_profile` | `rolling_window` | Memory strategy |
| `max_tokens` | `4096` | Default max context tokens |
| `summarization_threshold` | `3000` | Token count to trigger summarization |

### agents

Agent lifecycle settings.

| Field | Default | Description |
|-------|---------|-------------|
| `heartbeat_interval` | `30s` | How often agents send heartbeats |
| `disconnect_timeout` | `60s` | Time without heartbeat before disconnect |

## Environment Variables

Use `${VAR_NAME}` syntax to reference environment variables:

```yaml
llm:
  backends:
    - name: cloud
      type: openrouter
      api_key: ${OPENROUTER_API_KEY}
```

## Config File Locations

Athyr searches for configuration in order:

1. Path specified by `--config` flag
2. `./athyr.yaml` (current directory)
3. `/etc/athyr/athyr.yaml`

If no config file is found, Athyr uses defaults.

## Size Values

Storage sizes support human-readable units:

- `KB` - Kilobytes
- `MB` - Megabytes
- `GB` - Gigabytes
- `TB` - Terabytes

Examples: `512MB`, `2GB`, `50GB`

## Duration Values

Time durations use Go duration format:

- `s` - Seconds
- `m` - Minutes
- `h` - Hours

Examples: `30s`, `5m`, `24h`, `168h`

## Next Steps

- [CLI Commands](/docs/cli/) - Command-line reference
- [LLM Gateway](/docs/gateway/) - LLM provider details
- [Quick Start](/docs/quickstart/) - Get started
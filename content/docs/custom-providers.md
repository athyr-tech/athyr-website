---
title: "Custom Providers"
description: "Adding LLM providers via Lua scripts"
---

Athyr uses Lua scripts to define LLM provider integrations. Each provider is a small Lua file that describes how to talk to an OpenAI-compatible API. You can add new providers without recompiling the binary.

## Quick Start

Create a `.lua` file in your data directory under `providers/`:

```
<data-dir>/providers/my-provider.lua
```

Then reference it in `athyr.yaml`:

```yaml
llm:
  backends:
    - name: my-provider
      type: my-provider    # matches the filename (without .lua)
      url: http://localhost:8080
      api_key: sk-...
```

Restart Athyr. The provider is now available.

## Provider Script Contract

A provider script must return a Lua table with the following fields:

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `protocol` | string | Must be `"openai_compat"` |
| `base_url` | string | Base URL of the API |
| `completions_endpoint` | string | Path for chat completions (e.g. `/v1/chat/completions`) |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | from config | Display name for the backend |
| `models_endpoint` | string | `/v1/models` | Path for listing models |
| `health_endpoint` | string | `/` | Path for health checks |
| `auth_type` | string | `"none"` | Authentication type: `"none"`, `"bearer"`, or `"x-api-key"` |
| `auth_key` | string | | API key value (usually from `config.api_key`) |
| `headers` | table | | Additional HTTP headers to send with every request |

### Optional Hooks

Hooks are functions on the provider table that customize behavior:

| Hook | Signature | Purpose |
|------|-----------|---------|
| `parse_models` | `function(response) -> table` | Custom parsing of the models list response |
| `on_request` | `function(req) -> req, err` | Modify requests before sending (add headers, transform) |
| `health_check` | `function() -> bool` | Custom health check logic |

## Available Globals

Scripts run in a sandboxed Lua 5.1 VM with these available:

### `config` table

Populated from `athyr.yaml` backend entry:

| Key | Source |
|-----|--------|
| `config.name` | `backends[].name` |
| `config.url` | `backends[].url` |
| `config.api_key` | `backends[].api_key` |

### Standard libraries

Only safe Lua standard libraries are loaded: `base`, `table`, `string`, `math`. File I/O, OS access, and dynamic code loading (`load`, `loadfile`, `dofile`) are blocked.

### Helper modules

| Module | Functions | Description |
|--------|-----------|-------------|
| `json` | `json.encode(value)`, `json.decode(string)` | JSON serialization |
| `http` | `http.get(url, headers)`, `http.post(url, body, headers)` | HTTP requests (proxied through Go) |
| `log` | `log.info(msg)`, `log.warn(msg)`, `log.error(msg)` | Structured logging |

## Examples

### Minimal Provider (Ollama)

```lua
-- Helper: Lua treats "" as truthy, so use this for config defaults
local function default(val, fallback)
    if val == nil or val == "" then return fallback end
    return val
end

local provider = {
    name = "ollama",
    protocol = "openai_compat",
    base_url = default(config.url, "http://localhost:11434"),
    completions_endpoint = "/v1/chat/completions",
    models_endpoint = "/api/tags",
    health_endpoint = "/",
    auth_type = "none",
}

function provider.parse_models(response)
    local models = {}
    for _, m in ipairs(response.models or {}) do
        table.insert(models, { id = m.name, name = m.name })
    end
    return models
end

return provider
```

### Provider with Auth and Custom Headers (OpenRouter)

```lua
local function default(val, fallback)
    if val == nil or val == "" then return fallback end
    return val
end

local provider = {
    name = "openrouter",
    protocol = "openai_compat",
    base_url = default(config.url, "https://openrouter.ai/api/v1"),
    completions_endpoint = "/chat/completions",
    models_endpoint = "/models",
    auth_type = "bearer",
    auth_key = config.api_key,
    headers = {
        ["HTTP-Referer"] = "https://athyr.io",
        ["X-Title"] = "Athyr",
    },
}

function provider.parse_models(response)
    local models = {}
    for _, m in ipairs(response.data or {}) do
        table.insert(models, { id = m.id, name = m.name or m.id })
    end
    return models
end

return provider
```

### Provider with Request Hook

```lua
local provider = {
    name = "custom-api",
    protocol = "openai_compat",
    base_url = config.url,
    completions_endpoint = "/v1/chat/completions",
}

function provider.on_request(req)
    req.headers["X-Custom-Auth"] = "token-" .. config.api_key
    req.headers["X-Request-Model"] = req.model
    return req, nil
end

return provider
```

## Script Resolution Order

When Athyr loads a backend with `type: foo`:

1. Check `<data-dir>/providers/foo.lua` (user override)
2. Check built-in embedded scripts (ships with `ollama.lua` and `openrouter.lua`)

User scripts always take precedence. This lets you customize built-in providers or add entirely new ones.

## Troubleshooting

**Provider not loading?** Run `athyr doctor` to check LLM backend health.

**Script errors?** Check Athyr server logs. Lua parse errors and missing required fields are logged at startup.

**Models not listing?** If the provider's model list API uses a non-standard format, add a `parse_models` hook to transform the response into `{ id = "...", name = "..." }` entries.

## Next Steps

- [LLM Gateway](/docs/gateway/) - Gateway routing, failover, and usage
- [Configuration](/docs/configuration/) - Full configuration reference

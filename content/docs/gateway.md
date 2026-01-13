---
title: "LLM Gateway"
description: "Configuring LLM providers and routing"
---

The LLM Gateway routes completion requests to configured backends. Agents call a single API - Athyr handles provider
selection, failover, and retries.

## Why a Gateway?

Without Athyr, each agent needs:

- Provider-specific API code (Ollama vs OpenAI vs Anthropic)
- Retry logic for transient failures
- Fallback handling when a provider is down
- Connection management and health checks

The gateway centralizes this complexity. Agents just call `Complete()` with a model name.

## Supported Providers

| Provider   | Type         | Description                           |
|------------|--------------|---------------------------------------|
| Ollama     | `ollama`     | Local LLM inference                   |
| OpenRouter | `openrouter` | Access to 100+ models via unified API |

Both providers support streaming, tool calling, and all standard completion options.

## Configuration

Configure backends in `athyr.yaml`:

```yaml
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
```

### Backend Options

| Field      | Description                                  |
|------------|----------------------------------------------|
| `name`     | Unique identifier for this backend           |
| `type`     | Provider type: `ollama` or `openrouter`      |
| `url`      | Base URL for the provider API                |
| `api_key`  | API key (supports `${ENV_VAR}` substitution) |
| `priority` | Routing priority (lower = preferred)         |

### Retry Configuration

| Field          | Description                                           |
|----------------|-------------------------------------------------------|
| `max_attempts` | Maximum retry attempts per request (default: 3)       |
| `backoff`      | Backoff strategy: `exponential`, `linear`, or `fixed` |

## Usage

### Basic Completion

```go
resp, err := agent.Complete(ctx, athyr.CompletionRequest{
Model: "llama3",
Messages: []athyr.Message{
{Role: "user", Content: "Explain quantum computing"},
},
})
fmt.Println(resp.Content)
```

### Streaming

```go
err := agent.CompleteStream(ctx, athyr.CompletionRequest{
Model: "llama3",
Messages: messages,
}, func (chunk athyr.StreamChunk) error {
fmt.Print(chunk.Content)
if chunk.Done {
fmt.Printf("\nTokens: %d\n", chunk.Usage.TotalTokens)
}
return nil
})
```

### Completion Options

```go
resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
Model:    "llama3",
Messages: messages,
Config: athyr.CompletionConfig{
Temperature: 0.7,
MaxTokens:   1000,
TopP:        0.9,
Stop:        []string{"\n\n"},
},
})
```

| Option        | Description                                  |
|---------------|----------------------------------------------|
| `Temperature` | Randomness (0.0-1.0, higher = more creative) |
| `MaxTokens`   | Maximum tokens to generate                   |
| `TopP`        | Nucleus sampling threshold                   |
| `Stop`        | Sequences that stop generation               |

### Tool Calling

Define tools the LLM can invoke:

```go
resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
Model: "llama3",
Messages: messages,
Tools: []athyr.Tool{
{
Name:        "get_weather",
Description: "Get current weather for a location",
Parameters:  `{"type":"object","properties":{"location":{"type":"string"}}}`,
},
},
})

// Check if LLM wants to call a tool
if len(resp.ToolCalls) > 0 {
for _, call := range resp.ToolCalls {
fmt.Printf("Tool: %s, Args: %s\n", call.Name, call.Arguments)
}
}
```

### List Available Models

```go
models, _ := agent.Models(ctx)
for _, m := range models {
fmt.Printf("%s (%s)\n", m.Name, m.Backend)
}
```

## Fault Tolerance

### Circuit Breaker

Each backend has a circuit breaker that trips after repeated failures:

- **Closed** - Normal operation, requests pass through
- **Open** - Backend marked unhealthy, requests fail fast
- **Half-Open** - Testing if backend recovered

When a circuit opens, requests automatically route to healthy backends.

### Automatic Failover

If a backend fails:

1. Request retries with exponential backoff
2. After max attempts, circuit breaker records failure
3. Request routes to alternate backend
4. Original backend recovers when circuit closes

## Response Metadata

Completion responses include routing information:

```go
resp, _ := agent.Complete(ctx, req)

fmt.Println(resp.Content)       // Generated text
fmt.Println(resp.Model)         // Model that served the request
fmt.Println(resp.Backend) // Backend name
fmt.Println(resp.Latency) // Request duration
fmt.Println(resp.FinishReason) // "stop", "length", or "tool_calls"
fmt.Println(resp.Usage.TotalTokens)
```

## Next Steps

- [Agents](/docs/agents/) - Using LLM completions in agents
- [State Management](/docs/state/) - Memory sessions for conversations
- [Configuration](/docs/configuration/) - Full configuration reference

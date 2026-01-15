---
title: "Go SDK"
description: "Building agents with the Athyr Go SDK"
---

The Go SDK is the primary client for building agents on the Athyr platform. It provides production-ready features including orchestration patterns, middleware, and resilience out of the box.

## Installation

```bash
go get github.com/athyr-tech/athyr-sdk-go
```

Requires Go 1.21+ and a running [Athyr server](/docs/installation/).

## Quick Start

```go
package main

import (
    "context"
    "github.com/athyr-tech/athyr-sdk-go/pkg/athyr"
)

func main() {
    agent := athyr.MustConnect("localhost:9090",
        athyr.WithAgentCard(athyr.AgentCard{
            Name:        "my-agent",
            Description: "My first Athyr agent",
        }),
    )
    defer agent.Close()

    resp, _ := agent.Complete(context.Background(), athyr.CompletionRequest{
        Model:    "llama3",
        Messages: []athyr.Message{{Role: "user", Content: "Hello!"}},
    })
    println(resp.Content)
}
```

## Features

### Core Agent

- **Connect/Disconnect** — Lifecycle management with automatic reconnection
- **Pub/Sub Messaging** — Subscribe to subjects, publish messages, request/reply
- **LLM Completions** — Blocking and streaming completions via Athyr backends
- **Memory Sessions** — Conversation context with automatic summarization
- **KV Storage** — Key-value buckets for agent state
- **Tool Calling** — LLM function calling support

### Orchestration Patterns

Located in `pkg/orchestration/`:

| Pattern      | Description                              |
|--------------|------------------------------------------|
| **Pipeline** | Sequential agent chain (A → B → C)       |
| **FanOut**   | Parallel execution with aggregation      |
| **Handoff**  | Dynamic routing via triage agent         |
| **GroupChat**| Multi-agent collaborative discussion     |

### Middleware

- `Recover` — Panic recovery
- `Timeout` — Request timeouts
- `Retry` — Automatic retries with backoff
- `RateLimit` — Concurrency limiting
- `Metrics` — Duration/error callbacks
- `Validate` — Input validation
- `LogRequests` — Request/response logging

### Server Pattern

For building agent services that handle requests:

```go
server := athyr.NewServer("localhost:9090",
    athyr.WithAgentName("my-service"),
)

athyr.Handle(server, "echo.request", func(ctx athyr.Context, req EchoRequest) (EchoResponse, error) {
    return EchoResponse{Echo: req.Message}, nil
})

server.Run(context.Background())
```

## Documentation

Full documentation and examples are maintained in the SDK repository:

- **[SDK README](https://github.com/athyr-tech/athyr-sdk-go)** — Complete feature guide
- **[API Reference](https://pkg.go.dev/github.com/athyr-tech/athyr-sdk-go/pkg/athyr)** — GoDoc
- **[Examples](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples)** — Working code samples

### Available Examples

| Example                                                                          | Demonstrates                  |
|----------------------------------------------------------------------------------|-------------------------------|
| [quickstart](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/quickstart) | Basic agent setup             |
| [pipeline](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/pipeline)     | Sequential orchestration      |
| [fanout](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/fanout)         | Parallel execution            |
| [group-chat](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/group-chat) | Multi-agent collaboration     |
| [handoff-router](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/handoff-router) | Dynamic routing via triage |
| [resilience](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/resilience) | Error handling and retries    |
| [tool-calling](https://github.com/athyr-tech/athyr-sdk-go/tree/main/examples/tool-calling) | LLM function calling      |

## Next Steps

- [Agents](/docs/agents/) — Agent concepts and lifecycle
- [LLM Gateway](/docs/gateway/) — LLM provider configuration
- [State Management](/docs/state/) — Memory and KV details
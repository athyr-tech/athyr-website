---
title: "Go SDK"
description: "Building agents with the Athyr Go SDK"
---

The Go SDK provides a client for building agents on the Athyr platform.

## Installation

```bash
go get github.com/athyr-tech/athyr-sdk-go
```

Requires Go 1.21+.

**API Reference
**: [pkg.go.dev/github.com/athyr-tech/athyr-sdk-go](https://pkg.go.dev/github.com/athyr-tech/athyr-sdk-go/pkg/athyr)
¬

## Quick Start

```go
package main

import (
	"context"
	"fmt"

	"github.com/athyr-tech/athyr-sdk-go/pkg/athyr"
)

func main() {
	ctx := context.Background()

	agent, _ := athyr.NewAgent("localhost:9090",
		athyr.WithAgentCard(athyr.AgentCard{Name: "my-agent"}),
		athyr.WithInsecure(),
	)
	agent.Connect(ctx)
	defer agent.Close()

	resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
		Model:    "llama3",
		Messages: []athyr.Message{{Role: "user", Content: "Hello!"}},
	})
	fmt.Println(resp.Content)
}
```

## Common Patterns

### Streaming Responses

```go
agent.CompleteStream(ctx, athyr.CompletionRequest{
Model:    "llama3",
Messages: messages,
}, func (chunk athyr.StreamChunk) error {
fmt.Print(chunk.Content)
return nil
})
```

### Conversation Memory

```go
// Create session with system prompt
session, _ := agent.CreateSession(ctx,
athyr.DefaultSessionProfile(),
"You are a helpful assistant.",
)

// Completions automatically include history
resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
Model:         "llama3",
Messages:      []athyr.Message{{Role: "user", Content: "Hi"}},
SessionID:     session.ID,
IncludeMemory: true,
})
```

### Request/Reply Services

```go
type AddRequest struct {
A, B int `json:"a,b"`
}

type AddResponse struct {
Result int `json:"result"`
}

func main() {
ctx := context.Background()

athyr.Run(ctx, "localhost:9090", "math.add",
func (ctx athyr.Context, req AddRequest) (AddResponse, error) {
return AddResponse{Result: req.A + req.B}, nil
},
)
}
```

### Key-Value Storage

```go
bucket := agent.KV("user-data")

// Store
bucket.Put(ctx, "user:123", []byte(`{"name":"Alice"}`))

// Retrieve
entry, _ := bucket.Get(ctx, "user:123")
fmt.Println(string(entry.Value))
```

### Pub/Sub Messaging

```go
// Subscribe
agent.Subscribe(ctx, "events.>", func (msg athyr.SubscribeMessage) {
fmt.Printf("Got: %s\n", string(msg.Data))
})

// Publish
agent.Publish(ctx, "events.user.signup", []byte(`{"id":"123"}`))

// Request/Reply
response, _ := agent.Request(ctx, "math.add", []byte(`{"a":1,"b":2}`))
```

### Auto-Reconnection

```go
agent, _ := athyr.NewAgent("athyr.example.com:9090",
athyr.WithAutoReconnect(10, time.Second),
athyr.WithConnectionCallback(func (state athyr.ConnectionState, err error) {
log.Printf("Connection state: %s", state)
}),
)
```

### Error Handling

```go
entry, err := bucket.Get(ctx, "key")
if athyr.IsNotFound(err) {
// Handle missing key
}

resp, err := agent.Complete(ctx, req)
if athyr.IsUnavailable(err) {
// Retry later
}
```

## Configuration Options

| Option                                | Description                      |
|---------------------------------------|----------------------------------|
| `WithAgentCard(card)`                 | Set agent identity               |
| `WithInsecure()`                      | Disable TLS (development)        |
| `WithTLS(certFile)`                   | Use CA certificate               |
| `WithSystemTLS()`                     | Use system certificates          |
| `WithAutoReconnect(retries, backoff)` | Enable auto-reconnection         |
| `WithLogger(logger)`                  | Enable logging (slog compatible) |
| `WithHeartbeatInterval(d)`            | Heartbeat frequency              |
| `WithRequestTimeout(d)`               | Request timeout                  |

## Next Steps

- [Agents](/docs/agents/) - Agent concepts and lifecycle
- [LLM Gateway](/docs/gateway/) - LLM provider configuration
- [State Management](/docs/state/) - Memory and KV details
---
title: "Agents"
description: "Understanding AI agents in Athyr"
---

Agents are the core building blocks of Athyr. This guide explains what agents are, how they work, and what they can do.

## What is an Agent?

In Athyr, an agent is an **independent service** that connects to the platform to access AI capabilities. Unlike
traditional frameworks where agents are functions within a single process, Athyr agents are standalone processes that:

- Run anywhere (local machine, container, cloud)
- Connect to Athyr over gRPC
- Access LLM, memory, and storage through the platform
- Communicate with other agents via messaging

This design enables independent scaling, fault isolation, and language flexibility.

## Agent Identity

Every agent has an **AgentCard** that defines its identity:

```go
athyr.AgentCard{
Name:         "data-analyst",
Description:  "Analyzes datasets and generates insights",
Version:      "1.0.0",
Capabilities: []string{"analysis", "visualization"},
Metadata:     map[string]string{"team": "analytics"},
}

```

| Field          | Purpose                               |
|----------------|---------------------------------------|
| `Name`         | Display name for the agent            |
| `Description`  | What the agent does                   |
| `Version`      | Agent software version                |
| `Capabilities` | Advertised capabilities for discovery |
| `Metadata`     | Custom key-value pairs                |

When an agent connects, Athyr assigns it a unique **Agent ID** (e.g., `data-analyst-x7k2m`) for identification.

## Lifecycle

### Connect

Agents must connect to Athyr before using any features:

```go
agent, _ := athyr.NewAgent("localhost:9090",
athyr.WithAgentCard(card),
)

agent.Connect(ctx) // Register with Athyr
defer agent.Close() // Clean disconnect
```

### Heartbeat

Connected agents send periodic heartbeats. If Athyr doesn't receive heartbeats, it marks the agent as disconnected.
Configure the interval:

```go
athyr.WithHeartbeatInterval(30 * time.Second)
```

### Reconnection

The SDK handles reconnection automatically. If the connection drops, it will retry with exponential backoff and restore
subscriptions.

## Capabilities

Agents access four main capabilities through Athyr:

### LLM Completions

Request completions from configured LLM backends:

```go
resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
Model:    "llama3",
Messages: []athyr.Message{{Role: "user", Content: "Hello!"}},
})
fmt.Println(resp.Content)
```

Or stream responses:

```go
agent.CompleteStream(ctx, req, func (chunk athyr.StreamChunk) error {
fmt.Print(chunk.Content)
return nil
})
```

### Pub/Sub Messaging

Agents communicate via publish/subscribe messaging:

```go
// Subscribe to a subject pattern
agent.Subscribe(ctx, "tasks.>", func (msg athyr.SubscribeMessage) {
fmt.Printf("Received: %s\n", string(msg.Data))
})

// Publish a message
agent.Publish(ctx, "tasks.new", []byte(`{"task": "analyze"}`))

// Request/reply
response, _ := agent.Request(ctx, "math.add", []byte(`{"a": 1, "b": 2}`))
```

### Memory Sessions

Maintain conversation context across multiple LLM calls:

```go
// Create a session with system prompt
session, _ := agent.CreateSession(ctx, athyr.DefaultSessionProfile(),
"You are a helpful assistant.")

// Include memory in completions
resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
Model:         "llama3",
Messages:      []athyr.Message{{Role: "user", Content: "Hi"}},
SessionID:     session.ID,
IncludeMemory: true, // Athyr injects conversation history
})

// Add persistent hints
agent.AddHint(ctx, session.ID, "User prefers concise answers")
```

### KV Storage

Persist agent state in key-value buckets:

```go
prefs := agent.KV("user-preferences")

// Store
prefs.Put(ctx, "theme", []byte("dark"))

// Retrieve
entry, _ := prefs.Get(ctx, "theme")
fmt.Println(string(entry.Value)) // "dark"

// Delete
prefs.Delete(ctx, "theme")
```

## Multi-Agent Patterns

Athyr supports orchestration patterns for multi-agent systems:

- **Pipeline** - Sequential processing (A → B → C)
- **FanOut** - Parallel execution with aggregation
- **Handoff** - Dynamic routing via triage agent
- **GroupChat** - Collaborative multi-agent discussion

See the [Go SDK](/docs/sdk-go/) for pattern implementations.

## Next Steps

- [LLM Gateway](/docs/gateway/) - LLM backend configuration
- [State Management](/docs/state/) - Memory and storage details
- [Go SDK](/docs/sdk-go/) - Full API reference
---
title: "Quick Start"
description: "Create your first AI agent with Athyr"
---

Build a minimal AI agent that connects to Athyr and uses LLM completions.

## Prerequisites

- [Athyr installed](/docs/installation/)
- Go 1.21+
- [Ollama](https://ollama.ai) running with a model (`ollama pull llama3`)

## 1. Start Athyr

```bash
athyr serve
```

## 2. Create the Agent

```bash
mkdir my-agent && cd my-agent
go mod init my-agent
go get github.com/athyr-tech/athyr-sdk-go
```

Create `main.go`:

```go
package main

import (
	"context"
	"fmt"

	"github.com/athyr-tech/athyr-sdk-go/pkg/athyr"
)

func main() {
	ctx := context.Background()

	// 1. Create agent
	agent, _ := athyr.NewAgent("localhost:9090",
		athyr.WithAgentCard(athyr.AgentCard{
			Name:        "my-agent",
			Description: "My first AI agent",
		}),
	)

	// 2. Connect and register with Athyr
	agent.Connect(ctx)
	defer agent.Close()

	fmt.Println("Agent registered:", agent.AgentID())

	// 3. Call LLM through Athyr
	resp, _ := agent.Complete(ctx, athyr.CompletionRequest{
		Model: "llama3",
		Messages: []athyr.Message{
			{Role: "user", Content: "Hello! What can you do?"},
		},
	})

	fmt.Println("Response:", resp.Content)
}
```

## 3. Run

```bash
go run main.go
```

```
Agent registered: my-agent-x7k2m
Response: Hello! I'm an AI assistant. I can help answer questions,
explain concepts, write code, and much more. How can I help you?
```

## What's Happening

1. **Create** - `NewAgent()` creates the agent with an identity card
2. **Register** - `Connect()` registers the agent with Athyr's registry
3. **LLM Call** - `Complete()` sends a request through Athyr's LLM gateway

The agent doesn't know about Ollama - Athyr handles LLM routing and provider management.

## Next Steps

- [Agents](/docs/agents/) - Agent lifecycle and capabilities
- [LLM Gateway](/docs/gateway/) - LLM providers and routing
- [Go SDK](/docs/sdk-go/) - Full API reference
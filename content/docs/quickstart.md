---
title: "Quick Start"
description: "Create your first AI agent with Athyr"
---

Build a minimal AI agent that connects to Athyr and uses LLM completions.

> **Prefer no code?** You can define agents in YAML and run them with [Athyr Agent](/docs/athyr-agent/) — no programming required.

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

## Alternative: YAML Agent (No Code)

If you prefer not to write code, you can define the same agent in YAML using [Athyr Agent](/docs/athyr-agent/):

```yaml
# agent.yaml
agent:
  name: my-agent
  description: My first AI agent
  model: llama3
  instructions: |
    You are a helpful assistant. Respond concisely.
  topics:
    subscribe: [requests.new]
    publish: [requests.done]
```

```bash
brew install athyr-tech/tap/athyr-agent
athyr-agent run agent.yaml --server localhost:9090
```

## Next Steps

- [Athyr Agent](/docs/athyr-agent/) - Define agents in YAML with no code
- [Agents](/docs/agents/) - Agent lifecycle and capabilities
- [LLM Gateway](/docs/gateway/) - LLM providers and routing
- [Go SDK](/docs/sdk-go/) - Full API reference
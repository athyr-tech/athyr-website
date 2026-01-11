---
title: "Building Your First Multi-Agent System"
date: 2026-01-10
description: "A step-by-step tutorial on creating a multi-agent system using Athyr and the Go SDK."
tags:
  - Tutorial
  - Go
---

In this tutorial, we'll build a simple multi-agent system where agents collaborate to process and analyze data. You'll learn the fundamentals of agent communication, state management, and orchestration with Athyr.

## Prerequisites

Before starting, make sure you have:

- Athyr installed ([Installation Guide](/docs/installation/))
- Go 1.21 or later
- Basic understanding of Go

## Project Setup

Create a new directory for your project:

```bash
mkdir my-agent-system
cd my-agent-system
go mod init my-agent-system
go get github.com/athyr-tech/athyr-sdk-go
```

## Creating Your First Agent

Let's start with a simple "echo" agent that receives messages and responds:

```go
package main

import (
    "context"
    "log"

    athyr "github.com/athyr-tech/athyr-sdk-go"
)

func main() {
    agent, err := athyr.NewAgent(athyr.Config{
        Name: "echo-agent",
        Host: "localhost:9090",
    })
    if err != nil {
        log.Fatal(err)
    }

    agent.Handle("echo", func(ctx context.Context, msg athyr.Message) (any, error) {
        return map[string]string{
            "echoed": msg.Payload.(string),
        }, nil
    })

    log.Println("Echo agent starting...")
    agent.Run()
}
```

## Running the System

1. Start Athyr server:

```bash
athyr serve
```

2. In another terminal, run your agent:

```bash
go run main.go
```

3. Test the agent using the Athyr CLI:

```bash
athyr call echo-agent echo "Hello, World!"
```

## Adding More Agents

The real power of Athyr comes from multiple agents working together. In the next tutorial, we'll add:

- A **processor agent** that transforms data
- A **storage agent** that persists results
- An **orchestrator agent** that coordinates the workflow

## What's Next

- Learn about [Agent Registry](/docs/registry/) for service discovery
- Explore [State Management](/docs/state/) for persistent agent memory
- Check out the [Go SDK Reference](/docs/sdk-go/) for all available features

---
title: "Introduction"
description: "Learn how to deploy and manage distributed AI agents with the Athyr runtime."
menu:
  docs:
    parent: "Getting Started"
    weight: 1
---

Athyr is a lightweight runtime for deploying AI agents as distributed microservices. It provides the infrastructure layer that handles agent orchestration, communication, and state management so you can focus on building agent logic.

## Why Athyr?

Building multi-agent systems traditionally requires solving complex infrastructure problems: service discovery, message routing, state persistence, and LLM provider management. Athyr handles all of this in a single binary.

## Key Features

**Single Binary Deployment** - No external dependencies. Deploy anywhere with zero configuration.

**Language Agnostic** - Write agents in Go, Python, TypeScript, or any language with gRPC support.

**Built-in LLM Gateway** - Multi-provider routing with automatic failover and circuit breakers.

**Agent Registry** - Automatic service discovery. Agents find each other seamlessly.

## Next Steps

Ready to get started? Head to the [Installation](/docs/installation/) guide or jump straight into the [Quick Start](/docs/quickstart/) tutorial.

---
title: "Introduction"
description: "A runtime for AI agents as distributed microservices. Single binary. Language agnostic. Agents stay stateless."
menu:
  docs:
    parent: "Getting Started"
    weight: 1
---

Athyr is a runtime for AI agents as distributed microservices.

Most AI agent frameworks run multiple agents as objects in the same process. That works for demos. In production, when
agents need to run on different machines, scale independently, and communicate across networks, those frameworks break
down.

Athyr treats agents as **network services**, not library objects. The platform handles the infrastructure—memory,
messaging, LLM routing, state—so agents contain only business logic.

## The Problem

Multi-agent systems built as same-process Python objects face hard limits:

| In-Process Assumption  | Production Reality              |
|------------------------|---------------------------------|
| Shared memory          | Network serialization           |
| Instant function calls | Network latency (ms to seconds) |
| Single failure domain  | Partial failures, timeouts      |
| Exceptions propagate   | Must handle disconnects         |

When agents become independent services across machines, you need infrastructure designed for distribution from the
start.

## What Athyr Provides

**Deployment & Operations:**

- **Single binary** — No Python environment, no external dependencies. Deploy anywhere.
- **Built-in resilience** — Circuit breakers per LLM backend, automatic retry with backoff, backend failover.
- **Native observability** — Prometheus metrics, correlation IDs across requests, audit logging.
- **Air-gap deployable** — Zero external connectivity requirements.

**Agent Development:**

- **SDK orchestration patterns** — Pipeline (sequential), FanOut (parallel), HandoffRouter (triage-based routing),
  GroupChat (multi-agent conversation).
- **Platform-managed memory** — Automatic summarization at token thresholds, rolling windows, memory hints for important
  context.
- **LLM Gateway** — Multi-backend support, streaming with disconnect recovery, tool/function calling pass-through.

## Key Features

**Language Agnostic** — Write agents in Go, Python, or any language with gRPC/HTTP support. The platform speaks
protocols, not libraries.

**Agent Discovery** — Capability-based registry. Agents declare what they can do; the platform routes work to them.

**Durable Streaming** — LLM responses persist with sequence numbers. Clients reconnect and resume from where they left
off.

**Stateless Agents** — Platform manages sessions, state, and memory. Agents connect, process, respond.

## When Athyr Fits

- Agents need to run on different machines or regions
- Your team uses multiple languages (Go backend, Python ML, TypeScript frontend)
- Production requires fault isolation between agents
- On-prem or edge deployment without cloud dependencies
- You want infrastructure, not a framework embedded in your code

## Next Steps

Ready to get started? Head to the [Installation](/docs/installation/) guide or jump straight into
the [Quick Start](/docs/quickstart/) tutorial.

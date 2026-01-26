---
title: "Python SDK"
description: "Building agents with the Athyr Python SDK"
---

The Python SDK is a fully async client for building agents on the Athyr platform. It provides the same orchestration patterns, middleware, and resilience features as the Go SDK, designed for Python's async/await paradigm.

## Installation

```bash
pip install git+https://github.com/athyr-tech/athyr-sdk-python.git
```

Requires Python 3.10+ and a running [Athyr server](/docs/installation/).

## Quick Start

```python
import asyncio
from athyr import AthyrAgent, AgentCard, CompletionRequest, Message

async def main():
    async with AthyrAgent(
        "localhost:9090",
        agent_card=AgentCard(name="my-agent", description="My first Athyr agent"),
    ) as agent:
        resp = await agent.complete(CompletionRequest(
            model="llama3",
            messages=[Message(role="user", content="Hello!")]
        ))
        print(resp.content)

asyncio.run(main())
```

## Features

### Core Agent

- **Connect/Disconnect** — Lifecycle management with automatic reconnection
- **Pub/Sub Messaging** — Subscribe to subjects, publish messages, request/reply
- **LLM Completions** — Blocking and streaming completions via Athyr backends
- **Memory Sessions** — Conversation context with automatic summarization
- **KV Storage** — Key-value buckets for agent state
- **Tool Calling** — Decorator-based function calling support

### Orchestration Patterns

Located in `athyr.orchestration`:

| Pattern      | Description                              |
|--------------|------------------------------------------|
| **Pipeline** | Sequential agent chain (A → B → C)       |
| **FanOut**   | Parallel execution with aggregation      |
| **Handoff**  | Dynamic routing via triage agent         |
| **GroupChat**| Multi-agent collaborative discussion     |

### Middleware

- `recover` — Exception recovery
- `timeout` — Request timeouts
- `retry` — Automatic retries with backoff
- `log_requests` — Request/response logging
- Custom middleware via `@middleware` decorator

### Tool Calling

Define tools with the `@tool` decorator:

```python
from athyr import tool, ToolRegistry, run_tool_loop

@tool(description="Get weather for a city")
def get_weather(city: str, unit: str = "celsius") -> str:
    return f"Weather in {city}: sunny"

registry = ToolRegistry()
registry.register(get_weather)

response = await run_tool_loop(agent, request, registry)
```

## Documentation

Full documentation and examples are maintained in the SDK repository:

- **[SDK README](https://github.com/athyr-tech/athyr-sdk-python)** — Complete feature guide
- **[Examples](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples)** — Working code samples

### Available Examples

| Example                                                                                  | Demonstrates                  |
|------------------------------------------------------------------------------------------|-------------------------------|
| [quickstart](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/quickstart.py) | Basic agent setup             |
| [streaming](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/streaming.py)   | Streaming LLM responses       |
| [messaging](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/messaging.py)   | Pub/sub and request/reply     |
| [tool_calling](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/tool_calling.py) | LLM function calling      |
| [chat_agent](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/chat_agent.py) | Memory sessions               |
| [pipeline](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/pipeline.py)     | Sequential orchestration      |
| [fanout](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/fanout.py)         | Parallel execution            |
| [groupchat](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/groupchat.py)   | Multi-agent collaboration     |
| [handoff](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/handoff.py)       | Dynamic routing via triage    |
| [resilient_agent](https://github.com/athyr-tech/athyr-sdk-python/tree/main/examples/resilient_agent.py) | Error handling and retries |

## Next Steps

- [Agents](/docs/agents/) — Agent concepts and lifecycle
- [LLM Gateway](/docs/gateway/) — LLM provider configuration
- [State Management](/docs/state/) — Memory and KV details

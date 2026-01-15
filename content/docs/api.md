---
title: "API Reference"
description: "Athyr gRPC and HTTP API reference"
---

Athyr exposes a gRPC API with HTTP/JSON mappings. SDKs wrap this API for convenience, but you can call it directly for
unsupported languages.

## Connection

- **gRPC**: Connect to port `9090` (default)
- **HTTP**: Connect to port `8080` (default)

## Agent Lifecycle

### Connect

Register an agent with the platform.

**gRPC**: `Athyr.Connect`
**HTTP**: `POST /v1/connect`

```json
// Request
{
  "agent_card": {
    "name": "my-agent",
    "description": "Agent description",
    "version": "1.0.0",
    "capabilities": [
      "analysis",
      "chat"
    ],
    "metadata": {
      "team": "data"
    }
  }
}

// Response
{
  "agent_id": "my-agent-x7k2m",
  "connected_at": "2026-01-15T10:30:00Z"
}
```

### Heartbeat

Signal the agent is still alive.

**gRPC**: `Athyr.Heartbeat`
**HTTP**: `POST /v1/heartbeat`

```json
// Request
{
  "agent_id": "my-agent-x7k2m"
}

// Response
{
  "ok": true,
  "server_time": "2026-01-15T10:30:30Z"
}
```

### Disconnect

Gracefully remove an agent.

**gRPC**: `Athyr.Disconnect`
**HTTP**: `POST /v1/disconnect`

```json
// Request
{
  "agent_id": "my-agent-x7k2m"
}

// Response
{
  "ok": true
}
```

## Messaging

### Publish

Send a message to a subject.

**gRPC**: `Athyr.Publish`
**HTTP**: `POST /v1/publish`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "subject": "events.user.signup",
  "data": "eyJ1c2VyX2lkIjogIjEyMyJ9"
  // base64 encoded
}

// Response
{
  "ok": true
}
```

### Subscribe

Open a stream to receive messages. gRPC streaming only.

**gRPC**: `Athyr.Subscribe` (server streaming)

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "subject": "events.>",
  "queue_group": "workers"
  // optional, for load balancing
}

// Stream messages
{
  "subject": "events.user.signup",
  "data": "...",
  "reply": ""
}
```

### Request

Send a message and wait for a reply.

**gRPC**: `Athyr.Request`
**HTTP**: `POST /v1/request`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "subject": "math.add",
  "data": "eyJhIjogMSwgImIiOiAyfQ==",
  "timeout_ms": 5000
}

// Response
{
  "data": "eyJyZXN1bHQiOiAzfQ=="
}
```

## LLM

### Complete

Perform a blocking LLM completion.

**gRPC**: `Athyr.Complete`
**HTTP**: `POST /v1/complete`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "model": "llama3",
  "messages": [
    {
      "role": "system",
      "content": "You are helpful."
    },
    {
      "role": "user",
      "content": "Hello!"
    }
  ],
  "config": {
    "temperature": 0.7,
    "max_tokens": 1000,
    "top_p": 0.9,
    "stop": [
      "\n\n"
    ]
  },
  "session_id": "sess-abc123",
  "include_memory": true,
  "tools": [
    {
      "name": "get_weather",
      "description": "Get weather for a location",
      "parameters": "{\"type\":\"object\",\"properties\":{\"location\":{\"type\":\"string\"}}}"
    }
  ],
  "tool_choice": "auto"
}

// Response
{
  "content": "Hello! How can I help you today?",
  "model": "llama3",
  "backend": "local",
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 8,
    "total_tokens": 23
  },
  "finish_reason": "stop",
  "latency_ms": 245,
  "tool_calls": []
}
```

### CompleteStream

Perform a streaming LLM completion. gRPC streaming only.

**gRPC**: `Athyr.CompleteStream` (server streaming)

```json
// Request (same as Complete)

// Stream chunks
{
  "content": "Hello",
  "done": false,
  "sequence": 1
}
{
  "content": "!",
  "done": false,
  "sequence": 2
}
{
  "content": "",
  "done": true,
  "usage": {
    ...
  },
  "model": "llama3",
  "sequence": 3
}
```

### ListModels

Get available LLM models.

**gRPC**: `Athyr.ListModels`
**HTTP**: `GET /v1/models`

```json
// Response
{
  "models": [
    {
      "id": "llama3",
      "name": "Llama 3",
      "backend": "local",
      "available": true
    },
    {
      "id": "gpt-4",
      "name": "GPT-4",
      "backend": "cloud",
      "available": true
    }
  ]
}
```

## Memory Sessions

### CreateSession

Create a conversation session for memory.

**gRPC**: `Athyr.CreateSession`
**HTTP**: `POST /v1/sessions`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "profile": {
    "type": "rolling_window",
    "max_tokens": 4096,
    "summarization_threshold": 3000
  },
  "system_prompt": "You are a helpful assistant."
}

// Response
{
  "id": "sess-abc123",
  "agent_id": "my-agent-x7k2m",
  "system_prompt": "You are a helpful assistant.",
  "messages": [],
  "summary": "",
  "hints": [],
  "profile": {
    ...
  },
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-01-15T10:30:00Z"
}
```

### GetSession

Retrieve an existing session.

**gRPC**: `Athyr.GetSession`
**HTTP**: `GET /v1/sessions/{session_id}`

### DeleteSession

Remove a session.

**gRPC**: `Athyr.DeleteSession`
**HTTP**: `DELETE /v1/sessions/{session_id}`

### AddHint

Add a persistent hint to a session.

**gRPC**: `Athyr.AddHint`
**HTTP**: `POST /v1/sessions/{session_id}/hints`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "session_id": "sess-abc123",
  "hint": "User prefers Python over JavaScript"
}

// Response
{
  "ok": true
}
```

## KV Storage

### KVGet

Retrieve a value from a bucket.

**gRPC**: `Athyr.KVGet`
**HTTP**: `GET /v1/kv/{bucket}/{key}`

```json
// Response
{
  "value": "ZGFyaw==",
  // base64
  "revision": 42
}
```

### KVPut

Store a value in a bucket.

**gRPC**: `Athyr.KVPut`
**HTTP**: `PUT /v1/kv/{bucket}/{key}`

```json
// Request
{
  "agent_id": "my-agent-x7k2m",
  "bucket": "user-prefs",
  "key": "user:123:theme",
  "value": "ZGFyaw=="
}

// Response
{
  "revision": 43
}
```

### KVDelete

Remove a key from a bucket.

**gRPC**: `Athyr.KVDelete`
**HTTP**: `DELETE /v1/kv/{bucket}/{key}`

### KVList

List keys in a bucket.

**gRPC**: `Athyr.KVList`
**HTTP**: `GET /v1/kv/{bucket}?prefix=user:123:`

```json
// Response
{
  "keys": [
    "user:123:theme",
    "user:123:lang"
  ]
}
```

## Error Codes

| gRPC Code           | HTTP Status | Description                     |
|---------------------|-------------|---------------------------------|
| `NOT_FOUND`         | 404         | Resource not found              |
| `INVALID_ARGUMENT`  | 400         | Invalid request                 |
| `UNAVAILABLE`       | 503         | Service temporarily unavailable |
| `DEADLINE_EXCEEDED` | 504         | Request timeout                 |
| `UNAUTHENTICATED`   | 401         | Missing authentication          |
| `PERMISSION_DENIED` | 403         | Insufficient permissions        |

## Next Steps

- [Go SDK](/docs/sdk-go/) - Idiomatic Go wrapper
- [Configuration](/docs/configuration/) - Server configuration
- [LLM Gateway](/docs/gateway/) - LLM provider setup
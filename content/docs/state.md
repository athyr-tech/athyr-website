---
title: "State Management"
description: "Memory sessions and key-value storage for agents"
---

Agents in Athyr are stateless - they don't persist data themselves. Instead, Athyr provides two state management
primitives:

- **Memory Sessions** - Conversation context for multi-turn LLM interactions
- **KV Storage** - General-purpose key-value persistence

## Memory Sessions

Memory sessions maintain conversation history across multiple LLM calls. When enabled, Athyr automatically:

1. Injects previous context into LLM requests
2. Stores new messages from both user and assistant
3. Manages context size with rolling windows
4. Summarizes old messages when needed

### Creating a Session

```go
session, err := agent.CreateSession(ctx, athyr.DefaultSessionProfile(),
"You are a helpful coding assistant.")

fmt.Println(session.ID) // Use this ID for subsequent calls
```

The system prompt defines the agent's personality and is always included at the start of context.

### Using Memory in Completions

Enable memory injection by setting `SessionID` and `IncludeMemory`:

```go
resp, err := agent.Complete(ctx, athyr.CompletionRequest{
Model:         "llama3",
Messages:      []athyr.Message{{Role: "user", Content: "What's 2+2?"}},
SessionID:     session.ID,
IncludeMemory: true,
})

// Next call automatically includes previous exchange
resp, err = agent.Complete(ctx, athyr.CompletionRequest{
Model:         "llama3",
Messages:      []athyr.Message{{Role: "user", Content: "Multiply that by 3"}},
SessionID:     session.ID,
IncludeMemory: true,
})
// LLM receives: system prompt + "What's 2+2?" + "4" + "Multiply that by 3"
```

### Session Profiles

Profiles control memory behavior:

```go
profile := athyr.SessionProfile{
Type:                   "rolling_window",
MaxTokens:              4096,
SummarizationThreshold: 3000,
}

session, _ := agent.CreateSession(ctx, profile, systemPrompt)
```

| Field                    | Description                                  |
|--------------------------|----------------------------------------------|
| `Type`                   | Memory strategy (currently `rolling_window`) |
| `MaxTokens`              | Maximum tokens to include in context         |
| `SummarizationThreshold` | Token count that triggers summarization      |

Use `athyr.DefaultSessionProfile()` for sensible defaults (4096 max tokens, 3000 threshold).

### Rolling Window

When conversation exceeds `MaxTokens`, the oldest messages are dropped to stay within limits. This keeps context fresh
and relevant.

```
[System Prompt] [Summary] [Hints] [Recent Messages...]
                                  ↑ oldest dropped first
```

### Automatic Summarization

When messages exceed `SummarizationThreshold` and no summary exists yet, Athyr can compress older messages into a
summary. The summary is injected as context, preserving key information while saving tokens.

```
Before: [Msg1] [Msg2] [Msg3] [Msg4] [Msg5] [Msg6]
After:  [Summary of 1-3] [Msg4] [Msg5] [Msg6]
```

### Hints

Hints are persistent pieces of context that survive summarization. Use them for important information the LLM should
always remember:

```go
agent.AddHint(ctx, session.ID, "User prefers Python over JavaScript")
agent.AddHint(ctx, session.ID, "Project uses PostgreSQL database")
```

Hints are injected after the system prompt:

```
[System Prompt]
[Important context]
- User prefers Python over JavaScript
- Project uses PostgreSQL database
[Summary]
[Recent Messages...]
```

### Session Management

```go
// Retrieve session details
session, err := agent.GetSession(ctx, sessionID)
fmt.Println(session.Messages)  // View stored messages
fmt.Println(session.Summary)   // View compressed history
fmt.Println(session.Hints) // View hints

// Delete when done
agent.DeleteSession(ctx, sessionID)
```

### Context Injection Order

When `IncludeMemory: true`, context is prepended to your messages:

1. **System Prompt** - Agent personality/instructions
2. **Summary** - Compressed older conversation (if exists)
3. **Hints** - Persistent important context
4. **Rolling Window** - Recent messages up to MaxTokens
5. **Your Messages** - The new message(s) you're sending

## KV Storage

For non-conversation state, use key-value storage. Data is organized into buckets:

```go
// Get a bucket handle
prefs := agent.KV("user-preferences")
config := agent.KV("agent-config")
cache := agent.KV("response-cache")
```

### Basic Operations

```go
bucket := agent.KV("my-data")

// Store a value
revision, err := bucket.Put(ctx, "user:123:theme", []byte("dark"))

// Retrieve a value
entry, err := bucket.Get(ctx, "user:123:theme")
fmt.Println(string(entry.Value)) // "dark"
fmt.Println(entry.Revision) // Version number

// Delete a value
err = bucket.Delete(ctx, "user:123:theme")
```

### Listing Keys

```go
// List all keys with a prefix
keys, err := bucket.List(ctx, "user:123:")
// Returns: ["user:123:theme", "user:123:lang", "user:123:timezone"]

// List all keys in bucket
keys, err := bucket.List(ctx, "")
```

### Storing Structured Data

KV stores raw bytes. Serialize structured data as JSON:

```go
type UserPrefs struct {
Theme    string `json:"theme"`
Language string `json:"language"`
}

// Store
prefs := UserPrefs{Theme: "dark", Language: "en"}
data, _ := json.Marshal(prefs)
bucket.Put(ctx, "user:123", data)

// Retrieve
entry, _ := bucket.Get(ctx, "user:123")
var loaded UserPrefs
json.Unmarshal(entry.Value, &loaded)
```

### Revisions

Each Put returns a revision number. Use revisions for optimistic concurrency:

```go
entry, _ := bucket.Get(ctx, "counter")
count, _ := strconv.Atoi(string(entry.Value))

// Increment
newCount := count + 1
bucket.Put(ctx, "counter", []byte(strconv.Itoa(newCount)))
```

## When to Use What

| Use Case                 | Solution        |
|--------------------------|-----------------|
| Multi-turn conversations | Memory Sessions |
| Agent configuration      | KV Storage      |
| Caching responses        | KV Storage      |
| User preferences         | KV Storage      |
| Conversation history     | Memory Sessions |
| Temporary state          | KV Storage      |

## Next Steps

- [Agents](/docs/agents/) - Memory and KV in agent capabilities
- [LLM Gateway](/docs/gateway/) - How completions work
- [Configuration](/docs/configuration/) - Server configuration options
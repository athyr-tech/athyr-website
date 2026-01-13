---
title: "CLI Commands"
description: "Athyr command-line interface reference"
---

Athyr provides a command-line interface for managing the platform.

## Global Options

These options work with any command:

```bash
athyr [command] --config /path/to/athyr.yaml
athyr --version
athyr --help
```

| Option | Description |
|--------|-------------|
| `--config` | Path to configuration file (default: `./athyr.yaml`) |
| `--version` | Display version information |
| `--help` | Display help for any command |

## Commands

### athyr serve

Start the Athyr server.

```bash
athyr serve
athyr serve --data-dir /var/lib/athyr
athyr serve --config /etc/athyr/athyr.yaml
```

**Options:**

| Option | Description |
|--------|-------------|
| `--data-dir` | Data directory (overrides config file) |

**Output:**

```
    _   _   _
   /_\ | |_| |_  _  _ _ _
  / _ \|  _| ' \| || | '_|
 /_/ \_\\__|_||_|\_, |_|
                 |__/

Provider  embedded-nats
Data      ./data
LLM backends  2
    - local
    - cloud

Press Ctrl+C to stop
```

The server runs in the foreground. Use `Ctrl+C` to stop gracefully.

### athyr status

Check if the server is healthy.

```bash
athyr status
```

**Output (healthy):**

```
Server status: UP
  Provider: embedded-nats
  Data: ./data
  Storage: OK
  Messaging: OK
```

**Output (down):**

```
Server status: DOWN
  Cannot start: failed to connect to data store
```

### athyr agents

Manage registered agents.

#### athyr agents list

Display all connected agents.

```bash
athyr agents list
```

**Output:**

```
ID        NAME            STATUS      SKILLS  LAST SEEN
8a3b2c1d  weather-agent   connected   2       3s ago
f4e5d6c7  triage-agent    connected   1       1s ago
a1b2c3d4  calculator      connected   3       5s ago

Total: 3 agent(s)
```

| Column | Description |
|--------|-------------|
| ID | First 8 characters of agent's unique ID |
| NAME | Agent's display name from AgentCard |
| STATUS | Connection status (`connected`/`disconnected`) |
| SKILLS | Number of registered capabilities |
| LAST SEEN | Time since last heartbeat |

## Configuration File

Athyr looks for configuration in this order:

1. Path specified by `--config` flag
2. `./athyr.yaml` in current directory
3. `/etc/athyr/athyr.yaml`

If no configuration file is found, Athyr uses defaults.

See [Configuration](/docs/configuration/) for full configuration options.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |

## Next Steps

- [Configuration](/docs/configuration/) - Configuration file reference
- [Quick Start](/docs/quickstart/) - Get started with Athyr
- [Installation](/docs/installation/) - Installation options
---
title: "Installation"
description: "How to install Athyr on your system"
---

Athyr is distributed as a single binary with no external dependencies. Choose your preferred installation method below.

## Quick Install (Recommended)

The fastest way to install Athyr is using our install script:

```bash
curl -sSL https://athyr.tech/install.sh | sh
```

This will automatically detect your operating system and architecture, download the appropriate binary, and install it to `/usr/local/bin`.

## Manual Installation

### macOS

Using Homebrew:

```bash
brew install athyr-tech/tap/athyr
```

Or download directly:

```bash
# Apple Silicon (M1/M2/M3)
curl -LO https://github.com/athyr-tech/athyr/releases/latest/download/athyr-darwin-arm64.tar.gz

# Intel
curl -LO https://github.com/athyr-tech/athyr/releases/latest/download/athyr-darwin-amd64.tar.gz

tar xzf athyr-darwin-*.tar.gz
sudo mv athyr /usr/local/bin/
```

### Linux

```bash
# AMD64
curl -LO https://github.com/athyr-tech/athyr/releases/latest/download/athyr-linux-amd64.tar.gz

# ARM64
curl -LO https://github.com/athyr-tech/athyr/releases/latest/download/athyr-linux-arm64.tar.gz

tar xzf athyr-linux-*.tar.gz
sudo mv athyr /usr/local/bin/
```

### Windows

Download the latest release from [GitHub Releases](https://github.com/athyr-tech/athyr/releases) and add the binary to your PATH.

## Verify Installation

After installation, verify Athyr is working:

```bash
athyr version
```

You should see output like:

```
athyr version 0.1.0
```

## Next Steps

Now that Athyr is installed, head to the [Quick Start](/docs/quickstart/) guide to run your first agent.

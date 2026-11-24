# Agent Bootstrap

Engineering effort to manage bootstrapping a new device,
powered by wonderful [`mise bootstrap`](https://mise.jdx.dev/bootstrap.html)

Support both Windows and Linux (including WSL2)

- [Prerequisites](#prerequisites)
- [How to bootstrap](#how-to-bootstrap)
  - [1. Clone the repo](#1-clone-the-repo)
  - [2. Customize](#2-customize)
  - [3. Run `mise bootstrap`](#3-run-mise-bootstrap)
  - [4. To update later](#4-to-update-later)
- [What are not tracked](#what-are-not-tracked)

## Prerequisites

For both Windows and Linux:

- A clean system
- `mise` is installed, use default installation script
- git
  - windows: `scoop install git`
  - linux: `sudo apt install git`

For Windows specific:

- `scoop` and `winget` installed, and **configured**
  - if you need `scoop` and `winget` to install tools on different drive, configure it before `mise bootstrap`
- PowerShell 7 installed (prefer to enable auto update by windows)
- install followings:
  - latest Visual C++ via `winget install Microsoft.VCRedist.2015+.x64`

For linux specific:

- None

For human running this bootstrap, you also need a terminal with nerd fonts

## How to bootstrap

### 1. Clone the repo

You can either clone it to `~/.config/mise` (recommended), or for linux, clone it anywhere

```sh
git clone https://github.com/CX-AIAgents/agent-bootstrap.git ~/.config/mise
cd ~/.config/mise
```

### 2. Customize

Use VSCode to open this repo, and do following customize:

1. [`miserc.local.toml`](miserc.local.toml): set your profile, windows please set "desktop"
2. [`.env_var.template`](conf.d\dotfiles\.env_var.template): copy `.env_var.template` into `.env_var` at the same folder, and add any API keys. On Windows, optionally copy [`.env_var.windows.template`](conf.d\dotfiles\.env_var.windows.template) into `.env_var.windows` for Windows-only paths (such as `D:\` tool directories)
3. Finally, add any `.local.toml` to customize any settings for this current device, without being tracked by git

### 3. Run `mise bootstrap`

Depends on where you clone it, if it is cloned in `~/.config/mise`:

```sh
mise bootstrap
```

If not in `~/.config/mise`:

```sh
mise bootstrap \
  --from https://github.com/CX-AIAgents/agent-bootstrap.git \
  --from-dir /path/to/checkout \
  --config-dir .
```

> The 3 flags are:
>
> - `--from <GIT_URL>` selects the Git repository to bootstrap from. Later runs reuse the checkout.
> - `--from-dir <DIR>` is the directory where you cloned in step 1 so mise uses your customized copy.
> - `--config-dir .` links mise’s global config directory (normally `~/.config/mise`) to your checkout directory. The `.` is relative to the checkout directory you cloned, not your shell’s current directory. The global config directory must be absent, empty, or already linked to that location.

### 4. To update later

```sh
mise bootstrap status
mise bootstrap --update
```

`--update` refreshes package metadata, git pull the repo, then apply the config. It’s safe to run multiple times.

## What are not tracked

This repo can track many things but the following are so not tracked by design:

1. Settings of dependencies needed by `mise bootstrap`: such as `scoop` and `winget` settings
2. Anything sensitive: while the `.env_var` has a template file to help you add API keys in env var. Other configs such as SSH, `gws` config files, any AI Agents config files that contains API keys, terminal profiles containing IP addresses, are not tracked.
3. Agent Skills and AGENTS.md: currently are tracked on a dedicated repo, with a dedicated push script to push to common location such as `~/.agents/skills`
4. Services Login: ChatGPT App Login, Pi Coding Agent ChatGPT login, etc. Please login manually after bootstrap.

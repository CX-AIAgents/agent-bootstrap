# Agent Bootstrap

Engineering effort to manage bootstraping a new device,
powered by wonderful [`mise bootstrap`](https://mise.jdx.dev/bootstrap.html)

Support both Windows and Linux (including WSL2)

## Prerequisites

For both Windows and Linux:

- A clean system
- `mise` is installed, use default installation script

For Windows specific:

- PowerShell 7 installed either via `winget` or MSIX installer (prefer to enable auto update by windows)
- `scoop` installed
- install followings:
  - vc
  - git via `scoop install git`

For linux specific:

- None

## How to bootstrap

```sh
mise bootstrap --adopt "<repository-url or absolute-path-to-this-repository>"
```

Open the shell that has the `mise activate` (Zsh or PowerShell 7),
then check:

```sh
mise bootstrap status
```

## How to update

when you pushed new update to this repo, update your device

```sh
mise bootstrap --update
```

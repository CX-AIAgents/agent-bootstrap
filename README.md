# Agent Bootstrap

Engineering effort to manage bootstraping a new device,
powered by wonderful [`mise bootstrap`](https://mise.jdx.dev/bootstrap.html)

Support both Windows and Linux (including WSL2)

## Prerequisites

For both Windows and Linux:

- A clean system
- `mise` is installed, use default installation script
- A terminal with a nerf font

For Windows specific:

- PowerShell 7 installed either via `winget` or MSIX installer (prefer to enable auto update by windows)
- `scoop` installed
- install followings:
  - latest Visual C++ via `winget install Microsoft.VCRedist.2015+.x64`
  - git via `scoop install git`

For linux specific:

- None

## How to bootstrap

Clone this repo somewhere first,
make sure don't delete your cloned copy

```sh
mise run setup  # run the `mise bootstrap` from this repo
mise run setup status # `mise bootstrap status`
mise run setup --update # `mise bootstrap --update`
```

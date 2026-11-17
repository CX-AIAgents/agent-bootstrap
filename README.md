# Agent Bootstrap

Engineering effort to manage bootstrapping a new device,
powered by wonderful [`mise bootstrap`](https://mise.jdx.dev/bootstrap.html)

Support both Windows and Linux (including WSL2)

## Prerequisites

For both Windows and Linux:

- A clean system
- `mise` is installed, use default installation script
- A terminal with a nerf font
- git
  - windows: `scoop install git`
  - linux: `sudo apt install git`

For Windows specific:

- `scoop` installed
- PowerShell 7 installed either via `winget` or MSIX installer (prefer to enable auto update by windows)
- install followings:
  - latest Visual C++ via `winget install Microsoft.VCRedist.2015+.x64`

For linux specific:

- None

## How to bootstrap

### Option 1: Clone directly into `~/.config/mise` (or `MISE_CONFIG_DIR`)

```sh
git clone <this-repo> ~/.config/mise
cd ~/.config/mise

# Optional: add any *.local.toml overrides before bootstrapping
# Optional: create .env_var file in conf.d/dotfiles/
mise bootstrap
```

### Option 2: Clone elsewhere and link `~/.config/mise` (or `MISE_CONFIG_DIR`) to it

```sh
git clone <this-repo> /path/to/checkout

# Optional: add any *.local.toml overrides inside /path/to/checkout
# Optional: create .env_var file in conf.d/dotfiles/
mise bootstrap \
  --from <this-repo> \
  --from-dir /path/to/checkout \
  --config-dir .
```

## How to update

```sh
mise bootstrap status
mise bootstrap --update
```

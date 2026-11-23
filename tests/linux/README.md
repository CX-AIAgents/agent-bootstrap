# Linux Docker Compose bootstrap test

From the repository root in PowerShell or a Linux terminal, open a fresh Ubuntu 24.04 shell.

```sh
docker compose -f tests/linux/compose.yaml run --rm sandbox
```

From `tests/linux/`, the short form is `docker compose run --rm sandbox`. Compose mounts `prepare.sh` read-only at `/tmp/prepare.sh` and the current repository read-write at `/home/ubuntu/.config/mise`. The guest sees uncommitted edits and ignored files, including your local `.env_var` and `miserc.local.toml` if present. Writes under the project mount persist on the host. [Compose file](compose.yaml)

## Run bootstrap yourself

At `READY`, you have a Bash prompt as `ubuntu`, with Git, mise and passwordless sudo. The disposable account has an empty local password so bootstrap can change the login shell to Zsh. Check the commit, create the local environment file if needed, and run bootstrap when ready. [Project prerequisites](../../README.md#prerequisites)

```sh
cd ~/.config/mise
git rev-parse --short HEAD
test -e conf.d/dotfiles/.env_var || install -m 600 conf.d/dotfiles/.env_var.template conf.d/dotfiles/.env_var
mise bootstrap
```

Use `mise bootstrap status` to inspect the result, or run `mise bootstrap` again to test a repeat run. Type `exit` to remove the container.

On this minimal Ubuntu image, opening Zsh after bootstrap can report a missing `fzf/examples/key-bindings.zsh`. The image excludes that file under `/usr/share/doc`, so Ctrl+R uses Zsh's built-in history search.

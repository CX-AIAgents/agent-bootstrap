# Windows Sandbox bootstrap test

Use a fresh x64 Windows Sandbox with networking enabled. The launcher installs the Windows prerequisites and opens PowerShell 7 in the guest checkout. [Project prerequisites](../../README.md#prerequisites)

## Prepare the guest checkout

Copy the repository into `%USERPROFILE%\.config\mise` inside the sandbox.

- To copy a clean commit without ignored files such as your private `.env_var`, create a local clone on the host first and copy that folder to `%USERPROFILE%\.config\mise` inside the sandbox (including its hidden `.git` directory):

  ```powershell
  $sandboxCopy = Join-Path $env:TEMP ("agent-bootstrap-" + [guid]::NewGuid())
  git clone --no-local . $sandboxCopy
  $sandboxCopy
  ```

- Alternatively, copy your working tree directly if you want uncommitted edits or local `.env_var` / `miserc.local.toml` files included.

## Run the test

1. Inside the sandbox, open `%USERPROFILE%\.config\mise\tests\windows` (or a separately copied `windows` folder) and double-click `Start setup.cmd`. Explorer may display it as `Start setup`.
2. When setup prints `READY`, it drops you into a PowerShell 7 prompt at `~/.config/mise`. Run bootstrap:

   ```powershell
   mise bootstrap
   ```

## What setup prepares

Setup installs WinGet, the x64 Visual C++ redistributable, PowerShell 7, Scoop, Git, and mise using their default locations. [Setup script](./Prepare.ps1)

If missing in `%USERPROFILE%\.config\mise`, setup creates `miserc.local.toml` with the `desktop` profile and copies `conf.d\dotfiles\.env_var.template` to `.env_var`. Existing local files are preserved on reruns.

If setup fails, check `%TEMP%\mise-sandbox-setup\setup.log`. You can rerun `Start setup.cmd` after fixing the issue.

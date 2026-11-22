# Windows Sandbox bootstrap test

Use a fresh x64 Windows Sandbox with networking enabled. The launcher installs the Windows prerequisites and prepares the guest checkout. [Project prerequisites](../../README.md#prerequisites)

## Choose what to test

- To test the **published default branch**, copy just this `windows` folder to the sandbox desktop. The launcher clones the project from GitHub.
- To test **a local commit**, commit the files you want to test, including `tests/`. Run the commands below from the host repository, then copy the resulting folder to the sandbox desktop, including its hidden `.git` directory. This clean clone includes unpushed commits and excludes ignored files such as your private `.env_var`.

  ```powershell
  $sandboxCopy = Join-Path $env:TEMP ("agent-bootstrap-" + [guid]::NewGuid())
  git clone --no-local . $sandboxCopy
  $sandboxCopy
  ```

## Run the test

1. Inside the sandbox, open the copied `windows` folder, or `tests\windows` inside the copied checkout. Double-click **Start setup.cmd**. Explorer may display it as **Start setup**.
2. Open `%TEMP%\mise-sandbox-setup\Setup status.txt` in the guest. Once it reports `READY`, open a new **PowerShell 7** window in the guest and run the bootstrap.

   ```powershell
   mise bootstrap
   ```

## What setup prepares

Setup installs WinGet, the x64 Visual C++ redistributable, PowerShell 7, Scoop, Git, and mise. It uses the official mise PowerShell installer, adds the `extras` and `nerd-fonts` Scoop buckets, and sets MesloLGS Nerd Font as the console font. WinGet and Scoop use their default locations. [Setup script](./Prepare.ps1)

The guest checkout lives at `%USERPROFILE%\.config\mise`. Setup creates `miserc.local.toml` with the `desktop` profile and copies `conf.d\dotfiles\.env_var.template` to `.env_var` beside it. Reruns reuse the guest checkout and preserve its local settings. The status report includes its commit and notes any working tree changes.

If setup stops, check the `FAILED` line in `Setup status.txt` and the output in `Setup details.txt` beside it. You can rerun the launcher after correcting the issue. The subsequent `mise bootstrap` command prints its own output in PowerShell.

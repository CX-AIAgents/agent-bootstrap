# Testing

This folder contains files for testing this `mise bootstrap`

- [linux](linux/): Use a container to test the bootstrap process. Run `docker compose run --rm sandbox` in this folder, which installs prerequisites mentioned in project [README.md](../README.md) and opens a shell for you to run `mise bootstrap` yourself.
- [windows](windows/): Use Windows Sandbox to test the bootstrap process. Copy the repo to `%USERPROFILE%\.config\mise` in the sandbox and run `tests\windows\Start setup.cmd`, which installs the prerequisites mentioned in project [README.md](../README.md) and opens PowerShell 7 for you to run `mise bootstrap`.

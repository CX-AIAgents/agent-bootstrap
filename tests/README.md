# Testing

This folder contains files for testing this `mise bootstrap`

- [linux](linux/): Use a container to test the bootstrap processRun `docker compose run --rm sandbox` in this folder which installs prerequisites mentioned in project [README.md](../README.md). Then it left a terminal for you to run `mise bootstrap` yourself.
- [windows](windows/): Use a Windows Sandbox to test the bootstrap process. Copy this folder into Windows Sandbox and run `Start setup.cmd`, it will install any prerequisites mentioned in project [README.md](../README.md). So all you need is to run `mise bootstrap` in the sandbox.

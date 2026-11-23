#!/usr/bin/env bash
# Install the prerequisites and open an interactive shell in the Ubuntu test container.
set -euo pipefail

if [[ ! -f /.dockerenv ]]; then
  echo "Run this script inside the Ubuntu Docker container." >&2
  exit 2
fi

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl git sudo
printf 'ubuntu ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/bootstrap
chmod 440 /etc/sudoers.d/bootstrap
# The stock account is locked. An empty password lets chsh change this disposable user's shell.
passwd -d ubuntu >/dev/null

cd /home/ubuntu
# Docker can create this parent as root when the project is bind-mounted.
install -d -o ubuntu -g ubuntu .config
runuser -u ubuntu -- mkdir -p .config/mise
# Docker Desktop can present a writable host checkout as root-owned inside the guest.
runuser -u ubuntu -- git config --global --add safe.directory /home/ubuntu/.config/mise
runuser -u ubuntu -- curl -fsSL --retry 3 https://mise.run -o /tmp/install-mise.sh
runuser -u ubuntu -- sh /tmp/install-mise.sh
runuser -u ubuntu -- .local/bin/mise --version

printf '\nREADY  Prerequisites installed. Use ~/.config/mise for your project.\n'
printf 'Run mise bootstrap when ready. Type exit to discard the container.\n\n'
exec runuser -u ubuntu -- env PATH="/home/ubuntu/.local/bin:$PATH" bash -i

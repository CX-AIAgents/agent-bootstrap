# Preserve the first occurrence of each command directory in nested shells.
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  "${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}/bin"
  "$HOME/.bun/bin"
  /usr/local/bin
  $path
)

# Add CUDA commands only when the toolkit is installed.
if [[ -d /usr/local/cuda/bin ]]; then
  path=(/usr/local/cuda/bin $path)
fi
export PATH

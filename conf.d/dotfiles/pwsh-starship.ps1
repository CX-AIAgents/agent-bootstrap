# Only enable Starship TransientPrompt in interactive shells. Otherwise Starship prints an error message.
if ($env:TERM -ne 'dumb') {
  Invoke-Expression (&starship init powershell)
  if (Get-Command Enable-TransientPrompt -ErrorAction SilentlyContinue) {
    Enable-TransientPrompt
  }
}

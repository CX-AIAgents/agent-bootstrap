# Only enable Starship TransientPrompt in interactive shells. Otherwise Starship prints an error message.
if ($env:TERM -ne 'dumb') {
  # Decode Starship's UTF-8 init script without changing the session's encoding.
  $previousEncoding = [Console]::OutputEncoding
  try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    Invoke-Expression (&starship init powershell)
  } finally {
    [Console]::OutputEncoding = $previousEncoding
  }

  if (Get-Command Enable-TransientPrompt -ErrorAction SilentlyContinue) {
    Enable-TransientPrompt
  }
}

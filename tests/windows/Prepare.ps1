#Requires -Version 5.1
<#
.SYNOPSIS
  Prepare a fresh x64 Windows Sandbox for an interactive mise bootstrap test.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ($env:USERNAME -ne 'WDAGUtilityAccount') {
  throw 'Run Start setup.cmd inside Windows Sandbox.'
}

$workDir = Join-Path $env:TEMP 'mise-sandbox-setup'
$statusFile = Join-Path $workDir 'Setup status.txt'
$repo = Join-Path $env:USERPROFILE '.config\mise'
$repoUrl = 'https://github.com/CX-AIAgents/agent-bootstrap.git'
$env:GIT_TERMINAL_PROMPT = '0'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Keep a short status report alongside the full installation transcript.
function Write-Status([string]$Message) {
  Add-Content -LiteralPath $statusFile -Value $Message -Encoding UTF8
  Write-Host $Message
}

# Windows PowerShell 5.1 does not throw on a native command's nonzero exit code.
function Invoke-Checked([string]$Program, [string[]]$Arguments) {
  & $Program @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Program $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

# Pick up paths registered by installers in this PowerShell session.
function Update-SessionPath {
  $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = [Environment]::ExpandEnvironmentVariables("$machinePath;$userPath")
}

# Download one upstream installer to the sandbox's temporary directory.
function Save-Download([string]$Uri, [string]$Path) {
  Invoke-Checked curl.exe @('--fail', '--silent', '--show-error', '--location', '--retry', '2', '--output', $Path, $Uri)
}

# Install the signed WinGet bundle with the x64 dependencies from the same release.
function Install-SandboxWinGet {
  $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -Headers @{ 'User-Agent' = 'agent-bootstrap-sandbox' }
  $packageDir = Join-Path $workDir ([string]$release.id)
  New-Item -ItemType Directory -Force -Path $packageDir | Out-Null
  $bundleName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
  $zipName = 'DesktopAppInstaller_Dependencies.zip'
  foreach ($name in @($bundleName, $zipName)) {
    $asset = $release.assets | Where-Object name -eq $name
    if ($asset.digest -notmatch '^sha256:[a-f0-9]{64}$') { throw "Missing release asset or SHA-256 for $name." }
    $file = Join-Path $packageDir $name
    Save-Download $asset.browser_download_url $file
    if ("sha256:$((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash)" -ne $asset.digest) {
      throw "WinGet release checksum mismatch for $name."
    }
  }
  Expand-Archive -LiteralPath (Join-Path $packageDir $zipName) -DestinationPath $packageDir -Force
  $deps = @(Get-ChildItem -LiteralPath (Join-Path $packageDir 'x64') -File -Filter '*.appx' | ForEach-Object FullName)
  if ($deps.Count -eq 0) { throw 'The WinGet release contains no x64 dependencies.' }
  Add-AppxPackage -Path (Join-Path $packageDir $bundleName) -DependencyPath $deps
  Update-SessionPath
}

# WinGet can report success, reboot required, or an already-current package.
function Install-WinGetPackage([string]$Id, [string[]]$Options = @()) {
  & winget.exe install --id $Id --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --silent @Options
  if ($LASTEXITCODE -notin @(0, 3010, -1978335189)) {
    throw "WinGet could not install $Id (exit $LASTEXITCODE)."
  }
}

# Clone the local revision when running from a checkout's tests/windows directory.
function Initialize-Checkout([string]$LauncherDir, [string]$Destination) {
  $sourceDir = [IO.Path]::GetFullPath((Join-Path $LauncherDir '..\..'))
  $hasSource = (Test-Path -LiteralPath (Join-Path $sourceDir '.git')) -and
    (Test-Path -LiteralPath (Join-Path $sourceDir 'conf.d\190-bootstrap-task.windows.toml'))
  if (-not (Test-Path -LiteralPath (Join-Path $Destination '.git'))) {
    $from = if ($hasSource) { $sourceDir } else { $repoUrl }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Invoke-Checked git.exe @('clone', '--no-local', '--', $from, $Destination)
    if ($hasSource) {
      Invoke-Checked git.exe @('-C', $Destination, 'remote', 'set-url', 'origin', $repoUrl)
    }
  }

  $commit = Invoke-Checked git.exe @('-C', $Destination, 'rev-parse', '--verify', 'HEAD')
  if ($hasSource -and $commit -ne (Invoke-Checked git.exe @('-C', $sourceDir, 'rev-parse', '--verify', 'HEAD'))) {
    throw "The checkout at $Destination is at $commit. Select the intended commit there and rerun setup."
  }
  $template = Join-Path $Destination 'conf.d\dotfiles\.env_var.template'
  if (-not (Test-Path -LiteralPath $template -PathType Leaf)) { throw "Bootstrap template missing at $template." }
  $profileFile = Join-Path $Destination 'miserc.local.toml'
  if (-not (Test-Path -LiteralPath $profileFile)) {
    Set-Content -LiteralPath $profileFile -Value 'env = ["desktop"]' -Encoding Ascii
  }
  $envFile = Join-Path $Destination 'conf.d\dotfiles\.env_var'
  if (-not (Test-Path -LiteralPath $envFile)) { Copy-Item -LiteralPath $template -Destination $envFile }
  Write-Status "Checkout $commit in $Destination"
  if (Invoke-Checked git.exe @('-C', $Destination, 'status', '--porcelain')) {
    Write-Status 'The sandbox checkout also contains local changes.'
  }
}

New-Item -ItemType Directory -Force -Path $workDir | Out-Null
# Keep concurrent launchers from overwriting each other's downloads and reports.
$runLock = [IO.File]::Open((Join-Path $workDir 'setup.lock'), 'OpenOrCreate', 'Write', 'None')
$transcribing = $false
try {
  Set-Content -LiteralPath $statusFile -Value 'Checking Windows Sandbox prerequisites' -Encoding UTF8
  Start-Transcript -Path (Join-Path $workDir 'Setup details.txt') -Force | Out-Null
  $transcribing = $true
  Set-Location -LiteralPath $env:USERPROFILE

  Write-Status 'Checking WinGet.'
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { Install-SandboxWinGet }
  Write-Status "WinGet $(Invoke-Checked winget.exe @('--version'))"

  Write-Status 'Installing the x64 Visual C++ runtime and PowerShell 7.'
  Install-WinGetPackage 'Microsoft.VCRedist.2015+.x64'
  Install-WinGetPackage 'Microsoft.PowerShell' @('--installer-type', 'wix')
  Update-SessionPath
  $pwshVersion = Invoke-Checked pwsh.exe @('-NoProfile', '-Command', '$PSVersionTable.PSVersion.ToString()')
  if (([version]$pwshVersion).Major -ne 7) { throw "Expected PowerShell 7, found $pwshVersion." }
  Write-Status "PowerShell $pwshVersion"
  $vcKeys = @(
    'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
  )
  $runtime = Get-ItemProperty -Path $vcKeys -ErrorAction SilentlyContinue | Where-Object Installed -eq 1 | Select-Object -First 1
  if (-not $runtime) { throw 'The x64 Visual C++ runtime is missing from the registry.' }
  Write-Status "Visual C++ x64 $($runtime.Version)"

  Write-Status 'Preparing Scoop and Git.'
  if ((Get-ExecutionPolicy -Scope CurrentUser) -in @('Undefined', 'Restricted')) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
  }
  if (-not (Get-Command scoop.cmd -ErrorAction SilentlyContinue)) {
    $installer = Join-Path $workDir 'Install-Scoop.ps1'
    Save-Download 'https://get.scoop.sh' $installer
    $options = @('-NoLogo', '-NoProfile', '-File', $installer)
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $options += '-RunAsAdmin' }
    Invoke-Checked powershell.exe $options
    Update-SessionPath
  }
  Invoke-Checked scoop.cmd @('install', 'git')
  Update-SessionPath
  Write-Status "$(Invoke-Checked git.exe @('--version')) (Scoop)"
  Initialize-Checkout $PSScriptRoot $repo

  Write-Status 'Checking mise.'
  if (-not (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.local\bin\mise.exe'))) {
    $installer = Join-Path $workDir 'Install-Mise.ps1'
    Save-Download 'https://mise.run/powershell' $installer
    Invoke-Checked pwsh.exe @('-NoLogo', '-NoProfile', '-File', $installer)
    Update-SessionPath
  }
  Write-Status "mise $(Invoke-Checked mise.exe @('--version'))"

  Write-Status 'Preparing the Scoop buckets and Meslo Nerd Font.'
  foreach ($bucket in @('extras', 'nerd-fonts')) {
    if (-not (Test-Path -LiteralPath (Join-Path $env:USERPROFILE "scoop\buckets\$bucket"))) {
      Invoke-Checked scoop.cmd @('bucket', 'add', $bucket)
    }
  }
  Invoke-Checked scoop.cmd @('install', 'nerd-fonts/Meslo-NF')
  $font = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts\MesloLGSNerdFont-Regular.ttf'
  Add-Type -AssemblyName System.Drawing
  $fontSet = [Drawing.Text.PrivateFontCollection]::new()
  try {
    $fontSet.AddFontFile($font)
    $fontName = $fontSet.Families[0].Name
  } finally {
    $fontSet.Dispose()
  }
  [Microsoft.Win32.Registry]::SetValue('HKEY_CURRENT_USER\Console', 'FaceName', $fontName)
  Write-Status "Console font $fontName"

  $configs = (Invoke-Checked mise.exe @('config', 'ls', '--json') | Out-String)
  if ($configs -notmatch '040-packages\.windows-desktop\.toml' -or $configs -notmatch '190-bootstrap-task\.windows\.toml' -or $configs -match '090-repos\.linux\.toml') {
    throw 'mise did not load the Windows desktop configuration. Check miserc.local.toml in the sandbox checkout.'
  }
  Invoke-Checked mise.exe @('bootstrap', '--help') | Out-Null
  Write-Status 'READY - Open PowerShell 7 in the sandbox and run mise bootstrap.'
} catch {
  Write-Status "FAILED - $($_.Exception.Message)"
  exit 1
} finally {
  if ($transcribing) { Stop-Transcript | Out-Null }
  $runLock.Dispose()
}

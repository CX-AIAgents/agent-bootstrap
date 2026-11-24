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

$repo = Join-Path $env:USERPROFILE '.config\mise'
$template = Join-Path $repo 'conf.d\dotfiles\.env_var.template'
if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
  throw "Copy the agent-bootstrap repository to $repo first."
}

$workDir = Join-Path $env:TEMP 'mise-sandbox-setup'
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Windows PowerShell 5.1 does not throw on a native command's nonzero exit code.
function Invoke-Checked([string]$Program, [string[]]$Arguments) {
  & $Program @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Program $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

# Refresh PATH in this session after installers update Machine/User env vars.
function Update-SessionPath {
  $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = [Environment]::ExpandEnvironmentVariables("$machinePath;$userPath")
}

# Windows Sandbox lacks WinGet and its UWP dependencies; install both from the latest release.
function Install-SandboxWinGet {
  $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -Headers @{ 'User-Agent' = 'agent-bootstrap-sandbox' }
  $packageDir = Join-Path $workDir ([string]$release.id)
  New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

  $bundle = Join-Path $packageDir 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
  $depsZip = Join-Path $packageDir 'DesktopAppInstaller_Dependencies.zip'
  foreach ($item in @(
    @{ Name = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; Path = $bundle },
    @{ Name = 'DesktopAppInstaller_Dependencies.zip'; Path = $depsZip }
  )) {
    $asset = $release.assets | Where-Object name -eq $item.Name
    if (-not $asset) { throw "Missing WinGet release asset: $($item.Name)." }
    Invoke-Checked curl.exe @('--fail', '--silent', '--show-error', '--location', '--retry', '2', '--output', $item.Path, $asset.browser_download_url)
  }

  Expand-Archive -LiteralPath $depsZip -DestinationPath $packageDir -Force
  $deps = @(Get-ChildItem -LiteralPath (Join-Path $packageDir 'x64') -File -Filter '*.appx' | ForEach-Object FullName)
  Add-AppxPackage -Path $bundle -DependencyPath $deps
  Update-SessionPath
}

# Accept WinGet's success (0), reboot-required (3010), and already-installed (-1978335189) exit codes.
function Install-WinGetPackage([string]$Id, [string[]]$Options = @()) {
  & winget.exe install --id $Id --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --silent @Options
  if ($LASTEXITCODE -notin @(0, 3010, -1978335189)) {
    throw "WinGet could not install $Id (exit $LASTEXITCODE)."
  }
}

Start-Transcript -Path (Join-Path $workDir 'setup.log') -Force | Out-Null
try {
  Set-Location -LiteralPath $env:USERPROFILE

  Write-Host '1/4 Checking WinGet, Visual C++ runtime, and PowerShell 7...'
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { Install-SandboxWinGet }
  Install-WinGetPackage 'Microsoft.VCRedist.2015+.x64'
  Install-WinGetPackage 'Microsoft.PowerShell' @('--installer-type', 'wix')
  Update-SessionPath

  Write-Host '2/4 Preparing Scoop and Git...'
  if ((Get-ExecutionPolicy -Scope CurrentUser) -in @('Undefined', 'Restricted')) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
  }
  if (-not (Get-Command scoop.cmd -ErrorAction SilentlyContinue)) {
    $scoopInstaller = Join-Path $workDir 'Install-Scoop.ps1'
    Invoke-Checked curl.exe @('--fail', '--silent', '--show-error', '--location', '--retry', '2', '--output', $scoopInstaller, 'https://get.scoop.sh')
    $scoopArgs = @('-NoLogo', '-NoProfile', '-File', $scoopInstaller)
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $scoopArgs += '-RunAsAdmin' }
    Invoke-Checked powershell.exe $scoopArgs
    Update-SessionPath
  }
  Invoke-Checked scoop.cmd @('install', 'git')
  Update-SessionPath

  Write-Host '3/4 Installing mise...'
  if (-not (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.local\bin\mise.exe'))) {
    $miseInstaller = Join-Path $workDir 'Install-Mise.ps1'
    Invoke-Checked curl.exe @('--fail', '--silent', '--show-error', '--location', '--retry', '2', '--output', $miseInstaller, 'https://mise.run/powershell')
    Invoke-Checked pwsh.exe @('-NoLogo', '-NoProfile', '-File', $miseInstaller)
    Update-SessionPath
  }

  Write-Host '4/4 Seeding missing local config files...'
  $profileFile = Join-Path $repo 'miserc.local.toml'
  if (-not (Test-Path -LiteralPath $profileFile)) {
    Set-Content -LiteralPath $profileFile -Value 'env = ["desktop"]' -Encoding Ascii
  }
  $envFile = Join-Path $repo 'conf.d\dotfiles\.env_var'
  if (-not (Test-Path -LiteralPath $envFile)) {
    Copy-Item -LiteralPath $template -Destination $envFile
  }
} finally {
  Stop-Transcript | Out-Null
}

Set-Location -LiteralPath $repo
Write-Host "`nREADY  Prerequisites installed in $repo."
Write-Host "Run mise bootstrap when ready. Type exit to close.`n"
& pwsh.exe -NoLogo

# Loads .env into your CURRENT PowerShell session, once, so `robot` picks it up
# via %{ENV_VAR} for as many commands as you run afterward — same idea as
# activating a Python venv once and using python/pip freely after.
#
# IMPORTANT: dot-source this script, don't run it directly — it needs to set
# environment variables in your CURRENT session's scope, not an isolated
# script scope that gets torn down when the script finishes:
#
#   . .\init-env.ps1
#
# Running it as .\init-env.ps1 (without the leading ".") won't persist the
# variables in your terminal afterward, which is why this checks for that below.
# NOTE: this script hasn't been tested on an actual Windows/PowerShell machine —
# the bash equivalent (init-env.sh) has been, this one is reasoned-through, not
# verified. Please flag anything that doesn't work as expected.

if ($MyInvocation.InvocationName -ne '.') {
    Write-Error "This script must be dot-sourced, not executed directly. Run:`n  . $($MyInvocation.MyCommand.Path)"
    exit 1
}

if (-not (Test-Path .env)) {
    Write-Error "No .env file found. Copy .env.example to .env and fill in real values first:`n  Copy-Item .env.example .env"
    return
}

$loadedNames = @()
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*[A-Za-z_][A-Za-z0-9_]*\s*=') {
        $name, $value = $_ -split '=', 2
        $name = $name.Trim()
        Set-Item "Env:$name" $value.Trim()
        $loadedNames += $name
    }
}

Write-Host "Loaded from .env:"
$loadedNames | ForEach-Object { Write-Host "  $_" }

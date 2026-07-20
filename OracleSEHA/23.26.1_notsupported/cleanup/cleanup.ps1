#Requires -Version 5.1
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# cleanup.ps1
#   Windows (PowerShell) port of cleanup.sh. Tears down the SEHA lab and removes
#   the shared ASM disks (and per-node u01 disks on VirtualBox) that
#   `vagrant destroy` intentionally leaves behind.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\cleanup.ps1 [-Force]
#   # or, if execution policy allows:
#   .\cleanup.ps1 [-Force]
#------------------------------------------------------------------------------
[CmdletBinding()]
param(
    [Alias('f')][switch]$Force,
    [Alias('h')][switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$Config = '.\config\vagrant.yml'
if (-not (Test-Path -LiteralPath 'Vagrantfile')) {
    Write-Error 'Vagrantfile not found; run from project root'; exit 1
}
if (-not (Test-Path -LiteralPath $Config)) {
    Write-Error "$Config not found"; exit 1
}

# Minimal YAML scalar reader for the flat 2-level structure vagrant.yml uses
# (top-level section, then 2-space-indented key: value lines). Mirrors the awk
# logic in cleanup.sh so behaviour stays identical.
function Get-YamlValue {
    param([string]$Section, [string]$Key)
    $current = $null
    foreach ($raw in Get-Content -LiteralPath $Config) {
        if ($raw -match '^[A-Za-z_][A-Za-z0-9_]*:') {
            $current = ($raw -split ':', 2)[0].Trim()
            continue
        }
        if ($current -ne $Section) { continue }
        $line = $raw -replace '^\s+', ''
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        $idx = $line.IndexOf(':')
        if ($idx -lt 0) { continue }
        if ($line.Substring(0, $idx) -ne $Key) { continue }
        $val = $line.Substring($idx + 1)
        $val = ($val -replace '#.*$', '').Trim()
        return $val
    }
    return ''
}

$Provider = Get-YamlValue -Section 'env'    -Key 'provider'
$Prefix   = Get-YamlValue -Section 'env' -Key 'prefix_name'
$AsmNum   = Get-YamlValue -Section 'env' -Key 'asm_disk_num'
$AsmPath  = Get-YamlValue -Section 'env' -Key 'asm_disk_path'
$Pool     = Get-YamlValue -Section 'env' -Key 'storage_pool_name'

if ([string]::IsNullOrEmpty($Provider) -or [string]::IsNullOrEmpty($Prefix) -or [string]::IsNullOrEmpty($AsmNum)) {
    Write-Error "env.provider / env.prefix_name / env.asm_disk_num must be set in $Config"
    exit 1
}
$AsmNumInt = [int]$AsmNum

if ($Help) {
@"
Usage: .\cleanup.ps1 [-Force]
  Runs 'vagrant destroy -f' and removes shared ASM disks for the configured
  provider ($Provider). Pass -Force to skip the confirmation prompt.
"@
    exit 0
}

if (-not $Force) {
    Write-Host "This will:"
    Write-Host "  1. vagrant destroy -f"
    Write-Host "  2. delete $AsmNumInt shared ASM disk(s) (provider: $Provider)"
    if ($Provider -eq 'virtualbox') {
        Write-Host "  3. delete per-node u01 disks (node1_u01.vdi, node2_u01.vdi)"
    }
    Write-Host ""
    $ans = Read-Host 'Continue? [y/N]'
    if ($ans -notmatch '^[yY]$') { Write-Host 'Aborted.'; exit 0 }
}

# Resolve VBoxManage: prefer PATH, then default install location.
function Get-VBoxManage {
    $cmd = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $default = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
    if (Test-Path -LiteralPath $default) { return $default }
    return $null
}

function Invoke-VBoxCloseAndDelete {
    param([string]$Path, [string]$VBoxManage)
    $listed = & $VBoxManage list hdds 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed | Select-String -SimpleMatch $Path -Quiet)) {
        & $VBoxManage closemedium disk "$Path" --delete 2>$null
        if ($LASTEXITCODE -ne 0) {
            & $VBoxManage closemedium disk "$Path" 2>$null | Out-Null
        }
    }
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    }
}

Write-Host '=== vagrant destroy -f ==='
try { & vagrant destroy -f } catch { Write-Warning $_ }

switch ($Provider) {
    'libvirt' {
        # libvirt isn't native on Windows; surface a clear error rather than
        # pretending to clean up. Users on Hyper-V/WSL should run cleanup.sh
        # from inside the Linux environment that actually hosts the pool.
        Write-Error "provider 'libvirt' is not supported on Windows; run cleanup.sh from the Linux host that owns the pool"
        exit 1
    }
    'virtualbox' {
        $vbm = Get-VBoxManage
        if (-not $vbm) {
            Write-Error 'VBoxManage.exe not found in PATH or default install location'
            exit 1
        }
        $dir = if ([string]::IsNullOrEmpty($AsmPath)) { '.' } else { $AsmPath.TrimEnd('\','/') }
        Write-Host "=== removing VirtualBox shared ASM disks from $dir ==="
        for ($i = 0; $i -lt $AsmNumInt; $i++) {
            $p = [System.IO.Path]::GetFullPath((Join-Path $dir "asm_disk$i.vdi"))
            Invoke-VBoxCloseAndDelete -Path $p -VBoxManage $vbm
        }
        Write-Host '=== removing per-node u01 disks ==='
        foreach ($node_disk in 'node1_u01.vdi', 'node2_u01.vdi') {
            $p = [System.IO.Path]::GetFullPath((Join-Path '.' $node_disk))
            Invoke-VBoxCloseAndDelete -Path $p -VBoxManage $vbm
        }
    }
    default {
        Write-Error "unknown provider '$Provider' in $Config"
        exit 1
    }
}

Write-Host 'Cleanup complete.'

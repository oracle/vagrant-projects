#Requires -Version 5.1
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# cleanup.ps1
#   Windows (PowerShell) port of cleanup.sh. Tears down the True Cache lab and
#   removes the u01 disk (primary_u01.vdi) and the oradata disks
#   (primary_oradata_disk<i>.vdi) that `vagrant destroy` leaves behind on
#   VirtualBox.
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
        # Strip one layer of surrounding quotes so '' / "" resolve to empty.
        if ($val.Length -ge 2 -and
            (($val[0] -eq '"' -and $val[-1] -eq '"') -or ($val[0] -eq "'" -and $val[-1] -eq "'"))) {
            $val = $val.Substring(1, $val.Length - 2)
        }
        return $val
    }
    return ''
}

$Provider   = Get-YamlValue -Section 'env'   -Key 'provider'
$Prefix     = Get-YamlValue -Section 'env'   -Key 'prefix_name'
$OradataNum = Get-YamlValue -Section 'env'   -Key 'oradata_disk_num'
$OradataPath= Get-YamlValue -Section 'env'   -Key 'oradata_disk_path'

$U01H1 = Get-YamlValue -Section 'host1' -Key 'u01_disk'; if ([string]::IsNullOrEmpty($U01H1)) { $U01H1 = '.\primary_u01.vdi' }

if ([string]::IsNullOrEmpty($Provider) -or [string]::IsNullOrEmpty($Prefix) -or [string]::IsNullOrEmpty($OradataNum)) {
    Write-Error "env.provider / env.prefix_name / env.oradata_disk_num must be set in $Config"
    exit 1
}
$OradataNumInt = [int]$OradataNum

if ($Help) {
@"
Usage: .\cleanup.ps1 [-Force]
  Runs 'vagrant destroy -f' and removes the True Cache lab disks for the
  configured provider ($Provider). Pass -Force to skip the confirmation prompt.
"@
    exit 0
}

if (-not $Force) {
    Write-Host "This will:"
    Write-Host "  1. vagrant destroy -f"
    if ($Provider -eq 'virtualbox') {
        Write-Host "  2. delete the u01 disk ($(Split-Path -Leaf $U01H1))"
        Write-Host "  3. delete $OradataNumInt oradata disk(s)"
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
        Write-Host '=== removing VirtualBox u01 disk ==='
        $p = [System.IO.Path]::GetFullPath((Join-Path '.' $U01H1))
        Invoke-VBoxCloseAndDelete -Path $p -VBoxManage $vbm
        $dir = if ([string]::IsNullOrEmpty($OradataPath)) { '.' } else { $OradataPath.TrimEnd('\','/') }
        Write-Host "=== removing VirtualBox oradata disks from $dir ==="
        for ($i = 0; $i -lt $OradataNumInt; $i++) {
            $p = [System.IO.Path]::GetFullPath((Join-Path $dir "primary_oradata_disk$i.vdi"))
            Invoke-VBoxCloseAndDelete -Path $p -VBoxManage $vbm
        }
    }
    default {
        Write-Error "unknown provider '$Provider' in $Config"
        exit 1
    }
}

# Installer verification stamps written by the Vagrantfile cache (verify_installer!).
# Safe to drop: the next 'vagrant up' re-verifies the zip and regenerates them.
Write-Host '=== removing installer verification stamps ==='
if (Test-Path -LiteralPath '.\ORCL_software') {
    Get-ChildItem -LiteralPath '.\ORCL_software' -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*.verified' } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host 'Cleanup complete.'

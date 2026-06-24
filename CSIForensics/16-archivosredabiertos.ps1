
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "016-archivosredabiertos.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Archivos abiertos en unidades de red (estimado) $(Get-Date) ===`r`n`r`n",
    $utf8
)

# Helper para extraer texto legible de valores REG_BINARY
function Get-StringFromBinary {
    param([byte[]]$Bytes)
    try {
        $s = [System.Text.Encoding]::Unicode.GetString($Bytes)
        $clean = $s -replace '\x00', ''
        $clean = $clean -replace '[^\x20-\x7E]', ''
        if ($clean -match '\\\\' -or $clean -match '[A-Za-z]:\\') {
            return $clean
        }
    } catch {}
    return $null
}

# ==============================
# 1. RECENT FILES (.LNK) + ComDlg32
# ==============================
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf
    $hkUser = "Registry::HKEY_USERS\$sid"
    $text = "Usuario: $user`r`nSID: $sid`r`n----------------------`r`n"
    $found = $false

    # -- RecentDocs registry (buscar \\ o letra de unidad) --
    $recentPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $recentPath) {
        try {
            $items = Get-ChildItem $recentPath -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    $props = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
                    foreach ($p2 in $props.PSObject.Properties) {
                        if ($p2.Name -eq 'MRUListEx' -or -not $p2.Value) { continue }
                        $val = $p2.Value
                        if ($val -is [string] -and ($val -match "\\\\" -or $val -match '[A-Za-z]:\\')) {
                            $text += "$val`r`n"; $found = $true
                        } elseif ($val -is [byte[]]) {
                            $decoded = Get-StringFromBinary $val
                            if ($decoded) { $text += "$decoded`r`n"; $found = $true }
                        }
                    }
                } catch {}
            }
        } catch {}
    }

    # -- Unidades de red mapeadas para este usuario --
    $netDrives = @{}
    $netReg = "$hkUser\Network"
    if (Test-Path $netReg) {
        Get-ChildItem $netReg -ErrorAction SilentlyContinue | ForEach-Object {
            $letter = $_.PSChildName
            $rp = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).RemotePath
            if ($rp) { $netDrives[$letter] = $rp }
        }
    }

    # -- .LNK files in Recent folder (solo rutas de red) --
    $recentDir = Join-Path $profilePath "AppData\Roaming\Microsoft\Windows\Recent"
    if (Test-Path $recentDir) {
        try {
            $shell = New-Object -ComObject WScript.Shell -ErrorAction SilentlyContinue
        } catch { $shell = $null }
        if ($shell) {
            $lnkFiles = Get-ChildItem $recentDir -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach ($lnk in $lnkFiles) {
                try {
                    $shortcut = $shell.CreateShortcut($lnk.FullName)
                    $target = $shortcut.TargetPath
                    if (-not $target) { continue }
                    $isNet = $false
                    if ($target -match '^\\\\') { $isNet = $true }
                    elseif ($target -match '^([A-Za-z]):\\') {
                        $driveLetter = $matches[1]
                        if ($netDrives.ContainsKey($driveLetter)) { $isNet = $true }
                    }
                    if ($isNet) {
                        $text += "  Shortcut: $target`r`n"; $found = $true
                    }
                } catch {}
            }
            [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell)
        }
    }

    # -- ComDlg32 (Open/Save Dialog MRU - almacena rutas reales) --
    $comdlg = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
    if (Test-Path $comdlg) {
        $exts = Get-ChildItem $comdlg -ErrorAction SilentlyContinue
        foreach ($ext in $exts) {
            try {
                $props = Get-ItemProperty $ext.PSPath -ErrorAction SilentlyContinue
                foreach ($p2 in $props.PSObject.Properties) {
                    if ($p2.Name -eq 'MRUListEx' -or -not $p2.Value) { continue }
                    $val = $p2.Value
                    if ($val -is [string] -and ($val -match "\\\\" -or $val -match '[A-Za-z]:\\')) {
                        $text += "  ComDlg: $val`r`n"; $found = $true
                    } elseif ($val -is [byte[]]) {
                        $decoded = Get-StringFromBinary $val
                        if ($decoded) { $text += "  ComDlg: $decoded`r`n"; $found = $true }
                    }
                }
            } catch {}
        }
    }

    # -- ComDlg32 LastVisitedMRU (tiene rutas de red) --
    $lastVis = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
    if (Test-Path $lastVis) {
        try {
            $props = Get-ItemProperty $lastVis -ErrorAction SilentlyContinue
            foreach ($p2 in $props.PSObject.Properties) {
                if ($p2.Name -match '^\d+$' -and $p2.Value) {
                    if ($p2.Value -is [string] -and ($p2.Value -match "\\\\" -or $p2.Value -match '[A-Za-z]:\\')) {
                        $text += "  LastVisited: $($p2.Value)`r`n"; $found = $true
                    } elseif ($p2.Value -is [byte[]]) {
                        $decoded = Get-StringFromBinary $p2.Value
                        if ($decoded) { $text += "  LastVisited: $decoded`r`n"; $found = $true }
                    }
                }
            }
        } catch {}
    }

    if (-not $found) { $text += "Sin archivos de red recientes`r`n" }
    $text += "`r`n"
    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

# ==============================
# 2. OFFICE MRU
# ==============================
[System.IO.File]::AppendAllText($outFile, "=== Office recientes ===`r`n`r`n", $utf8)

$officeVersions = @("16.0", "15.0", "14.0", "12.0", "11.0")
$officeApps = @("Word", "Excel", "PowerPoint", "Access", "Outlook", "Publisher")

foreach ($p in $profiles) {
    $sid = $p.PSChildName
    $user = Split-Path ((Get-ItemProperty $p.PSPath).ProfileImagePath) -Leaf

    foreach ($ver in $officeVersions) {
        foreach ($app in $officeApps) {
            $mruPaths = @(
                "Registry::HKEY_USERS\$sid\Software\Microsoft\Office\$ver\$app\File MRU",
                "Registry::HKEY_USERS\$sid\Software\Microsoft\Office\$ver\$app\Place MRU",
                "Registry::HKEY_USERS\$sid\Software\Microsoft\Office\$ver\$app\Reading Locations"
            )
            foreach ($mru in $mruPaths) {
                if (Test-Path $mru) {
                    try {
                        $props = Get-ItemProperty $mru -ErrorAction SilentlyContinue
                        foreach ($p2 in $props.PSObject.Properties) {
                            if ($p2.Name -notin @('MRUListEx', '') -and $p2.Value) {
                                if ($p2.Value -is [string] -and $p2.Value -match "\\\\") {
                                    $line = "Usuario: $user | $app ($ver) -> $($p2.Value)`r`n"
                                    [System.IO.File]::AppendAllText($outFile, $line, $utf8)
                                }
                            }
                        }
                    } catch {}
                }
            }
        }
    }
}

# ==============================
# FIN
# ==============================
[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
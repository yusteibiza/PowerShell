
$outDir = ".\resultados"
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

# ==============================
# 1. RECENT FILES (TODOS LOS USUARIOS)
# ==============================
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf

    $recentPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"

    if (!(Test-Path $recentPath)) { continue }

    try {
        $items = Get-ChildItem $recentPath -ErrorAction SilentlyContinue

        $text = "Usuario: $user`r`nSID: $sid`r`n----------------------`r`n"

        $found = $false

        foreach ($item in $items) {

            try {
                $props = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue

                foreach ($p2 in $props.PSObject.Properties) {

                    $val = $p2.Value

                    # detectar rutas de red
                    if ($val -is [string] -and $val -match "\\\\") {

                        $text += "$val`r`n"
                        $found = $true
                    }
                }
            }
            catch {}
        }

        if (-not $found) {
            $text += "Sin archivos de red recientes`r`n"
        }

        $text += "`r`n"

        [System.IO.File]::AppendAllText($outFile, $text, $utf8)
    }
    catch {}
}

# ==============================
# 2. OFFICE (Word/Excel recent)
# ==============================
[System.IO.File]::AppendAllText($outFile, "=== Office recientes ===`r`n`r`n", $utf8)

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $user = Split-Path ((Get-ItemProperty $p.PSPath).ProfileImagePath) -Leaf

    $office = "Registry::HKEY_USERS\$sid\Software\Microsoft\Office"

    if (!(Test-Path $office)) { continue }

    try {
        $keys = Get-ChildItem $office -Recurse -ErrorAction SilentlyContinue

        foreach ($k in $keys) {
            try {
                $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue

                foreach ($p2 in $props.PSObject.Properties) {
                    if ($p2.Value -is [string] -and $p2.Value -match "\\\\") {

                        $line = "Usuario: $user -> $($p2.Value)`r`n"
                        [System.IO.File]::AppendAllText($outFile, $line, $utf8)
                    }
                }
            }
            catch {}
        }
    }
    catch {}
}

# ==============================
# FIN
# ==============================
[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
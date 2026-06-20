
$outDir = ".\resultados"
$outFile = Join-Path $outDir "017-cuentagoogle.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Google Drive Forensic $(Get-Date) ===`r`n`r`n",
    $utf8
)

$users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue |
Where-Object { $_.Name -notin @("Public","Default","Default User","All Users","WDAGUtilityAccount") }

foreach ($u in $users) {

    $path = Join-Path $u.FullName "AppData\Local\Google\DriveFS"

    if (!(Test-Path $path)) { continue }

    $text = "Usuario: $($u.Name)`r`n----------------------`r`n"

    # =========================
    # 1. Buscar bases SQLite
    # =========================
    $dbs = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue |
           Where-Object { $_.Extension -in ".db",".sqlite" }

    foreach ($db in $dbs) {
        $text += "DB encontrada: $($db.FullName)`r`n"
    }

    # =========================
    # 2. Logs (pueden contener account ID)
    # =========================
    $logs = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in ".log",".txt" }

    foreach ($log in $logs) {
        try {
            $c = Get-Content $log.FullName -Raw -ErrorAction SilentlyContinue

            # Account ID Google Drive
            if ($c -match "([0-9A-Za-z_-]{20,})") {
                $text += "Posible Account ID: $($matches[1])`r`n"
            }

            # a veces aparece email SOLO en logs antiguos
            if ($c -match "([a-zA-Z0-9._%+-]+@gmail\.com)") {
                $text += "Email detectado en log: $($matches[1])`r`n"
            }

        } catch {}
    }

    # =========================
    # 3. Estado general
    # =========================
    if ($text -eq "Usuario: $($u.Name)`r`n----------------------`r`n") {
        $text += "Sin datos accesibles (cuenta cifrada por Google)`r`n"
    }

    $text += "`r`n"

    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
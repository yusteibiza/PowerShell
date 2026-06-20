
$outDir = ".\resultados"
$outFile = Join-Path $outDir "019-impdocxrenuncia.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Análisis impresión documentos (renuncia) $(Get-Date) ===`r`n`r`n",
    $utf8
)

# ==============================
# 1. PrintService Log
# ==============================
$log = "Microsoft-Windows-PrintService/Operational"

try {
    $events = Get-WinEvent -LogName $log -ErrorAction Stop |
              Where-Object { $_.Id -eq 307 }

    foreach ($e in $events) {

        $msg = $e.Message

        if ($msg -match "renuncia|baja|carta") {

            $text = "Fecha: $($e.TimeCreated)`r`n"
            $text += "Evento: $($e.Id)`r`n"
            $text += "Detalle:`r`n$msg`r`n"
            $text += "----------------------`r`n"

            [System.IO.File]::AppendAllText($outFile, $text, $utf8)
        }
    }
}
catch {
    [System.IO.File]::AppendAllText(
        $outFile,
        "PrintService log no disponible o no activado`r`n`r`n",
        $utf8
    )
}

# ==============================
# 2. Spooler (archivos recientes)
# ==============================
$spool = "C:\Windows\System32\spool\PRINTERS"

if (Test-Path $spool) {

    $files = Get-ChildItem $spool -ErrorAction SilentlyContinue

    foreach ($f in $files) {

        $text = "Archivo spool: $($f.Name)`r`n"
        $text += "Fecha: $($f.CreationTime)`r`n"
        $text += "----------------------`r`n"

        [System.IO.File]::AppendAllText($outFile, $text, $utf8)
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
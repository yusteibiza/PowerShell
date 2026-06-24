
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "018-marcasdocx.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Analisis timestamps DOCX (renuncia) $(Get-Date) ===`r`n`r`n",
    $utf8
)

# Cargar driver ZIP (compatible PS5/PS7)
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
} catch {
    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
}

# =========================
# 1. Buscar DOCX en perfiles de usuario
# =========================
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath
    if (-not $profilePath) { continue }

    $searchDirs = @(
        "Desktop",
        "Documents",
        "Downloads"
    ) | ForEach-Object { Join-Path $profilePath $_ }

    $files = Get-ChildItem $searchDirs -Filter "*.docx" -Recurse -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -match "renuncia|baja|carta" }

    foreach ($f in $files) {

        $text = "Archivo: $($f.FullName)`r`n"
        $text += "--------------------------`r`n"
        $text += "FS Creation: $($f.CreationTime)`r`n"
        $text += "FS Modified: $($f.LastWriteTime)`r`n"
        $text += "FS Access: $($f.LastAccessTime)`r`n"

        # Extraer DOCX (Open XML)
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($f.FullName)
            $core = $zip.Entries | Where-Object { $_.FullName -eq "docProps/core.xml" }

            if ($core) {
                $stream = $core.Open()
                $reader = New-Object System.IO.StreamReader($stream)
                $xml = $reader.ReadToEnd()
                $reader.Close()
                $stream.Close()

                if ($xml -match "<dcterms:created>(.*?)</dcterms:created>") {
                    $text += "DOC Created (internal): $($matches[1])`r`n"
                }
                if ($xml -match "<dcterms:modified>(.*?)</dcterms:modified>") {
                    $text += "DOC Modified (internal): $($matches[1])`r`n"
                }
                if ($xml -match "<cp:lastPrinted>(.*?)</cp:lastPrinted>") {
                    $text += "Last Printed: $($matches[1])`r`n"
                }
            }

            $zip.Dispose()
        }
        catch {
            $text += "Error leyendo metadatos DOCX: $($_.Exception.Message)`r`n"
        }

        $text += "`r`n"
        [System.IO.File]::AppendAllText($outFile, $text, $utf8)
    }
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin an�lisis ===`r`n",
    $utf8
)

$outDir = ".\resultados"
$outFile = Join-Path $outDir "018-marcasdocx.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Análisis timestamps DOCX (renuncia) $(Get-Date) ===`r`n`r`n",
    $utf8
)

# =========================
# 1. Buscar DOCX en escritorios
# =========================
$files = Get-ChildItem "C:\Users\*\Desktop\*.docx" -ErrorAction SilentlyContinue |
Where-Object { $_.Name -match "renuncia|baja|carta" }

foreach ($f in $files) {

    $text = "Archivo: $($f.FullName)`r`n"
    $text += "--------------------------`r`n"

    # =========================
    # 2. Timestamps NTFS
    # =========================
    $text += "FS Creation: $($f.CreationTime)`r`n"
    $text += "FS Modified: $($f.LastWriteTime)`r`n"
    $text += "FS Access: $($f.LastAccessTime)`r`n"

    # =========================
    # 3. Extraer DOCX (Open XML)
    # =========================
    try {

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $zip = [System.IO.Compression.ZipFile]::OpenRead($f.FullName)

        # core.xml contiene metadatos de Word
        $core = $zip.Entries | Where-Object { $_.FullName -eq "docProps/core.xml" }

        if ($core) {

            $stream = $core.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xml = $reader.ReadToEnd()

            $reader.Close()
            $stream.Close()

            # buscar timestamps internos
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

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin análisis ===`r`n",
    $utf8
)
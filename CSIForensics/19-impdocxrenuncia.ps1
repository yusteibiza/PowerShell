
# ==============================
# RUTAS SEGURAS
# ==============================

$base = Split-Path -Parent $MyInvocation.MyCommand.Path

$archivo = Join-Path $base "docrenuncia.docx"
$salida  = Join-Path $base "resultados\019-impdocxrenuncia.txt"

# Crear carpeta de salida
New-Item -ItemType Directory -Force -Path (Split-Path $salida) | Out-Null


# ==============================
# VARIABLES
# ==============================

$fecha = $null


# ==============================
# INTENTO 1: WORD COM
# ==============================

$word = New-Object -ComObject Word.Application
$word.Visible = $false

$doc = $null

try {
    $doc = $word.Documents.Open((Resolve-Path $archivo).Path)

    try {
        $fecha = $doc.BuiltInDocumentProperties("Last Print Date").Value
    } catch {
        $fecha = $null
    }

    $doc.Close($false)
}
catch {
    $fecha = $null
}
finally {
    $word.Quit()

    if ($doc)  { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null }
    if ($word) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null }

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}


# ==============================
# INTENTO 2: OPENXML (FALLBACK)
# ==============================

if (-not $fecha) {

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $archivo))

    $entry = $zip.Entries | Where-Object { $_.FullName -eq "docProps/core.xml" }

    if ($entry) {

        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $xml = [xml]$reader.ReadToEnd()

        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("dcterms", "http://purl.org/dc/terms/")

        $node = $xml.SelectSingleNode("//dcterms:modified", $ns)

        if ($node) {
            $fecha = $node."#text"
        }

        $reader.Close()
        $stream.Close()
    }

    $zip.Dispose()
}


# ==============================
# FORMATO FECHA ESPAÑOL
# ==============================

if ($fecha -and $fecha -ne "Sin fecha de impresión") {

    try {
        $dt = [datetime]::Parse($fecha).ToLocalTime()
        $fecha = $dt.ToString("dd/MM/yyyy HH:mm:ss")
    }
    catch {
        $fecha = "Formato no reconocible: $fecha"
    }
}
else {
    $fecha = "Sin fecha de impresión"
}


# ==============================
# GUARDAR UTF-8
# ==============================

[System.IO.File]::WriteAllText(
    $salida,
    "Fecha de impresión de docrenuncia.docx`: $fecha",
    [System.Text.Encoding]::UTF8
)



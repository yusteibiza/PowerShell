$docrenuncia = (Get-Item ".\docrenuncia.docx")

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
    " -- Marcas de tiempo archivo de renuncia --`n
- Nombre .............: $($docrenuncia.Name)
- Fecha creación .....: $($docrenuncia.CreationTime.ToString("dd/MM/yyyy hh:mm:ss"))
- Última modificación : $($docrenuncia.LastWriteTime.ToString("dd/MM/yyyy hh:mm:ss"))
- Último acceso ......: $($docrenuncia.LastAccessTime.ToString("dd/MM/yyyy hh:mm:ss"))",
    $utf8
);


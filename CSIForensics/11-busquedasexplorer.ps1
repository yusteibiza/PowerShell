# ============================================================
#  Get-RecentSearches.ps1
#  Lista los archivos buscados recientemente en el Explorador
#  de Windows (WordWheelQuery + archivos recientes del sistema)
#  Salida: .\resultados\011-busquedas_explorer.txt  (sin consola)
# ============================================================

param(
    [int]$Limit = 50,          # Máximo de resultados a mostrar
    [switch]$ExportCSV,        # Exportar resultados a CSV
    [string]$CSVPath = "$env:USERPROFILE\Desktop\BusquedasRecientes.csv"
)

# ── Silenciar toda salida a consola ────────────────────────
$null = $null   # no-op; toda salida se dirige al archivo

# ── Carpeta y archivo de salida ────────────────────────────
$OutputDir  = Join-Path $PSScriptRoot "resultados"
$OutputFile = Join-Path $OutputDir "011-busquedas_explorer.txt"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Inicializar archivo limpio
Set-Content -Path $OutputFile -Value "" -Encoding UTF8

# ── Función helper: escribir solo al archivo ───────────────
function Out-File-Line {
    param([string]$Text = "")
    Add-Content -Path $OutputFile -Value $Text -Encoding UTF8
}

function Write-Header {
    param([string]$text)
    Out-File-Line ""
    Out-File-Line ("─" * 60)
    Out-File-Line "  $text"
    Out-File-Line ("─" * 60)
}

# ── 1. WordWheelQuery (términos escritos en la barra de búsqueda) ──
function Get-WordWheelQuery {
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
    $results = @()

    if (Test-Path $regPath) {
        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -match '^\d+$') {
                $value = $prop.Value
                if ($value -is [byte[]]) {
                    $text = [System.Text.Encoding]::Unicode.GetString($value).TrimEnd([char]0)
                } else {
                    $text = $value.ToString()
                }
                if ($text -ne "") {
                    $results += [PSCustomObject]@{
                        Termino = $text
                        Orden   = [int]$prop.Name
                    }
                }
            }
        }
        $results = $results | Sort-Object Orden
    }
    return $results
}

# ── 2. Archivos recientes (Recent Items) ──────────────────
function Get-RecentFiles {
    $recentPath = [System.Environment]::GetFolderPath("Recent")
    $results = @()

    if (Test-Path $recentPath) {
        $files = Get-ChildItem -Path $recentPath -Filter "*.lnk" -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First $Limit

        $shell = New-Object -ComObject WScript.Shell
        foreach ($file in $files) {
            try {
                $shortcut = $shell.CreateShortcut($file.FullName)
                $target = $shortcut.TargetPath
                if ($target -ne "") {
                    $results += [PSCustomObject]@{
                        Nombre       = $file.BaseName
                        RutaDestino  = $target
                        UltimoAcceso = $file.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
                    }
                }
            } catch { }
        }
    }
    return $results
}

# ── 3. Rutas escritas en la barra del Explorador (TypedPaths) ──
function Get-TypedPaths {
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
    $results = @()

    if (Test-Path $regPath) {
        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -match '^url\d+$') {
                $results += [PSCustomObject]@{
                    Clave = $prop.Name
                    Ruta  = $prop.Value
                }
            }
        }
    }
    return $results
}

# ── 4. Búsquedas guardadas (.search-ms) ───────────────────
function Get-SavedSearches {
    $searchPaths = @(
        "$env:USERPROFILE\Searches",
        "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
    )
    $results = @()

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Filter "*.search-ms" -Recurse -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $results += [PSCustomObject]@{
                    Nombre        = $f.BaseName
                    Ruta          = $f.FullName
                    FechaCreacion = $f.CreationTime.ToString("dd/MM/yyyy HH:mm:ss")
                }
            }
        }
    }
    return $results
}

# ══════════════════════════════════════════════════════════
#  MAIN — toda salida va al archivo, nada a consola
# ══════════════════════════════════════════════════════════

Out-File-Line "  ╔══════════════════════════════════════════════════════╗"
Out-File-Line "  ║     HISTORIAL DE BÚSQUEDAS - EXPLORADOR DE WINDOWS  ║"
Out-File-Line "  ╚══════════════════════════════════════════════════════╝"
Out-File-Line "  Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

# --- Términos buscados ---
Write-Header "1. Términos escritos en la barra de búsqueda"
$wordWheel = Get-WordWheelQuery
if ($wordWheel.Count -gt 0) {
    Out-File-Line ("{0,-6} {1}" -f "Orden", "Termino")
    Out-File-Line ("{0,-6} {1}" -f "-----", "-------")
    foreach ($item in $wordWheel) {
        Out-File-Line ("{0,-6} {1}" -f $item.Orden, $item.Termino)
    }
} else {
    Out-File-Line "  No se encontraron términos de búsqueda."
}

# --- Archivos recientes ---
Write-Header "2. Archivos abiertos recientemente"
$recentFiles = Get-RecentFiles
if ($recentFiles.Count -gt 0) {
    Out-File-Line ("{0,-22} {1}" -f "UltimoAcceso", "RutaDestino")
    Out-File-Line ("{0,-22} {1}" -f "------------", "-----------")
    foreach ($item in $recentFiles) {
        Out-File-Line ("{0,-22} {1}" -f $item.UltimoAcceso, $item.RutaDestino)
    }
} else {
    Out-File-Line "  No se encontraron archivos recientes."
}

# --- Rutas escritas ---
Write-Header "3. Rutas escritas directamente en el Explorador"
$typedPaths = Get-TypedPaths
if ($typedPaths.Count -gt 0) {
    Out-File-Line ("{0,-8} {1}" -f "Clave", "Ruta")
    Out-File-Line ("{0,-8} {1}" -f "-----", "----")
    foreach ($item in $typedPaths) {
        Out-File-Line ("{0,-8} {1}" -f $item.Clave, $item.Ruta)
    }
} else {
    Out-File-Line "  No se encontraron rutas escritas."
}

# --- Búsquedas guardadas ---
Write-Header "4. Busquedas guardadas (.search-ms)"
$savedSearches = Get-SavedSearches
if ($savedSearches.Count -gt 0) {
    Out-File-Line ("{0,-22} {1}" -f "FechaCreacion", "Ruta")
    Out-File-Line ("{0,-22} {1}" -f "-------------", "----")
    foreach ($item in $savedSearches) {
        Out-File-Line ("{0,-22} {1}" -f $item.FechaCreacion, $item.Ruta)
    }
} else {
    Out-File-Line "  No se encontraron busquedas guardadas."
}

# --- Exportar CSV opcional ---
if ($ExportCSV) {
    $allData = @()
    $wordWheel     | ForEach-Object { $allData += [PSCustomObject]@{ Origen="Busqueda"; Detalle=$_.Termino;     Fecha="" } }
    $recentFiles   | ForEach-Object { $allData += [PSCustomObject]@{ Origen="Archivo";  Detalle=$_.RutaDestino; Fecha=$_.UltimoAcceso } }
    $typedPaths    | ForEach-Object { $allData += [PSCustomObject]@{ Origen="Ruta";     Detalle=$_.Ruta;        Fecha="" } }
    $savedSearches | ForEach-Object { $allData += [PSCustomObject]@{ Origen="Guardada"; Detalle=$_.Ruta;        Fecha=$_.FechaCreacion } }
    $allData | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8
    Out-File-Line ""
    Out-File-Line "  CSV exportado en: $CSVPath"
}

Out-File-Line ""
Out-File-Line ("─" * 60)
Out-File-Line "  Fin del reporte."
Out-File-Line ("─" * 60)

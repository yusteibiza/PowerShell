
$outDir = ".\resultados"
$outFile = Join-Path $outDir "020-notas.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Sticky Notes Forensic $(Get-Date) ===`r`n`r`n",
    $utf8
)

# ==============================
# 1. Buscar usuarios
# ==============================
$users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -notin @("Public","Default","Default User","All Users","WDAGUtilityAccount")
}

foreach ($u in $users) {

    $stickyPath = Join-Path $u.FullName "AppData\Local\Packages"

    if (!(Test-Path $stickyPath)) { continue }

    $app = Get-ChildItem $stickyPath -Directory -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -like "Microsoft.MicrosoftStickyNotes*" }

    if (-not $app) { continue }

    $text = "Usuario: $($u.Name)`r`n----------------------`r`n"

    foreach ($a in $app) {

        $state = Join-Path $a.FullName "LocalState"

        $db = Join-Path $state "plum.sqlite"

        $text += "Ruta app: $($a.FullName)`r`n"

        if (Test-Path $db) {

            $text += "Base datos: $db`r`n"

            # ==============================
            # 2. Intento de lectura básica SQLite (raw)
            # ==============================
            try {

                Add-Type -AssemblyName System.Data

                $conn = New-Object System.Data.SQLite.SQLiteConnection
                $conn.ConnectionString = "Data Source=$db;Version=3;"
                $conn.Open()

                $cmd = $conn.CreateCommand()
                $cmd.CommandText = "SELECT * FROM Note"

                $reader = $cmd.ExecuteReader()

                while ($reader.Read()) {

                    try {
                        $text += "----------------------`r`n"
                        $text += "Nota detectada (raw)`r`n"

                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $text += "$($reader.GetName($i)): $($reader.GetValue($i))`r`n"
                        }
                    }
                    catch {}
                }

                $conn.Close()

            }
            catch {
                $text += "No se pudo leer SQLite directamente (posible bloqueo o versión moderna)`r`n"
            }

        }
        else {
            $text += "No existe plum.sqlite`r`n"
        }

        $text += "`r`n"
    }

    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
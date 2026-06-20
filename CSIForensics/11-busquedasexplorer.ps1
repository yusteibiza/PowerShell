
$outDir = ".\resultados"
$outFile = Join-Path $outDir "011-busquedas_explorer.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

# Inicializar archivo correctamente
    [System.IO.File]::WriteAllText(
        $outFile,
        "=== Inicio extraccion WordWheelQuery $(Get-Date) ===`r`n`r`n",
        $utf8
    )

# Obtener perfiles del sistema (con SID)
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf

    $hkUser = "Registry::HKEY_USERS\$sid"

    # Si el usuario no está cargado en HKEY_USERS, saltar
    if (!(Test-Path $hkUser)) {
        continue
    }

    $regPath = "$hkUser\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"

    if (Test-Path $regPath) {

        try {
            $data = Get-ItemProperty $regPath -ErrorAction Stop

            $text = "Usuario: $user`r`nSID: $sid`r`n--------------------------`r`n"

            $found = $false

            foreach ($prop in $data.PSObject.Properties) {
                if ($prop.Name -match '^\d+$' -and $prop.Value) {
                    $text += "$($prop.Value)`r`n"
                    $found = $true
                }
            }

            if (-not $found) {
                $text += "Sin busquedas registradas`r`n"
            }

            $text += "`r`n"

            [System.IO.File]::AppendAllText($outFile, $text, $utf8)
        }
        catch {
            [System.IO.File]::AppendAllText(
                $outFile,
                "Error en ${user}: $($_.Exception.Message)`r`n`r`n",
                $utf8
            )
        }
    }
}

    [System.IO.File]::AppendAllText(
        $outFile,
        "`r`n=== Fin extraccion ===`r`n",
        $utf8
    )

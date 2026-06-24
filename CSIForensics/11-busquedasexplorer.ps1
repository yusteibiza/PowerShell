
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "011-busquedas_explorer.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

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
                    if ($prop.Value -is [string]) {
                        $text += "$($prop.Value)`r`n"
                        $found = $true
                    }
                    elseif ($prop.Value -is [byte[]]) {
                        $decoded = [System.Text.Encoding]::Unicode.GetString($prop.Value)
                        $decoded = $decoded -replace '\x00', ''
                        $decoded = $decoded -replace '[^\x20-\x7E\x80-\xFF\xC0-\xFF\xA0-\xFF]', ' '
                        $decoded = ($decoded -split '\s+' -ne '' ) -join ' '
                        $decoded = $decoded.Trim()
                        if ($decoded -ne '') {
                            $text += "$decoded`r`n"
                            $found = $true
                        }
                    }
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

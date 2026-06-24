
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "015-unidadesred.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Unidades de red + IP servidor $(Get-Date) ===`r`n`r`n",
    $utf8
)

# ==============================
# 1. Unidades de red actuales (WMI)
# ==============================
$net = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
Where-Object { $_.DriveType -eq 4 }

foreach ($drive in $net) {

    $path = $drive.ProviderName

    if (-not $path) { continue }

    $text = "Unidad: $($drive.DeviceID)`r`n"
    $text += "Ruta: $path`r`n"

    if ($path -match "\\\\([^\\]+)\\") {

        $server = $matches[1]
        $text += "Servidor: $server`r`n"

        try {
            $ip = [System.Net.Dns]::GetHostAddresses($server) |
                  Where-Object { $_.AddressFamily -eq "InterNetwork" } |
                  Select-Object -First 1

            if ($ip) {
                $text += "IP: $($ip.IPAddressToString)`r`n"
            }
            else {
                $text += "IP: no resuelta`r`n"
            }
        }
        catch {
            $text += "IP: error resolucion`r`n"
        }
    }

    $text += "----------------------`r`n"

    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

# ==============================
# 2. Unidades persistentes (registro) - todos los usuarios
# ==============================
[System.IO.File]::AppendAllText($outFile, "`r`n=== Unidades persistentes (registro) ===`r`n`r`n", $utf8)

$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf
    $hkUser = "Registry::HKEY_USERS\$sid"

    if (!(Test-Path $hkUser)) { continue }

    $reg = "$hkUser\Network"

    if (Test-Path $reg) {

        Get-ChildItem $reg | ForEach-Object {

            $letter = $_.PSChildName
            $props = Get-ItemProperty $_.PSPath

            $remote = $props.RemotePath

            if ($remote) {

                $text = "Usuario: $user`r`n"
                $text += "Unidad: $letter`r`n"
                $text += "Ruta: $remote`r`n"

                if ($remote -match "\\\\([^\\]+)\\") {

                    $server = $matches[1]
                    $text += "Servidor: $server`r`n"

                    try {
                        $ip = [System.Net.Dns]::GetHostAddresses($server) |
                              Where-Object { $_.AddressFamily -eq "InterNetwork" } |
                              Select-Object -First 1

                        if ($ip) {
                            $text += "IP: $($ip.IPAddressToString)`r`n"
                        }
                    }
                    catch {}
                }

                $text += "----------------------`r`n"

                [System.IO.File]::AppendAllText($outFile, $text, $utf8)
            }
        }
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
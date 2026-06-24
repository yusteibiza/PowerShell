
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "014-dispexternos.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Dispositivos USB / almacenamiento externo $(Get-Date) ===`r`n`r`n",
    $utf8
)

# ==============================
# 1. USBSTOR (discos, memorias USB)
# ==============================
$usbStorPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"

[System.IO.File]::AppendAllText($outFile, "=== USBSTOR (Discos USB) ===`r`n`r`n", $utf8)

if (Test-Path $usbStorPath) {

    $devices = Get-ChildItem $usbStorPath -ErrorAction SilentlyContinue

    foreach ($device in $devices) {

        foreach ($instance in Get-ChildItem $device.PSPath -ErrorAction SilentlyContinue) {

            try {
                $props = Get-ItemProperty $instance.PSPath -ErrorAction SilentlyContinue

                $name = $props.FriendlyName
                $serial = $instance.PSChildName

                if (-not $name) { $name = "Desconocido" }

                $text = "Dispositivo: $name`r`n"
                $text += "Serial: $serial`r`n"
                $text += "----------------------`r`n"

                [System.IO.File]::AppendAllText($outFile, $text, $utf8)
            }
            catch {}
        }
    }
}

# ==============================
# 2. USB gen�rico
# ==============================
$usbPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"

[System.IO.File]::AppendAllText($outFile, "`r`n=== USB gen�ricos ===`r`n`r`n", $utf8)

if (Test-Path $usbPath) {

    $devices = Get-ChildItem $usbPath -ErrorAction SilentlyContinue

    foreach ($device in $devices) {

        foreach ($instance in Get-ChildItem $device.PSPath -ErrorAction SilentlyContinue) {

            try {
                $props = Get-ItemProperty $instance.PSPath -ErrorAction SilentlyContinue

                $text = "ID: $($instance.PSChildName)`r`n"

                if ($props.FriendlyName) {
                    $text += "Nombre: $($props.FriendlyName)`r`n"
                }

                $text += "----------------------`r`n"

                [System.IO.File]::AppendAllText($outFile, $text, $utf8)
            }
            catch {}
        }
    }
}

# ==============================
# 3. Discos montados (letras asignadas)
# ==============================
[System.IO.File]::AppendAllText($outFile, "`r`n=== Discos montados ===`r`n`r`n", $utf8)

$mounted = "HKLM:\SYSTEM\MountedDevices"

if (Test-Path $mounted) {

    $items = Get-ItemProperty $mounted

    foreach ($prop in $items.PSObject.Properties) {

        if ($prop.Name -like "\DosDevices\*") {

            $letter = $prop.Name

            if ($prop.Value -is [byte[]]) {
                $guid = [System.Text.Encoding]::Unicode.GetString($prop.Value) -replace '\x00', ''
                if ($guid -match '^[a-fA-F0-9-]{32,}$') {
                    $value = $guid
                } else {
                    $value = [System.BitConverter]::ToString($prop.Value) -replace '-', ' '
                }
            } else {
                $value = $prop.Value
            }

            $text = "Unidad: $letter`r`n"
            $text += "Identificador: $value`r`n"
            $text += "----------------------`r`n"

            [System.IO.File]::AppendAllText($outFile, $text, $utf8)
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
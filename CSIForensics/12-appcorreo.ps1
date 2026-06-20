
$outDir = ".\resultados"
$outFile = Join-Path $outDir "012-appcorreo.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Clientes de correo detectados $(Get-Date) ===`r`n`r`n",
    $utf8
)

# =========================
# OUTLOOK (Office clásico)
# =========================
$outlook = @(
    "HKLM:\SOFTWARE\Microsoft\Office",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office"
)

foreach ($path in $outlook) {
    if (Test-Path $path) {
        [System.IO.File]::AppendAllText(
            $outFile,
            "Outlook (Microsoft Office) detectado`r`n",
            $utf8
        )
        break
    }
}

# =========================
# NEW OUTLOOK / MAIL APP (UWP)
# =========================
$mailApp = Get-AppxPackage *microsoft.windowscommunicationsapps* -ErrorAction SilentlyContinue

if ($mailApp) {
    [System.IO.File]::AppendAllText(
        $outFile,
        "Windows Mail / Calendario detectado`r`n",
        $utf8
    )
}

$newOutlook = Get-AppxPackage *outlookforwindows* -ErrorAction SilentlyContinue

if ($newOutlook) {
    [System.IO.File]::AppendAllText(
        $outFile,
        "New Outlook detectado`r`n",
        $utf8
    )
}

# =========================
# THUNDERBIRD
# =========================
$users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -notin @(
        "Public","Default","Default User",
        "All Users","WDAGUtilityAccount"
    )
}

foreach ($u in $users) {

    $tb = Join-Path $u.FullName "AppData\Roaming\Thunderbird"

    if (Test-Path $tb) {

        $text = "Thunderbird detectado (usuario: $($u.Name))`r`n"

        $ini = Join-Path $tb "profiles.ini"

        if (Test-Path $ini) {
            $text += "Perfil activo encontrado`r`n"
        }

        [System.IO.File]::AppendAllText($outFile, $text, $utf8)
    }
}

# =========================
# FINAL
# =========================
[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)

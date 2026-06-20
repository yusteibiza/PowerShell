
$outDir = ".\resultados"
$outFile = Join-Path $outDir "013-cuentascorreo.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Cuentas de correo (Outlook MAPI) $(Get-Date) ===`r`n`r`n",
    $utf8
)

$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf
    $hkUser = "Registry::HKEY_USERS\$sid"

    $foundAccounts = @()

    # ==============================
    # OUTLOOK PROFILE (MAPI STORE)
    # ==============================
    $base = "$hkUser\Software\Microsoft\Office\16.0\Outlook\Profiles"

    if (Test-Path $base) {

        try {
            $profiles = Get-ChildItem $base -ErrorAction SilentlyContinue

            foreach ($prof in $profiles) {

                $profPath = $prof.PSPath

                # buscar claves donde suele estar el email
                $keys = Get-ChildItem $profPath -Recurse -ErrorAction SilentlyContinue

                foreach ($k in $keys) {

                    try {
                        $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue

                        foreach ($prop in $props.PSObject.Properties) {

                            $val = $prop.Value

                            # detectar emails reales
                            if ($val -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}$") {
                                $foundAccounts += $val
                            }
                        }
                    }
                    catch {}
                }
            }
        }
        catch {}
    }

    # ==============================
    # WINDOWS MAIL / CLOUD ACCOUNTS (heurístico)
    # ==============================
    $cloud = "$hkUser\Software\Microsoft\Windows\CurrentVersion\CloudStore"
    if (Test-Path $cloud) {

        try {
            $dump = Get-ChildItem $cloud -Recurse -ErrorAction SilentlyContinue

            foreach ($d in $dump) {
                try {
                    $props = Get-ItemProperty $d.PSPath -ErrorAction SilentlyContinue

                    foreach ($p2 in $props.PSObject.Properties) {
                        if ($p2.Value -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}$") {
                            $foundAccounts += $p2.Value
                        }
                    }
                }
                catch {}
            }
        }
        catch {}
    }

    # ==============================
    # THUNDERBIRD (real emails)
    # ==============================
    $tb = Join-Path $profilePath "AppData\Roaming\Thunderbird"

    if (Test-Path $tb) {

        $files = Get-ChildItem $tb -Recurse -Filter "prefs.js" -ErrorAction SilentlyContinue

        foreach ($f in $files) {
            try {
                $content = Get-Content $f.FullName -ErrorAction SilentlyContinue

                foreach ($line in $content) {
                    if ($line -match "@") {
                        if ($line -match "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,})") {
                            $foundAccounts += $matches[1]
                        }
                    }
                }
            }
            catch {}
        }
    }

    # ==============================
    # OUTPUT
    # ==============================
    $foundAccounts = $foundAccounts | Select-Object -Unique

    $text = "Usuario: $user`r`nSID: $sid`r`n----------------------`r`n"

    if ($foundAccounts.Count -gt 0) {
        foreach ($acc in $foundAccounts) {
            $text += "$acc`r`n"
        }
    }
    else {
        $text += "Sin cuentas de correo visibles`r`n"
    }

    $text += "`r`n"

    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
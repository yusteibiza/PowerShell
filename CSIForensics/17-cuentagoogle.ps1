
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "017-cuentagoogle.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Cuentas Google + Google Drive $(Get-Date) ===`r`n`r`n",
    $utf8
)

$emailRegexG = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(?:gmail|googlemail)\.[a-z]{2,}"

$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf
    $text = "Usuario: $user`r`n----------------------`r`n"
    $found = $false

    # ================================================================
    # 1. CHROME / CHROMIUM (Login Data, Web Data, Preferences)
    # ================================================================
    $chromeBases = @(
        "AppData\Local\Google\Chrome\User Data",
        "AppData\Local\Chromium\User Data",
        "AppData\Local\Microsoft\Edge\User Data",
        "AppData\Local\BraveSoftware\Brave-Browser\User Data",
        "AppData\Local\Vivaldi\User Data",
        "AppData\Local\Opera Software\Opera Stable"
    )

    foreach ($chromeRel in $chromeBases) {
        $chromeBase = Join-Path $profilePath $chromeRel
        if (Test-Path $chromeBase) {
            $browser = Split-Path (Split-Path $chromeBase -Parent) -Leaf
            $profilesDirs = Get-ChildItem $chromeBase -Directory -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -match '^(Default|Profile \d+)$' }

            foreach ($profileDir in $profilesDirs) {
                $prefs = Join-Path $profileDir.FullName "Preferences"
                if (Test-Path $prefs) {
                    try {
                        $json = Get-Content $prefs -Raw -ErrorAction SilentlyContinue
                        if ($json -match '"email"\s*:\s*"([^"]+)"') {
                            $text += "  Chrome ($browser/$($profileDir.Name)): $($matches[1])`r`n"
                            $found = $true
                        }
                        if ($json -match '"gaia_id"\s*:\s*"([^"]+)"') {
                            $text += "  Chrome GAIA ID ($browser): $($matches[1])`r`n"
                            $found = $true
                        }
                    } catch {}
                }

                $loginData = Join-Path $profileDir.FullName "Login Data"
                if (Test-Path $loginData) {
                    $text += "  Login Data encontrado ($browser/$($profileDir.Name)): $loginData`r`n"
                    $found = $true
                }
            }
        }
    }

    # ================================================================
    # 2. GOOGLE DRIVE (DriveFS)
    # ================================================================
    $driveFs = Join-Path $profilePath "AppData\Local\Google\DriveFS"

    if (Test-Path $driveFs) {

        $text += "  [Google Drive Detectado]`r`n"
        $found = $true

        $dbs = Get-ChildItem $driveFs -Recurse -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -in ".db",".sqlite" }

        # Cargar driver SQLite si está disponible
        $haveSQLite = $false
        try {
            $null = [System.Data.SQLite.SQLiteConnection]::new('')
            $haveSQLite = $true
        } catch {
            try { Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue; $haveSQLite = $true } catch {}
        }

        foreach ($db in $dbs) {
            $text += "    DB: $($db.FullName)`r`n"

            if (-not $haveSQLite) {
                $text += "    (no se pudo leer SQLite - driver no disponible)`r`n"
                continue
            }

            try {
                $conn = [System.Data.SQLite.SQLiteConnection]::new("Data Source=$($db.FullName);Read Only=True;")
                $conn.Open()
                $cmd = $conn.CreateCommand()

                $tables = @()
                $cmd.CommandText = "SELECT name FROM sqlite_master WHERE type='table'"
                $reader = $cmd.ExecuteReader()
                while ($reader.Read()) { $tables += $reader.GetString(0) }
                $reader.Close()

                if ('accounts' -in $tables) {
                    $cmd.CommandText = "SELECT * FROM accounts"
                    $r2 = $cmd.ExecuteReader()
                    while ($r2.Read()) {
                        for ($i = 0; $i -lt $r2.FieldCount; $i++) {
                            $val = $r2.GetValue($i)
                            if ($val -is [string] -and $val -match $emailRegexG) {
                                $text += "    Email (DB accounts): $val`r`n"
                            }
                        }
                    }
                    $r2.Close()
                }

                if ('data' -in $tables -or 'account' -in $tables) {
                    $target = if ('data' -in $tables) { 'data' } else { 'account' }
                    $cmd.CommandText = "SELECT * FROM [$target]"
                    $r3 = $cmd.ExecuteReader()
                    while ($r3.Read()) {
                        for ($i = 0; $i -lt $r3.FieldCount; $i++) {
                            $val = $r3.GetValue($i)
                            if ($val -is [string] -and $val -match $emailRegexG) {
                                $text += "    Email (DB $target): $val`r`n"
                            }
                        }
                    }
                    $r3.Close()
                }

                $conn.Close()
            } catch {
                $text += "    (no se pudo leer SQLite - cifrada o corrupta)`r`n"
            }
        }

        $logs = Get-ChildItem $driveFs -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in ".log",".txt" }

        foreach ($log in $logs) {
            try {
                $c = Get-Content $log.FullName -Raw -ErrorAction SilentlyContinue

                $accountMatches = [regex]::Matches($c, $emailRegexG)
                foreach ($am in $accountMatches) {
                    $text += "    Email (log): $($am.Value)`r`n"
                }

                if ($c -match "([0-9A-Za-z_-]{20,})") {
                    $text += "    Posible Account ID: $($matches[1])`r`n"
                }

            } catch {}
        }
    }

    if (-not $found) {
        $text += "Sin cuentas Google detectadas`r`n"
    }

    $text += "`r`n"
    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)
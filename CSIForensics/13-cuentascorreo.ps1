
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$outDir = Join-Path $scriptDir "resultados"
$outFile = Join-Path $outDir "013-cuentascorreo.txt"

$utf8 = New-Object System.Text.UTF8Encoding $false

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

[System.IO.File]::WriteAllText(
    $outFile,
    "=== Cuentas de correo $(Get-Date) ===`r`n`r`n",
    $utf8
)

$emailRegex = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

foreach ($p in $profiles) {

    $sid = $p.PSChildName
    $profilePath = (Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue).ProfileImagePath

    if (-not $profilePath) { continue }

    $user = Split-Path $profilePath -Leaf
    $hkUser = "Registry::HKEY_USERS\$sid"

    $foundAccounts = @()

    # ========================================================
    # OUTLOOK CLASSIC (MAPI) - multiples versiones
    # ========================================================
    $outlookVersions = @("16.0", "15.0", "14.0", "12.0", "11.0")

    foreach ($ver in $outlookVersions) {
        $base = "$hkUser\Software\Microsoft\Office\$ver\Outlook\Profiles"
        if (Test-Path $base) {
            try {
                $outProfiles = Get-ChildItem $base -ErrorAction SilentlyContinue
                foreach ($prof in $outProfiles) {
                    $keys = Get-ChildItem $prof.PSPath -Recurse -ErrorAction SilentlyContinue
                    foreach ($k in $keys) {
                        try {
                            $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Value -match $emailRegex) {
                                    $foundAccounts += @{ Source = "Outlook Classic ($ver)"; Email = $matches[0] }
                                }
                            }
                        } catch {}
                    }
                }
            } catch {}
        }
    }

    # Windows Messaging Subsystem perfiles legacy
    $msgPath = "$hkUser\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles"
    if (Test-Path $msgPath) {
        try {
            $msgProfiles = Get-ChildItem $msgPath -ErrorAction SilentlyContinue
            foreach ($prof in $msgProfiles) {
                $keys = Get-ChildItem $prof.PSPath -Recurse -ErrorAction SilentlyContinue
                foreach ($k in $keys) {
                    try {
                        $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
                        foreach ($prop in $props.PSObject.Properties) {
                            if ($prop.Value -match $emailRegex) {
                                $foundAccounts += @{ Source = "Outlook Classic (MAPI)"; Email = $matches[0] }
                            }
                        }
                    } catch {}
                }
            }
        } catch {}
    }

    # ========================================================
    # NEW OUTLOOK / WINDOWS MAIL
    # ========================================================
    $mailAccountsPath = "$hkUser\Software\Microsoft\Windows\CurrentVersion\Mail\Accounts"
    if (Test-Path $mailAccountsPath) {
        try {
            $accts = Get-ChildItem $mailAccountsPath -ErrorAction SilentlyContinue
            foreach ($acct in $accts) {
                try {
                    $props = Get-ItemProperty $acct.PSPath -ErrorAction SilentlyContinue
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Value -match $emailRegex) {
                            $foundAccounts += @{ Source = "New Outlook/Mail"; Email = $matches[0] }
                        }
                    }
                } catch {}
            }
        } catch {}
    }

    # CloudStore (New Outlook, cuentas Microsoft)
    $cloud = "$hkUser\Software\Microsoft\Windows\CurrentVersion\CloudStore"
    if (Test-Path $cloud) {
        try {
            $dump = Get-ChildItem $cloud -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $dump) {
                try {
                    $props = Get-ItemProperty $d.PSPath -ErrorAction SilentlyContinue
                    foreach ($p2 in $props.PSObject.Properties) {
                        if ($p2.Value -is [string] -and $p2.Value -match $emailRegex) {
                            $foundAccounts += @{ Source = "CloudStore (Microsoft)"; Email = $matches[0] }
                        }
                        if ($p2.Value -is [byte[]]) {
                            $text = [System.Text.Encoding]::Unicode.GetString($p2.Value)
                            $cMatches = [regex]::Matches($text, $emailRegex)
                            foreach ($cm in $cMatches) {
                                $foundAccounts += @{ Source = "CloudStore (Microsoft)"; Email = $cm.Value }
                            }
                        }
                    }
                } catch {}
            }
        } catch {}
    }

    # Microsoft Account vinculada al usuario
    $identityCrl = "$hkUser\Software\Microsoft\IdentityCRL"
    if (Test-Path $identityCrl) {
        try {
            $dump = Get-ChildItem $identityCrl -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $dump) {
                $props = Get-ItemProperty $d.PSPath -ErrorAction SilentlyContinue
                foreach ($p2 in $props.PSObject.Properties) {
                    if ($p2.Value -match $emailRegex) {
                        $foundAccounts += @{ Source = "Microsoft Account"; Email = $matches[0] }
                    }
                }
            }
        } catch {}
    }

    # ========================================================
    # NEW OUTLOOK (Outlook para Windows - app modern)
    # ========================================================
    $outlookPkgBase = Join-Path $profilePath "AppData\Local\Packages\Microsoft.OutlookForWindows_*"
    $outlookPkg = Get-ChildItem $outlookPkgBase -Directory -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $outlookPkg) {
        $outlookPkgBase = "C:\Users\$user\AppData\Local\Packages\Microsoft.OutlookForWindows_*"
        $outlookPkg = Get-ChildItem $outlookPkgBase -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if ($outlookPkg) {
        $foundAccounts += @{ Source = "New Outlook (app instalada)"; Email = "(detectada)" }

        # Buscar en subdirectorios específicos con datos de cuentas (JSON, etc.)
        $outlookDataDirs = @(
            "LocalCache\Roaming\outlook",
            "LocalCache\Roaming",
            "Settings",
            "LocalState"
        )
        foreach ($subDir in $outlookDataDirs) {
            $searchPath = Join-Path $outlookPkg.FullName $subDir
            if (Test-Path $searchPath) {
                $jsonFiles = Get-ChildItem $searchPath -Recurse -Include "*.json", "*.txt", "*.dat", "*.log" -File -ErrorAction SilentlyContinue
                foreach ($jf in $jsonFiles) {
                    if ($jf.Length -eq 0 -or $jf.Length -gt 2MB) { continue }
                    try {
                        $content = Get-Content $jf.FullName -Raw -ErrorAction SilentlyContinue
                        if ($content -match $emailRegex) {
                            $nMatches = [regex]::Matches($content, $emailRegex)
                            foreach ($nm in $nMatches) {
                                $foundAccounts += @{ Source = "New Outlook (datos)"; Email = $nm.Value }
                            }
                        }
                    } catch {}
                }
            }
        }

        # Escaneo general de archivos como fallback
        $pkgFiles = Get-ChildItem $outlookPkg.FullName -Recurse -File -ErrorAction SilentlyContinue
        foreach ($pf in $pkgFiles) {
            if ($pf.Length -eq 0 -or $pf.Length -gt 5MB) { continue }
            if ($foundAccounts.Count -ge 20) { break }
            try {
                $bytes = [System.IO.File]::ReadAllBytes($pf.FullName)
                $textUtf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
                if ($textUtf8 -match $emailRegex) {
                    $foundAccounts += @{ Source = "New Outlook (raw)"; Email = $matches[0] }
                }
                $textUni = [System.Text.Encoding]::Unicode.GetString($bytes)
                if ($textUni -match $emailRegex) {
                    $foundAccounts += @{ Source = "New Outlook (raw)"; Email = $matches[0] }
                }
            } catch {}
        }
    }

    # Windows Credential Manager (vaultcmd) para cuentas de Outlook/Microsoft
    try {
        $vault = & vaultcmd /listcreds:"Windows Credentials" /all 2>$null
        if ($vault) {
            $vaultText = $vault -join "`n"
            $vMatches = [regex]::Matches($vaultText, $emailRegex)
            foreach ($vm in $vMatches) {
                $foundAccounts += @{ Source = "Credential Manager"; Email = $vm.Value }
            }
        }
    } catch {}
    try {
        $vault2 = & vaultcmd /listcreds:"Generic Credentials" /all 2>$null
        if ($vault2) {
            $vaultText2 = $vault2 -join "`n"
            $vMatches2 = [regex]::Matches($vaultText2, $emailRegex)
            foreach ($vm in $vMatches2) {
                $foundAccounts += @{ Source = "Credential Manager (generic)"; Email = $vm.Value }
            }
        }
    } catch {}

    # Windows Unistore (Windows Mail / Calendar cache)
    $unistore = Join-Path $profilePath "AppData\Local\Comms\Unistore\data"
    if (Test-Path $unistore) {
        $ucaFiles = Get-ChildItem $unistore -Filter "*.uca" -ErrorAction SilentlyContinue
        foreach ($uf in $ucaFiles) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($uf.FullName)
                $text = [System.Text.Encoding]::Unicode.GetString($bytes)
                $matches = [regex]::Matches($text, $emailRegex)
                foreach ($m in $matches) { $foundAccounts += @{ Source = "Windows Mail/Calendar"; Email = $m.Value } }
            } catch {}
        }
    }

    # ========================================================
    # THUNDERBIRD
    # ========================================================
    $tb = Join-Path $profilePath "AppData\Roaming\Thunderbird"
    if (Test-Path $tb) {
        # Buscar en prefs.js identidades (nota: user_pref con guión bajo, NO userpref)
        $prefsFiles = Get-ChildItem $tb -Recurse -Filter "prefs.js" -ErrorAction SilentlyContinue
        foreach ($f in $prefsFiles) {
            try {
                $content = Get-Content $f.FullName -ErrorAction SilentlyContinue
                foreach ($line in $content) {
                    if ($line -match 'user_pref\("mail\.identity\.\d+\.useremail",\s*"([^"]+)"\)') {
                        $foundAccounts += @{ Source = "Thunderbird"; Email = $matches[1] }
                    }
                    if ($line -match 'user_pref\("mail\.identity\.\d+\.email",\s*"([^"]+)"\)') {
                        $foundAccounts += @{ Source = "Thunderbird"; Email = $matches[1] }
                    }
                }
            } catch {}
        }
        # Fallback: buscar cualquier email en prefs.js si no se encontró por identidad
        if (-not ($foundAccounts | Where-Object { $_.Source -eq "Thunderbird" })) {
            foreach ($f in $prefsFiles) {
                try {
                    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                    $tbMatches = [regex]::Matches($content, $emailRegex)
                    foreach ($m in $tbMatches) {
                        $foundAccounts += @{ Source = "Thunderbird (raw)"; Email = $m.Value }
                    }
                } catch {}
            }
        }
        # Buscar en logins.json credenciales guardadas
        $loginsFiles = Get-ChildItem $tb -Recurse -Filter "logins.json" -ErrorAction SilentlyContinue
        foreach ($f in $loginsFiles) {
            try {
                $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                $loginMatches = [regex]::Matches($content, $emailRegex)
                foreach ($lm in $loginMatches) {
                    $foundAccounts += @{ Source = "Thunderbird (logins)"; Email = $lm.Value }
                }
            } catch {}
        }
    }

    # ========================================================
    # POSTBOX (misma estructura que Thunderbird)
    # ========================================================
    $pb = Join-Path $profilePath "AppData\Roaming\Postbox"
    if (Test-Path $pb) {
        $prefsFiles = Get-ChildItem $pb -Recurse -Filter "prefs.js" -ErrorAction SilentlyContinue
        foreach ($f in $prefsFiles) {
            try {
                $content = Get-Content $f.FullName -ErrorAction SilentlyContinue
                foreach ($line in $content) {
                    if ($line -match 'userpref\("mail\.identity\.\d+\.useremail",\s*"([^"]+)"\)') {
                        $foundAccounts += @{ Source = "Postbox"; Email = $matches[1] }
                    }
                }
            } catch {}
        }
    }

    # ========================================================
    # WINDOWS LIVE MAIL
    # ========================================================
    $wlmail = Join-Path $profilePath "AppData\Local\Microsoft\Windows Live Mail"
    if (Test-Path $wlmail) {
        $oeFiles = Get-ChildItem $wlmail -Recurse -Filter "*.oeaccount" -ErrorAction SilentlyContinue
        foreach ($f in $oeFiles) {
            try {
                $content = Get-Content $f.FullName -ErrorAction SilentlyContinue
                foreach ($line in $content) {
                    if ($line -match 'Email\s*=\s*([^`r`n]+)' -and $matches[1] -match $emailRegex) {
                        $foundAccounts += @{ Source = "Windows Live Mail"; Email = $matches[0] }
                    }
                }
            } catch {}
        }
    }

    $wlReg = "$hkUser\Software\Microsoft\Windows Live Mail"
    if (Test-Path $wlReg) {
        try {
            $props = Get-ItemProperty $wlReg -ErrorAction SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Value -match $emailRegex) {
                    $foundAccounts += @{ Source = "Windows Live Mail (reg)"; Email = $matches[0] }
                }
            }
        } catch {}
    }

    # ========================================================
    # eM CLIENT
    # ========================================================
    $emClient = Join-Path $profilePath "AppData\Roaming\eM Client\Accounts"
    if (Test-Path $emClient) {
        try {
            $accountDirs = Get-ChildItem $emClient -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $accountDirs) {
                $acctXml = Join-Path $dir.FullName "account.xml"
                if (Test-Path $acctXml) {
                    try {
                        $xml = [xml](Get-Content $acctXml -ErrorAction SilentlyContinue)
                        if ($xml.account.email -match $emailRegex) {
                            $foundAccounts += @{ Source = "eM Client"; Email = $xml.account.email }
                        }
                    } catch {}
                }
            }
        } catch {}
    }

    $emReg = "$hkUser\Software\eM Client"
    if (Test-Path $emReg) {
        try {
            $dump = Get-ChildItem $emReg -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $dump) {
                $props = Get-ItemProperty $d.PSPath -ErrorAction SilentlyContinue
                foreach ($p2 in $props.PSObject.Properties) {
                    if ($p2.Value -match $emailRegex) {
                        $foundAccounts += @{ Source = "eM Client (reg)"; Email = $matches[0] }
                    }
                }
            }
        } catch {}
    }

    # ========================================================
    # FOXMAIL
    # ========================================================
    $foxmail = Join-Path $profilePath "AppData\Roaming\Foxmail\Accounts"
    if (Test-Path $foxmail) {
        try {
            $dataFiles = Get-ChildItem $foxmail -Recurse -File -ErrorAction SilentlyContinue
            foreach ($df in $dataFiles) {
                try {
                    $content = Get-Content $df.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content -match $emailRegex) {
                        $foundAccounts += @{ Source = "Foxmail"; Email = $matches[0] }
                    }
                } catch {}
            }
        } catch {}
    }

    $foxReg = "$hkUser\Software\Aerofox\Foxmail"
    if (Test-Path $foxReg) {
        try {
            $props = Get-ItemProperty $foxReg -ErrorAction SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Value -match $emailRegex) {
                    $foundAccounts += @{ Source = "Foxmail (reg)"; Email = $matches[0] }
                }
            }
        } catch {}
    }

    # ========================================================
    # MAILBIRD
    # ========================================================
    $mailbird = Join-Path $profilePath "AppData\Roaming\Mailbird\Accounts"
    if (Test-Path $mailbird) {
        try {
            $acctFiles = Get-ChildItem $mailbird -Recurse -Filter "*.json" -ErrorAction SilentlyContinue
            foreach ($f in $acctFiles) {
                try {
                    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content -match $emailRegex) {
                        $foundAccounts += @{ Source = "Mailbird"; Email = $matches[0] }
                    }
                } catch {}
            }
        } catch {}
    }

    # ========================================================
    # THE BAT!
    # ========================================================
    $theBat = Join-Path $profilePath "AppData\Roaming\The Bat!"
    if (Test-Path $theBat) {
        try {
            $acctFiles = Get-ChildItem $theBat -Recurse -Filter "*.ini" -ErrorAction SilentlyContinue
            foreach ($f in $acctFiles) {
                try {
                    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue
                    foreach ($line in $content) {
                        if ($line -match "EmailAddress\s*=\s*(.+)" -and $matches[1] -match $emailRegex) {
                            $foundAccounts += @{ Source = "The Bat!"; Email = $matches[0] }
                        }
                    }
                } catch {}
            }
        } catch {}
    }

    $batReg = "$hkUser\Software\RIT\The Bat!"
    if (Test-Path $batReg) {
        try {
            $props = Get-ItemProperty $batReg -ErrorAction SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Value -match $emailRegex) {
                    $foundAccounts += @{ Source = "The Bat! (reg)"; Email = $matches[0] }
                }
            }
        } catch {}
    }

    # ========================================================
    # OUTPUT
    # ========================================================
    $foundAccounts = $foundAccounts | Select-Object Source, Email -Unique | Sort-Object Source, Email

    $text = "Usuario: $user`r`nSID: $sid`r`n----------------------`r`n"

    if ($foundAccounts.Count -gt 0) {
        $currentSource = ""
        foreach ($acc in $foundAccounts) {
            if ($acc.Source -ne $currentSource) {
                $text += "`r`n[$($acc.Source)]`r`n"
                $currentSource = $acc.Source
            }
            $text += "  $($acc.Email)`r`n"
        }
        $text += "`r`n"
    }
    else {
        $text += "Sin cuentas de correo visibles`r`n`r`n"
    }

    [System.IO.File]::AppendAllText($outFile, $text, $utf8)
}

[System.IO.File]::AppendAllText(
    $outFile,
    "`r`n=== Fin ===`r`n",
    $utf8
)

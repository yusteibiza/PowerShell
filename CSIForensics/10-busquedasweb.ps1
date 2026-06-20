if (!(Test-Path ".\resultados")) {
    New-Item -ItemType Directory ".\resultados" -Force | Out-Null
}

$sqlite = ".\sqlite3.exe"

# ==========================
# EDGE
# ==========================
$edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"

if (Test-Path $edge) {
    Copy-Item $edge ".\resultados\edge.db" -Force

    & $sqlite ".\resultados\edge.db" `
    "SELECT url,
            title,
            datetime((last_visit_time/1000000)-11644473600,'unixepoch','localtime') as Fecha
     FROM urls
     ORDER BY last_visit_time DESC
     LIMIT 50;" | Out-File ".\resultados\0101-sitiosweb_edge.txt" -Encoding utf8
}

# ==========================
# CHROME
# ==========================
$chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"

if (Test-Path $chrome) {
    Copy-Item $chrome ".\resultados\chrome.db" -Force

    & $sqlite ".\resultados\chrome.db" `
    "SELECT url,
            title,
            datetime((last_visit_time/1000000)-11644473600,'unixepoch','localtime') as Fecha
     FROM urls
     ORDER BY last_visit_time DESC
     LIMIT 50;" | Out-File ".\resultados\0102-sitiosweb_chrome.txt" -Encoding utf8
}

# ==========================
# FIREFOX
# ==========================
$ffProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue |
             Select-Object -First 1

if ($ffProfile) {
    $ffdb = "$($ffProfile.FullName)\places.sqlite"

    if (Test-Path $ffdb) {
        Copy-Item $ffdb ".\resultados\firefox.db" -Force

        & $sqlite ".\resultados\firefox.db" `
        "SELECT url,
                title,
                datetime(last_visit_date/1000000,'unixepoch','localtime') as Fecha
         FROM moz_places
         ORDER BY last_visit_date DESC
         LIMIT 50;" | Out-File ".\resultados\0103-sitiosweb_firefox.txt" -Encoding utf8
    }
}
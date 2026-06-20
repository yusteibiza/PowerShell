$paths = @(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

Get-ItemProperty $paths |
Where-Object {
    $_.DisplayName -match "Chrome|Edge|Firefox|Opera|Brave|Vivaldi|Safari"
} |
Select-Object DisplayName, DisplayVersion, Publisher |
Out-File ".\resultados\08-navegadores.txt" -Encoding utf8
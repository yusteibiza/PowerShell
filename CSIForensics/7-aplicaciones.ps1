$paths = @(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty $paths |
Where-Object DisplayName |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Sort-Object DisplayName |
Out-File ".\resultados\07-aplicaciones.txt" -Encoding utf8
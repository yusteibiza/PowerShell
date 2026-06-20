Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074} |
Select-Object -First 1 TimeCreated |
Out-File ".\resultados\05-fechaapagado.txt" -Encoding utf8
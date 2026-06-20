Get-CimInstance Win32_ComputerSystem | Select-Object UserName |
Out-File ".\resultados\04-ultimousuario.txt" -Encoding utf8
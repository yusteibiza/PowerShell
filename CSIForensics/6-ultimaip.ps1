Get-NetIPAddress -AddressFamily IPv4 |
Where-Object {$_.IPAddress -notlike "169.*"} |
Select-Object IPAddress, InterfaceAlias |
Out-File ".\resultados\06-ultimaip.txt" -Encoding utf8
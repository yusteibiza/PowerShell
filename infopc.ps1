### Script para sacar información del equipo
### mediante WinSat

echo "`nInformación del equipo" "".PadLeft(22, '-') $(Get-CimInstance Win32_WinSAT | 
    Select-Object CPUScore, MemoryScore, GraphicsScore, D3DScore, DiskScore | Format-List)
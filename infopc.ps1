### Script para sacar información del equipo
### mediante WinSat

[string]$res = Get-CimInstance Win32_WinSAT | 
    Select-Object CPUScore,
    MemoryScore,
    GraphicsScore,
    D3DScore,
    DiskScore
    | Format-List | Out-String

$individual = Get-CimInstance Win32_WinSAT

#[string]$procesador = Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name
$placabase = Get-CimInstance Win32_BaseBoard | Select-Object -Property Manufacturer, Product
[string]$procesador = (Get-CimInstance Win32_Processor).Name
[string]$velocidad = (Get-CimInstance Win32_Processor).MaxClockSpeed
[string]$video = (Get-CimInstance Win32_VideoController).Description
[string]$memoria = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
$memoria = [math]::Round($memoria/1GB,2)
[string]$velmemoria = (Get-CimInstance Win32_physicalmemory).Speed[0]

clear

Write-Host "`n " -NoNewLine
Write-Host "".PadLeft(22, '-') -ForegroundColor Cyan
Write-Host " Información del equipo" -ForegroundColor Cyan
Write-Host " " -NoNewLine
Write-Host "".PadLeft(22, '-') -ForegroundColor Cyan

### INFORMACION CABECERA ###
Write-Host "`n   * Placa Base ..: $($placabase.Manufacturer) / $($placabase.Product)" -ForegroundColor Blue
Write-Host "   * Procesador ..: $procesador" -ForegroundColor Blue
Write-Host "   * Velocidad ...: $velocidad Mhz" -ForegroundColor Blue
Write-Host "   * Gráfica .....: $video" -ForegroundColor Blue
Write-Host "   * Memoria RAM .: $memoria GB / $velmemoria Mhz" -ForegroundColor Blue

### PUNTUACION WINSAT ###
Write-Host "`n   - Puntuación del procesador ..: " -ForegroundColor DarkGray -NonewLine
Write-Host $($individual.CPUScore) -ForegroundColor white
Write-Host "   - Puntuación de la memoria ...: " -ForegroundColor DarkGray -NonewLine
Write-Host $($individual.MemoryScore) -ForegroundColor white
Write-Host "   - Puntuación de los gráficos .: " -ForegroundColor DarkGray -NonewLine
Write-Host $($individual.GraphicsScore) -ForegroundColor white
Write-Host "   - Puntuación Direct 3D .......: " -ForegroundColor DarkGray -NonewLine
Write-Host $($individual.D3DScore) -ForegroundColor white
Write-Host "   - Puntuación del disco .......: " -ForegroundColor DarkGray -NonewLine
Write-Host $($individual.DiskScore)`n -ForegroundColor white

# Write-Host $res


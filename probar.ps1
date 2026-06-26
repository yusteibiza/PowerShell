Add-Type -Path ".\LibreHardwareMonitorLib.dll"

$computer = New-Object LibreHardwareMonitor.Hardware.Computer
$computer.IsCpuEnabled = $true
$computer.Open()

$computer.Hardware | ForEach-Object { $_.HardwareType }

Add-Type -Path ".\LibreHardwareMonitorLib.dll"

$computer = New-Object LibreHardwareMonitor.Hardware.Computer
$computer.IsCpuEnabled = $true
$computer.IsMemoryEnabled = $true
$computer.IsGpuEnabled = $true

$computer.Open()

while ($true) {

    Clear-Host

    foreach ($hw in $computer.Hardware) {

        $hw.Update()

        foreach ($sub in $hw.SubHardware) {
            $sub.Update()
        }

        if ($hw.HardwareType -eq "Cpu") {

            Write-Host "===== CPU ====="

            foreach ($sensor in $hw.Sensors) {

                if ($sensor.Value -ne $null) {

                    if ($sensor.SensorType -eq "Load") {
                        Write-Host ("Uso CPU: {0} %" -f [math]::Round($sensor.Value, 2))
                    }

                    if ($sensor.SensorType -eq "Clock") {
                        Write-Host ("Frecuencia: {0} MHz - {1}" -f `
                            [math]::Round($sensor.Value, 0), $sensor.Name)
                    }

                    if ($sensor.SensorType -eq "Temperature") {
                        Write-Host ("Temp CPU: {0} °C" -f [math]::Round($sensor.Value, 1))
                    }
                }
            }
        }

        if ($hw.HardwareType -eq "Memory") {

            Write-Host "`n===== RAM ====="

            foreach ($sensor in $hw.Sensors) {

                if ($sensor.SensorType -eq "Data") {
                    Write-Host ("RAM: {0} GB" -f [math]::Round($sensor.Value, 2))
                }
            }
        }
    }

    Start-Sleep 1
}
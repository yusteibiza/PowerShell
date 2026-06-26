Write-Host "".PadLeft(55, "-")
Write-Host "Velocidad actual / máxima / porcentage de uso de la CPU"
Write-Host "".PadLeft(55, "-")

       
while ($true) {
    $cpu = Get-CimInstance Win32_Processor

    $current = $cpu.CurrentClockSpeed
    $max = $cpu.MaxClockSpeed
    $percent = $cpu.LoadPercentage
    $percent = ([string]::IsNullOrEmpty($percent) ? "0,5" : $percent)
    if ($percent -eq 0) { $percent = "0,5" }
    
    $dot = if ($percent -lt 30) { "🟢" }
           elseif ($percent -lt 70) { "🟡" }
           else { "🔴" }

    $fecha = (Get-Date).ToString("HH:MM:ss")
            
    Write-Host "$dot [$fecha] <> CPU ACTUAL: [$current MHz] / CPU MAX: [$max MHz] / [$percent%] de uso"
    Start-Sleep 1
}

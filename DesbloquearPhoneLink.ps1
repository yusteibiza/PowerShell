# Ejecutar como administrador

Write-Host "1. Cerrando procesos de Phone Link..." -ForegroundColor Cyan
Get-Process *YourPhone* -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "2. Reactivando servicios esenciales..." -ForegroundColor Cyan
$services = @("DiagTrack", "dmwappushsvc")
foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Set-Service -Name $svc -StartupType Automatic
        Start-Service -Name $svc
        Write-Host "Servicio $svc activado y en ejecución."
    } else {
        Write-Host "Servicio $svc no encontrado."
    }
}

Write-Host "3. Limpiando políticas de AppX que puedan bloquear Phone Link..." -ForegroundColor Cyan
$AppxPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
if (Test-Path $AppxPolicyKey) {
    # Hacer backup primero
    $backupPath = "$env:USERPROFILE\AppxPolicyBackup.reg"
    reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" $backupPath /y
    Write-Host "Backup de la clave de políticas guardado en $backupPath"
    
    # Borrar claves que bloqueen apps UWP
    Remove-ItemProperty -Path $AppxPolicyKey -Name "AllowAllTrustedApps" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $AppxPolicyKey -Name "BlockUWP" -ErrorAction SilentlyContinue
    Write-Host "Políticas de bloqueo de apps UWP eliminadas (si existían)."
} else {
    Write-Host "No se encontraron políticas de AppX."
}

Write-Host "4. Registrando/reparando Phone Link..." -ForegroundColor Cyan
Get-AppxPackage -AllUsers Microsoft.YourPhone | ForEach-Object {
    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
}

Write-Host "5. Configurando permisos de Phone Link..." -ForegroundColor Cyan
$PhoneLinkSettingsPath = "HKCU:\Software\Microsoft\PhoneExperience"
if (-Not (Test-Path $PhoneLinkSettingsPath)) { New-Item -Path $PhoneLinkSettingsPath -Force }
Set-ItemProperty -Path $PhoneLinkSettingsPath -Name "EnableBackgroundActivity" -Value 1 -Force
Set-ItemProperty -Path $PhoneLinkSettingsPath -Name "EnableNotifications" -Value 1 -Force

Write-Host "✅ Script finalizado. Reinicia el PC e intenta abrir Phone Link como administrador." -ForegroundColor Green

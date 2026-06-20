# Ejecutar como Administrador
Write-Host "Reparando Windows Update..." -ForegroundColor Cyan

# Detener servicios relacionados
Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptsvc -Force -ErrorAction SilentlyContinue
Stop-Service -Name msiserver -Force -ErrorAction SilentlyContinue

# Eliminar caché de Windows Update
Write-Host "Eliminando caché de Windows Update..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

# Reiniciar servicios BITS y Windows Update
Write-Host "Reiniciando servicios..." -ForegroundColor Yellow
Start-Service -Name cryptsvc
Start-Service -Name bits
Start-Service -Name msiserver
Start-Service -Name wuauserv

# Re-registrar DLLs críticas de Windows Update
Write-Host "Re-registrando componentes DLL..." -ForegroundColor Yellow
$Dlls = @(
    "atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll",
    "jscript.dll","vbscript.dll","scrrun.dll","msxml.dll","msxml3.dll",
    "msxml6.dll","actxprxy.dll","softpub.dll","wintrust.dll","dssenh.dll",
    "rsaenh.dll","gpkcsp.dll","sccbase.dll","slbcsp.dll","cryptdlg.dll",
    "oleaut32.dll","ole32.dll","shell32.dll","initpki.dll","wuapi.dll",
    "wuaueng.dll","wuaueng1.dll","wucltui.dll","wups.dll","wups2.dll",
    "wuweb.dll","qmgr.dll","qmgrprxy.dll","wucltux.dll","muweb.dll",
    "wuwebv.dll"
)

foreach ($Dll in $Dlls) {
    try {
        regsvr32.exe /s $Dll
    } catch {
        Write-Host "Error al registrar $Dll" -ForegroundColor Red
    }
}

# Resetear configuración de red (Winsock + proxy)
Write-Host "Restableciendo Winsock y configuración de red..." -ForegroundColor Yellow
netsh winsock reset
netsh winhttp reset proxy

# Forzar nueva detección de actualizaciones
Write-Host "Forzando nueva detección de actualizaciones..." -ForegroundColor Yellow
wuauclt /resetauthorization /detectnow

Write-Host "Reparación de Windows Update completada." -ForegroundColor Green
Pause

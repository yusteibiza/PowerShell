@echo off
cls
chcp 65001 > nul
color 0E

echo             CSI FORENSICS
echo   ^/--------------------------------^\
echo   ^| Ejecutando herramienta forense ^| 
echo   ^|      ...se realizarán 20 pasos ^| 
echo   ^\--------------------------------^/
echo.   
echo   - Espere por favor...
echo.

echo [*] Paso  1 - Obteniendo información de discos...
powershell .\1-hashdiscos.ps1

echo [*] Paso  2 - Obteniendo información del sistema..
powershell .\2-so.ps1

echo [*] Paso  3 - Obteniendo información de usuarios...
powershell .\3-usuarios.ps1

echo [*] Paso  4 - Obteniendo información del último usuario que inició sesión...
powershell .\4-ultimousuario.ps1

echo [*] Paso  5 - Obteniendo información de la última fecha del apagado del sistema...
powershell .\5-fechaapagado.ps1

echo [*] Paso  6 - Obteniendo la última dirección IP asignada al sistema...
powershell .\6-ultimaip.ps1

echo [*] Paso  7 - Obteniendo aplicaciones instaladas...
powershell .\7-aplicaciones.ps1

echo [*] Paso  8 - Obteniendo navegadores web instalados...
powershell .\8-navegadores.ps1

echo [*] Paso  9 - Obteniendo la lista de los sitios web accedidos...
powershell .\9-sitiosweb.ps1
del .\resultados\*.db > nul

echo [*] Paso 10 - Obteniendo la lista búsquedas en la web...
powershell .\10-busquedasweb.ps1
del .\resultados\*.db > nul

echo [*] Paso 11 - Obteniendo la lista búsquedas en el explorador de Windows...
powershell .\11-busquedasexplorer.ps1

echo [*] Paso 12 - Obteniendo la aplicaciún de correo predeterminada...
powershell .\12-appcorreo.ps1

echo [*] Paso 13 - Obteniendo las cuentas de correo configuradas...
powershell .\13-cuentascorreo.ps1

echo [*] Paso 14 - Obteniendo los dispositivos externos que se conectaron al sistema...
powershell .\14-dispexternos.ps1

echo [*] Paso 15 - Obteniendo la lista de unidades de red compartidas...
powershell .\15-unidadesred.ps1

echo [*] Paso 16 - Obteniendo la lista de archivos abiertos en la red...
powershell .\16-archivosredabiertos.ps1

echo [*] Paso 17 - Obteniendo la cuenta de Google Drive...
powershell .\17-cuentagoogle.ps1

echo [*] Paso 18 - Obteniendo las marcas de tiempo archivos de renuncia DOCX en el escritorio...
powershell .\18-marcasdocx.ps1

echo [*] Paso 19 - Cuando se imprimió un archivo DOCX de renuncia...
powershell .\19-impdocxrenuncia.ps1

echo [*] Paso 20 - Notas Sticky Note...
powershell .\20-notas.ps1

echo.
echo --- FIN DEL ANÁLISIS ---
echo.
echo - Los resultados han sido guardados en .\resultados
echo   Cada paso ha creado un archivo con la información resultante
echo.

exit

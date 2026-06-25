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

pwsh -Command "Remove-Item .\resultados\* -Recurse -Force"

echo [*] Paso  1 - Obteniendo información de discos...
pwsh .\1-hashdiscos.ps1

echo [*] Paso  2 - Obteniendo información del sistema..
pwsh .\2-so.ps1

echo [*] Paso  3 - Obteniendo información de usuarios...
pwsh .\3-usuarios.ps1

echo [*] Paso  4 - Obteniendo información del último usuario que inició sesión...
pwsh .\4-ultimousuario.ps1

echo [*] Paso  5 - Obteniendo información de la última fecha del apagado del sistema...
pwsh .\5-fechaapagado.ps1

echo [*] Paso  6 - Obteniendo la última dirección IP asignada al sistema...
pwsh .\6-ultimaip.ps1

echo [*] Paso  7 - Obteniendo aplicaciones instaladas...
pwsh .\7-aplicaciones.ps1

echo [*] Paso  8 - Obteniendo navegadores web instalados...
pwsh .\8-navegadores.ps1

echo [*] Paso  9 - Obteniendo la lista de los sitios web accedidos...
pwsh .\9-sitiosweb.ps1
del .\resultados\*.db > nul

echo [*] Paso 10 - Obteniendo la lista búsquedas en la web...
pwsh .\10-busquedasweb.ps1
del .\resultados\*.db > nul

echo [*] Paso 11 - Obteniendo la lista búsquedas en el explorador de Windows...
pwsh .\11-busquedasexplorer.ps1

echo [*] Paso 12 - Obteniendo la aplicación de correo predeterminada...
pwsh .\12-appcorreo.ps1

echo [*] Paso 13 - Obteniendo las cuentas de correo configuradas...
pwsh .\13-cuentascorreo.ps1

echo [*] Paso 14 - Obteniendo los dispositivos externos que se conectaron al sistema...
pwsh .\14-dispexternos.ps1

echo [*] Paso 15 - Obteniendo la lista de unidades de red compartidas...
pwsh .\15-unidadesred.ps1

echo [*] Paso 16 - Obteniendo la lista de archivos abiertos en la red...
pwsh .\16-archivosredabiertos.ps1

echo [*] Paso 17 - Obteniendo la cuenta de Google Drive...
pwsh .\17-cuentagoogle.ps1

echo [*] Paso 18 - Obteniendo las marcas de tiempo archivos de renuncia DOCX en el escritorio...
pwsh .\18-marcasdocx.ps1

echo [*] Paso 19 - Cuando se imprimió un archivo DOCX de renuncia...
pwsh .\19-impdocxrenuncia.ps1

echo [*] Paso 20 - Notas Sticky Note...
pwsh .\20-notas.ps1

echo.
echo --- FIN DEL ANÁLISIS ---
echo.
echo - Los resultados han sido guardados en .\resultados
echo   Cada paso ha creado un archivo con la información resultante
echo.

exit

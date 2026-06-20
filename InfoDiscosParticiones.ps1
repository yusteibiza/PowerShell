# Exportar info de discos, particiones y Volumen UID (como Disk2VHD)
$salida = @()

Get-Disk | Sort-Object Number | ForEach-Object {
    $disco = $_
    $uidDisco = if ($disco.PartitionStyle -eq 'MBR') { $disco.Signature } else { $disco.Guid }
    if (-not $uidDisco) { $uidDisco = "N/A" }

    $salida += "================================= [ Disco $($disco.Number) ] ================================="
    $salida += ("{0,-25} : {1}" -f "Número de disco", $disco.Number)
    $salida += ("{0,-24} : {1}" -f "Fabricante", $disco.Manufacturer)
    $salida += ("{0,-24} : {1}" -f "Modelo", $disco.Model)
    $salida += ("{0,-25} : {1:N2} GB" -f "Tamaño del disco", [math]::Round([double]$disco.Size/1GB,2))
    $salida += ("{0,-24} : {1}" -f "UID del disco", $uidDisco)
    $salida += ""

    Get-Partition -DiskNumber $disco.Number | Sort-Object PartitionNumber | ForEach-Object {
        $part = $_
        $vol  = Get-Volume -Partition $part -ErrorAction SilentlyContinue

        $uidPart = if ($part.GptType) { $part.GptType } else { $part.PartitionNumber }
        if (-not $uidPart) { $uidPart = "N/A" }

        $driveLetter = if ($vol) { $vol.DriveLetter } else { "Sin letra" }
        $fs          = if ($vol) { $vol.FileSystem } else { "N/A" }
        $volGuid     = if ($vol) { $vol.UniqueId } else { "N/A" }   # UID como Disk2VHD

        $salida += ("{0,-26} : {1}" -f "Número de partición", $part.PartitionNumber)
        $salida += ("{0,-26} : {1:N2} GB" -f "Tamaño de la partición", [math]::Round([double]$part.Size/1GB,2))
        $salida += ("{0,-25} : {1}" -f "UID de la partición", $uidPart)
        $salida += ("{0,-24} : {1}" -f "Letra de unidad", $driveLetter)
        $salida += ("{0,-24} : {1}" -f "Sistema de archivos", $fs)
        $salida += ("{0,-24} : {1}" -f "Volume UID", $volGuid)   # <--- igual al de Disk2VHD
        $salida += ""
    }
}

# Guardar en ANSI
$salida | Out-File -FilePath "infodiscos.txt" -Encoding default 

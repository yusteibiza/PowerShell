$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

[PSCustomObject]@{
    Equipo              = $cs.Name
    Sistema             = $os.Caption
    Version             = $os.Version
    Build               = $os.BuildNumber
    Arquitectura        = $os.OSArchitecture
    FechaInstalacion    = $os.InstallDate
    UltimoArranque      = $os.LastBootUpTime
    Propietario         = $os.RegisteredUser
    Fabricante          = $cs.Manufacturer
    Modelo              = $cs.Model
} | Out-File ".\resultados\02-info_sistema.txt" -Encoding utf8
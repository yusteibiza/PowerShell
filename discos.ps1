# ===============================
# 📏 CENTRADO GENERAL
# ===============================
$width = $Host.UI.RawUI.WindowSize.Width

function Write-Centered {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White"
    )

    $padding = [math]::Max(0, [math]::Floor(($width - $Text.Length) / 2))
    Write-Host ((" " * $padding) + $Text) -ForegroundColor $Color
}

# ===============================
# 🧹 CABECERA
# ===============================
Clear-Host

Write-Centered "════════════════════════════════════════════" DarkCyan
Write-Centered "🖥 INFORMACIÓN DE DISCOS DEL SISTEMA 🖥" Yellow
Write-Centered "════════════════════════════════════════════" DarkCyan
Write-Centered "Centro de Software Ibiza" Green
Write-Centered ("Fecha: " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss")) Cyan
Write-Centered "════════════════════════════════════════════" DarkCyan
Write-Host ""

# ===============================
# 💾 INFORMACIÓN DE DISCOS
# ===============================

Get-Disk |
Sort-Object Number |
ForEach-Object {

    $disk = $_

    # 🔧 Nombre estilo Windows API
    $windowsPath = "\\.\PHYSICALDRIVE$($disk.Number)"

    Get-Partition -DiskNumber $disk.Number | ForEach-Object {

        $partition = $_
        $volume = Get-Volume -Partition $partition -ErrorAction SilentlyContinue

        # 🔹 Partition alineado izquierda
        $partitionLeft = ("{0}" -f $partition.PartitionNumber).PadRight(5)

        # 🔹 DriveLetter seguro
        $driveLetter = if ($partition.DriveLetter) {
            [string]$partition.DriveLetter
        } else {
            "-"
        }

        $driveLeft = $driveLetter.PadRight(3)

        # 🔹 Serial limpio
        $serial = if ($disk.SerialNumber) {
            ($disk.SerialNumber -replace '\s','').Trim()
        } else {
            "-"
        }

        [PSCustomObject]@{
            DiskNumber      = $disk.Number
            WindowsPath     = $windowsPath   # 👈 NUEVO
            DiskModel       = $disk.FriendlyName
            SerialNumber    = $serial
            UniqueId        = $disk.UniqueId
            BusType         = $disk.BusType
            Partition       = $partitionLeft
            DriveLetter     = $driveLeft
            Label           = $volume.FileSystemLabel
            FileSystem      = $volume.FileSystem
            SizeGB          = [math]::Round($partition.Size / 1GB, 2)
        }
    }
} | Format-Table -AutoSize
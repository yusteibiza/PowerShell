#############################
## ESC[?25l	ocultar cursor ##
## ESC[?25h	mostrar cursor ##
#############################

$color = ""

Write-Host "`nPrueba de bucle for...`n" -foreground green

for ($i = 1; $i -le 100; $i++) {
    $color = "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
    "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White" | Get-Random
    
    if ($i -eq 100) {
        Write-Host "`e[?25l$i`n" -NoNewline -foreground $color;
        Start-Sleep 0.1
    } else {
        Write-Host "`e[?25l$i, " -NoNewline -foreground $color;
    }

    Start-Sleep 0.1
} 

Write-Host "`e[?25h"


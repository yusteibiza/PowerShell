#############################
## ESC[?25l	ocultar cursor ##
## ESC[?25h	mostrar cursor ##
#############################

param(
    [int]$inicio = 1,
    [int]$fin = 100,
    [int]$delay = 50
)

if ($inicio -gt $fin){
    Write-Host "`nEl valor final debe de ser mayor o igual al inicial`n" -foreground red
    return
}

$color = "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White"

clear
Write-Host "`nPrueba de bucle for...`n" -foreground white

for ($i = $inicio; $i -le $fin; $i++) {
    $c = Get-Random $color
    
    if ($i -eq $fin) {
        Write-Host "`e[?25l$i`n" -NoNewline -foreground $c;
        Start-Sleep 0.1
    } else {
        Write-Host "`e[?25l$i" -NoNewline -foreground $c;
        Write-Host ", " -NoNewline -foreground white
    }

    Start-Sleep -Milliseconds $delay
} 

Write-Host "`e[?25h"


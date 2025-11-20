# Utility script for executing the same command in multiple parallel threads.

param(
    [int]$Requests = 10
)

$command = { curl.exe -s http://localhost:8080/products/1/priceHistory > $null }

Write-Host ""

# Capturar el proceso de PowerShell actual para medir CPU
$process = Get-Process -Id $PID

# Medir tiempo real
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $Requests; $i++) {
    Write-Host "Sending request..."
    Start-Job $command | Out-Null
    Start-Sleep -Milliseconds 100
}

# Esperar a que terminen todos los jobs
Get-Job | Wait-Job | Receive-Job
Remove-Job *

$stopwatch.Stop()

# Obtener estadísticas de CPU del proceso
$process.Refresh()
$userTime = [TimeSpan]::FromTicks($process.UserProcessorTime.Ticks)
$sysTime = [TimeSpan]::FromTicks($process.PrivilegedProcessorTime.Ticks)

# Mostrar estadísticas en formato similar a time
Write-Host ""
Write-Host "real $($stopwatch.Elapsed.ToString('m\mss\.fff\s'))"
Write-Host "user $($userTime.ToString('m\mss\.fff\s'))"
Write-Host "sys  $($sysTime.ToString('m\mss\.fff\s'))"
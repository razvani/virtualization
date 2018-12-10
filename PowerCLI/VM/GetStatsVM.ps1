Get-VM | Where {$_.PowerState -eq "PoweredOn"} | Select Name, NumCpu, MemoryMB, `
@{N="CPU Usage (Max), %" ; E={[Math]::Round((($_ | Get-Stat -Stat cpu.usage.average -Start (Get-Date).AddDays(-7) -Finish (Get-Date) | Measure-Object Value -Maximum).Maximum),2)}}, `
@{N="Memory Usage (Max), %" ; E={[Math]::Round((($_ | Get-Stat -Stat mem.usage.average -Start (Get-Date).AddDays(-7) -Finish (Get-Date) | Measure-Object Value -Maximum).Maximum),2)}} |`
Export-Csv -Path "./ECCBEHAVC02.eccmgmt.local.csv"



Import-Csv ".\MigrateVMsDistributed2StandardSwitch.csv" | ForEach-Object {

# ESXi host
$VM = Get-VM -Name $_.Server 

Get-VM -Name $_.Server | Get-NetworkAdapter | Select Name, NetworkName | ForEach-Object {

# Get the port group from standard switch
$StdPortgroupToUse = Get-VirtualPortgroup -VMHost $VM.VMHost -Standard -Name $_.NetworkName
# Change network adapter port group from distributed switch to standard switch
Get-NetworkAdapter -VM $VM -Name $_.Name | Set-NetworkAdapter -Portgroup $StdPortgroupToUse -Confirm:$false

}

}
$ImportFile = '.\ServerList.csv'


Import-csv $ImportFile | ForEach-Object {

$Name = $_.Hostname
Get-VM | Where {$_.Name -contains $Name} | Select Name, VMHost

}

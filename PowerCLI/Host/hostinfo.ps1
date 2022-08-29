Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Set-Location $PSScriptRoot

$cred = Get-Credentials

Connect-VIServer -Server sharbehavcsa101.cegekavirtual.local -Credential -AllLinked

$BladeCINumber = @{Name = "CI-nr Blade"; expr = {$_.CustomFields.Item("CI-nr Blade")}}
$ClusterCINumber = @{Name = "CI-nr Cluster"; expr = {$_.CustomFields.Item("CI-nr Cluster")}}
$HostExport = Get-VMHost | select Name, Parent, $BladeCINumber, $ClusterCINumber #If only a set of VMHosts is needed e.g. per DC use Get-Datacenter -Name *SHAR* | Get-VMhost | ...

$HostExport | Export-Csv ".\VMhostInfo.csv" -NoTypeInformation

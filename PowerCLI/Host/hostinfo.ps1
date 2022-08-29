Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Set-Location $PSScriptRoot

$cred = Get-Credentials

Connect-VIServer -Server sharbehavcsa101.cegekavirtual.local -Credential -AllLinked

$BladeCINumber = @{Name = "CI-nr Blade"; expr = {$_.CustomFields.Item("CI-nr Blade")}}
$ClusterCINumber = @{Name = "CI-nr Cluster"; expr = {$_.CustomFields.Item("CI-nr Cluster")}}
$HostExport = Get-Datacenter *SHAR* | Get-VMHost | select Name, Parent, $BladeCINumber, $ClusterCINumber

$HostExport | Export-Csv ".\VMhostInfo.csv" -NoTypeInformation

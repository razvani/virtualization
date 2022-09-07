#################################################################################
# This script is created for configuring SNMP on multiple ESXi hosts
# Parameters:
#
# CSV file
$CSVfile = 'ESXiHosts.csv' #Default name for CSV input file ## CSV header: Name
$CSVfileDelimiter = ','
#
# Community strings
$snmpString1 = "public"
$twoStrings = True       #Set to 'False' if you want to set just one string
$snmpString2 = "secondstring"  #Secure string (should be in PIM)
#
#################################################################################

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Importing VMWare.VimAutomation.Core module
Write-Host -ForegroundColor Green "`r`nImporting VMware PowerCLI module..."
Import-Module -Name VMWare.VimAutomation.Core

# Set location the same as the folder where the current script is located
Set-Location $PSScriptRoot

# Importing CSV file that contains the ESXi hosts FQDN.
$DataFile = $CSVfile | %{ If($Entry = Read-Host "`r`nInput the name of the import CSV file ($_)"){$Entry} Else {$_} }
Write-Host -ForegroundColor Yellow "Importing CSV file $DataFile"
$ESXiHosts = Import-Csv -Path $DataFile -Delimiter $CSVfileDelimiter
Write-Host ($ESXiHosts | Measure-Object).count "ESXi hosts to process!"

$ESXiCredentials = Get-Credential -Message "Please enter the ESXi host account credentials."

# Setting the SNMP community string on each host.
ForEach ($ESXiHost in $ESXiHosts){
	Write-Host -ForegroundColor Yellow "`r`nConnecting to" $ESXiHost.Name
   	Connect-VIServer $ESXiHost.Name -Credential $ESXiCredentials
	
	if ($twoStrings) {
		Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$True -ReadOnlyCommunity $snmpString1, $snmpString2
	} else {
		Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$True -ReadOnlyCommunity $snmpString1
	}
	
	#Get-VMHostSnmp | Select ReadOnlyCommunities, Enabled
	Disconnect-VIServer -Server * -Force -Confirm:$False
}

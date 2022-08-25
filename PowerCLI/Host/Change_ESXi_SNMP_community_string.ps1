#################################################################################
# This script is created for configuring SNMP on multiple ESXi hosts
# Parameters
$CSVfile = 'ESXiHosts.csv' #Default name for CSV input file
$CSVfileDelimiter = ','
# CSV header:    Name
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


# $ESXiHostSnmp_String  = Read-Host -Prompt "`r`nInput the SNMP community string" doesn't work this way. use:

$ESXiHostSnmp_String  = public, cegekamonsecured, ihatesnmp, ireallydo

$ESXiCredentials = Get-Credential -Message "Please enter the ESXi host account credentials"

ForEach ($ESXiHost in $ESXiHosts){
	Write-Host -ForegroundColor Yellow "`r`nConnecting to" $ESXiHost.Name
    Connect-VIServer $ESXiHost.Name -Credential $ESXiCredentials
	Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$True -ReadOnlyCommunity $ESXiHostSnmp_String
    #Get-VMHostSnmp | Select ReadOnlyCommunities, Enabled
	Disconnect-VIServer -Server * -Force -Confirm:$False
}

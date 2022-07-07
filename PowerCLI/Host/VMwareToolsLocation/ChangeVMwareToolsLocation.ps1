#################################################################################################################
# This PowerShell Script is used to alter the default VMware Tools location to a central one for all ESXi hosts).
#
$queryMode = $true  # Set it to $false to change the VMware Tools location on each ESXi host
#
# !!! Review the script attributes before you start the script !!!
#################################################################################################################
#   ATRIBUTES:

# Cluster name RegEx and VMware tools location
$clustersDataArray = @(

       # SHARED
       [pscustomobject]@{
                        clusterNameRegEx='SHARBEHACLU\w+_1\d+'; # RegEx for Shared clusters in Hasselt AZ1
                        toolsLocation='/vmfs/volumes/TEMPLATES_HAS_AZ1/VMwareTools'
        }
       [pscustomobject]@{
                        clusterNameRegEx='SHARBEHACLU\w+_2\d+'; # RegEx for Shared clusters in Hasselt AZ2
                        toolsLocation='/vmfs/volumes/TEMPLATES_HAS_AZ2/VMwareTools'
        }
       [pscustomobject]@{
                        clusterNameRegEx='SHARNLGECLU\w+_1\d+'; # RegEx for Shared clusters in Geleen AZ1
                        toolsLocation='/vmfs/volumes/TEMPLATES_GEL_AZ1/VMwareTools'
        }
       [pscustomobject]@{
                        clusterNameRegEx='SHARNLGECLU\w+_2\d+'; # RegEx for Shared clusters in in Geleen AZ2
                        toolsLocation='/vmfs/volumes/TEMPLATES_GEL_AZ2/VMwareTools'
       }

       # TST
       [pscustomobject]@{
                        clusterNameRegEx='TSTBEHACLU\w+_1\d+'; # RegEx for TST clusters in Hasselt AZ1
                        toolsLocation='/vmfs/volumes/TEMPLATES_HAS_AZ1/VMwareTools'
       }

   )

# ESXi name RegEx to filter hosts
#$ESXiHostsRegEx = 'shar' 
$ESXiHostsRegEx = 'tst'

#################################################################################################################

# Set location the same as the folder where the current script is located
Set-Location $PSScriptRoot

# Connect to vCenter - function
. "./Connect2vCenter.ps1"

# Importing VMWare.VimAutomation.Core module
Write-Host -ForegroundColor Green "Importing VMware PowerCLI module..."
Import-Module -Name VMWare.VimAutomation.Core

# Clearing the default error array
$Error.clear()

# vCenter that will be used to connect to.
$vCenter = Read-Host -Prompt "Input vCenter FQDN or IP address"
#$vCenter = "sharbehavcsa101.cegekavirtual.local"
#$vCenter = "tstbehavcsa201.pocvirtual.local"

# vCenter credentials
Write-Host -ForegroundColor Green "Enter your username and password to make a connection to $vCenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for $vCenter"

# Connecting to vCenter
Connect2vCenter $vCenter -Credential $vCenterCredentials

#Get SHARED hosts
$ESXiHosts = Get-VMHost| Where-Object {$_.Name -match $ESXiHostsRegEx}
$ESXiHostsAmount = ($ESXiHosts | Measure-Object).count
Write-Host -ForegroundColor Blue "`r`n $ESXiHostsAmount ESXi hosts to process."
$ESXiHostsCounter = 1

# Safety measure before the script will start
if ($queryMode){
    Write-Warning " Query VMware Tools location!"
    Write-Host -NoNewLine 'Press any key to continue or CTRL+C to abort...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
 } else {
    Write-Warning " VMware Tools location will be changed!"
    Write-Host -NoNewLine "`r`nPress any key to continue or CTRL+C to abort..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
 }



ForEach ($ESXiHost in $ESXiHosts){
    
    Write-Host -ForegroundColor Yellow "`r`nESXi host $ESXiHost - $ESXiHostsCounter\$ESXiHostsAmount"

    $found = $false
    ForEach ($clusterData in $clustersDataArray) {

        if ($EsxiHost.Parent.Name -match $clusterData.clusterNameRegEx){

            $Location = $clusterData.toolsLocation # VMware Tools location

            if ($queryMode){
                $currentLocation = $ESXiHost.ExtensionData.QueryProductLockerLocation()
                Write-Host "`r`nCurrent VMware Tools location path: $currentLocation"
        
            } else {
                Write-Host "`r`nChange VMware Tools location path to $Location"
                $ESXiHost.ExtensionData.UpdateProductLockerLocation($Location) | Out-Null
            }
            $found = $true
            break;

        }
    }    
    
    if (!$found) {
        Write-Host -ForegroundColor Red "ESXi host name does not match with any cluster RegEx defined in clustersDataArray attribute!"
    };

    $ESXiHostsCounter++

}

#Disconnecting from vCenter.
Write-Host -ForegroundColor Green "`r`nDisconnecting from $vCenter please wait...."
Disconnect-VIServer -Server $vCenter -Confirm:$false
<#
.Synopsis
   This script will create the host affinity rules, 1 host per host_group.
#>
function Verb-Noun
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1,

        # Param2 help description
        [int]
        $Param2
    )

    Begin
    {
    }
    Process
    {
    }
    End
    {
    }
}
Function Connection-vCenter
{

    Param 
        (
            [string]$Vcenter,
            [System.Management.Automation.PSCredential]$Credential
        )

     #Connecting to vcenter with check for failed logins
                $login = "0"
                
                While ($login -eq "0")
                    {
                        Try
                            {
                            
                                Write-Host -ForegroundColor Green "Connecting to vcenter $vcenter!"
                                Connect-VIServer $Vcenter -Credential $Credential -ErrorAction stop -WarningAction SilentlyContinue
                                $login = "1"
                            }

                        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
                            {
                                Write-Host -ForegroundColor Red "Wrong username or password. Please try again!!"
                                $login = "0"
                                Write-host -ForegroundColor Green "Enter correct username and password to make a connection to vcenter"
                                $Credential = Get-Credential -Message "Enter correct username name and password for vcenter"
                                $script:vCenterCredentials=$Credential
                                
                            }
                    }
}

#Importing module needed for this script
Write-Host -ForegroundColor Green "Importing VMware PowerCLI module"
Import-Module vmware.vimautomation.core


#Set location the same as the folder where the current script is saved
set-location $PSScriptRoot
 
#Importing CSV file
Write-Host -ForegroundColor Green "Importing CSV file"
$DataFile = "host_affinity.csv"
$DataContent = Import-Csv -Path $DataFile -Delimiter ";" | Sort-Object Location -Descending

#write-host -ForegroundColor Yellow "Showing content from data file"
$DataContent

#Error check variable
$Errorcheck="99" 


#Clearing the default error arrayr as it will be checked later in the script and mailed if it contains data.
$error.clear()

Write-host -ForegroundColor Green "Enter your username and password to make a connection to vcenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for vcenter"

Foreach ($vm in $DataContent)
{
    #checking which template need to be used
        write-host "=========================================="
        Write-Host "Affinity rule creation started..."
  
  
        #Checking where the rule must be deployed (Vcenter+Cluster)
        $DestinationSite = $vm.Location
        if ($vm.Location  -eq "Kortrijk" -and $vm.OTAP -eq "PRD") 
            {
                Write-host -ForegroundColor Green "Location is Kortrijk PROD"
                $DestinationCluster = "SV81-ESX-P500"
                $vCenter = "SV81-ESX-P100.nbs.ndis.be"
                $Location = "Kortrijk"
                $dvswitch = "EANDIS-Kortrijk"
            
            }

        Elseif ($vm.Location -eq "Kortrijk" -and $vm.OTAP -eq "TST") 
            {
                Write-host -ForegroundColor Green "Location is Kortrijk TST"
                $DestinationCluster = "SV81-ESX-A500"
                $vCenter = "SV81-ESX-P100.nbs.ndis.be"
                $Location = "Kortrijk"
                $dvswitch = "EANDIS-Kortrijk"
            
            }

        Elseif ($vm.Location -eq "Merksem") 
            {
                Write-host -ForegroundColor Green "Location is Merksem"
                $DestinationCluster = "SV83-ESX-P500"
                $vCenter = "SV83-ESX-P100.nbs.ndis.be"
                $Location = "Merksem"   
                $dvswitch = "EANDIS-Merksem"
            }

        else 
            {
                Write-Host "Incorrect location, VI server not found." -ForegroundColor Red
                $Errorcheck=1
            }

      

        #Connecting to vcenter with custom function
        Connection-vcenter $vcenter -Credential $vCenterCredentials

        #Creating the affinity rule       
        $vmhost = get-vmhost $vm.name
        $hostdrsgroup = $vm.host_group+"-host-group"
        Write-Host "Following hostdrs group will be created: $hostdrsgroup"
        New-DrsClusterGroup -name $hostdrsgroup -cluster $DestinationCluster -VMHost $vmhost -Confirm:$false
       
        #Disconnect from vcenter
        disconnect-viserver * -force -Confirm:$false

}
    
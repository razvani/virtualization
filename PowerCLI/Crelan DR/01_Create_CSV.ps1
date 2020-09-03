<#
.Synopsis
   This script will gather all VM's that are involved in a DR. This is based on datastores linked to VIRPs.
.DESCRIPTION
   When entering all VIRP CI's in the array VIRPs this script will check all datastores linked to those CI's based on the CI number infront of the Datastore name. 
   $datastores array will be created with all Datastores found. All VM's info will be saved and exported for each entry in Datastore array.
.EXAMPLE
   Example of how to use this cmdlet          .\01_Create_CSV.ps1
.EXAMPLE
   Another example of how to use this cmdlet
#>


# vCenter FQDN
$vCenter = "hn1584.crelan.be"

# Log file name
$logfile = "DRP_vm_list.csv"

# Array of VIRP CI's. You can add as many as you want separated by coma.
# sample: $Virps= @("HI56789","")
$Virps= @("CI00048635")

# Set the working folder the same as where the current script is located
set-location $PSScriptRoot


Function Connect2vCenter
{

    Param 
        (
            [string]$vCenter
        )

                # Connecting to vCenter and check for failed logins
                $login = "0"
                While ($login -eq "0")
                    {
                        Try
                            {
                            
                                Write-Host -ForegroundColor Yellow "Connecting to vCenter $vCenter!"
                                Connect-VIServer $vCenter -user test -ErrorAction stop -WarningAction SilentlyContinue
                                $login = "1"
                            }

                        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
                            {
                                Write-Host -ForegroundColor Red "Wrong username or password. Please try again!"
                                $login = "0"
                            }
                    }
}




# Connecting to vCenter using the above function 'Connect2vCenter'
Connect2vCenter $vCenter

$exportVMinfo = @()

#Checking for all CI's of the virps in the array
Foreach ($virp in $virps)
    {
        #Checking each Datastore that's linked to the VIRP for VM's and gathering all info.
        $datastores = Get-Datastore | Where-Object {$_.Name -like "$virp*"}
        foreach ($datastore in $datastores)
            {
                $vms = get-vm -Datastore $datastore
                
                Foreach ($vm in $vms)
                    {
                        $VMSummary = "" | Select-Object Vmxpath, Name, Folder, Vlan, Datastore
                        $VMSummary.Name = $vm.Name                
                        $VMSummary.Folder = $vm.Folder
                        $VMSummary.Vmxpath = $vm | Get-View | ForEach-Object {$_.Config.Files.VmPathName}
			            $Networkname = $vm | Get-NetworkAdapter
                        $VMSummary.Vlan = $Networkname.NetworkName
                        $VMSummary.Datastore = $datastore
                        
                        $exportVMinfo += $VMSummary
                    }
            }
    }

Write-Host -ForegroundColor Yellow "Script is finished, all VM's can be found in $logfile"
$exportVMinfo | Export-Csv $logfile -NoTypeInformation -Delimiter ";"

# Closing vCenter connection.
Disconnect-VIserver -confirm:$false          


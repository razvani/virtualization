<#
.Synopsis
   This script will gather all vm's that are involved in a DR. This is based on datastores linked to VIRPs.
.DESCRIPTION
   When entering all VIRP CI's in the array VIRPs this script will check all datastores linked to those ci's based on the CI infront of the datastore name. 
   When it found some it will same them in a new array. For each of those entries in this new datastores array all vm's on it will be checked and info will be saved and exported.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

Function Connection-vCenter
{

    Param 
        (
            [string]$Vcenter
        )

     #Connecting to vCenter Geleen with check for failed logins
                $login = "0"
                While ($login -eq "0")
                    {
                        Try
                            {
                            
                                Write-Host -ForegroundColor Yellow "Connecting to vCenter $vcenter!"
                                Connect-VIServer $Vcenter -user test -ErrorAction stop -WarningAction SilentlyContinue
                                $login = "1"
                            }

                        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
                            {
                                Write-Host -ForegroundColor Red "Wrong username or password. Please try again!"
                                $login = "0"
                            }
                    }
}



#vCenter connection
$vcenter = "hn1584.crelan.be"

$logfile = "DRP_vm_list.csv"

#Array of VIRP CI's. You can add as many as you want
#sample: $Virps= @("HI56789","")
$Virps= @("CI00048635")

#Set location the same as the folder where the current script is saved
set-location $PSScriptRoot


#Connecting to vCenter using the function above
Connection-vCenter $vcenter

$exportVMinfo = @()

#Checking for all CI's of the virps in the array
Foreach ($Virp in $virps)
    {
        #Checking each Datastore that's linked to the VIRP for VM's and gathering all info.
        $datastores = Get-Datastore | Where-Object {$_.Name -like "$Virp*"}
        foreach ($datastore in $datastores)
            {
                $vms = get-vm -Datastore $datastore
                #Write-Host "Output for the variable 'vm' is $vm"

                Foreach ($vm in $vms)
                    {
                        $VMView = $vm | Get-View
                        $VMSummary = "" | Select Vmxpath,Name,Folder,DRPfolder,Vlan,Datastore
                        $VMSummary.Name = $vm.Name                
                        $VMSummary.Folder = $vm.folder
                        $VMSummary.DRPfolder = "DRP$($vm.folder)"
                        $VMSummary.Vmxpath = $vm | get-view |%{$_.Config.Files.VmPathName}
			            $Networkname = $vm | get-NetworkAdapter
                        $VMSummary.Vlan = $Networkname.NetworkName
                        $VMSummary.Datastore = $datastore
                        
                        $exportVMinfo += $VMSummary
                    }
            }
    }

Write-host -ForegroundColor Yellow "Script is finished, all VM's can be found in $logfile"
$exportVMinfo | export-csv $logfile -NoTypeInformation -Delimiter ";"

#Closing connection to vCenter.
disconnect-viserver -confirm:$false          


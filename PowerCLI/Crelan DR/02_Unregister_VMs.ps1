<#
.Synopsis
   This script will register all vm's from an csv file in the clusters/hosts where the datastores they are hostsed on are connected to.
.DESCRIPTION
   Long description
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



$vcenter = "hn1584.crelan.be"
$vmfile = "DRP_vm_list.csv"




# ask for confirmation before executing the script
Write-host -ForegroundColor Yellow  "You are about the unregister the VM's from the file $vmfile" `n
$confirm = Read-Host "Are you sure you want to continue? Type [Yes] to confirm"

if ($confirm -eq 'Yes')
    {
	    Connection-vCenter $vcenter

        $csv = Import-csv  $vmfile -Delimiter ";"

        #Write-host "Showing input file $csv"



        foreach ($row in $csv)
	        { 
	            Write-host "Removing $($vm.name) from $datastore in folder $($vmsummary.folder)"
                Remove-VM $row.Name -Confirm:$false        
   	        } 

      
        #disconnect from server
        disconnect-viserver -confirm:$false
        Write-Host -ForegroundColor Yellow "VM's have been unregistered based on the file $vmfile."

    }

Else
    {
        Write-host -ForegroundColor Red  "You have not typed Yes as answer but $confirm so the script will exit. Thank you for flying with us today."
    }



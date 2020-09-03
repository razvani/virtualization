<#
.Synopsis
   This script will register all vm's from an csv file in the clusters/hosts where the datastores they are hostsed on are connected to.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
   .\02_Unregister_VMs.ps1
.EXAMPLE
   Another example of how to use this cmdlet
#>

# vCenter FQDN
$vCenter = "hn1584.crelan.be"

# CSV file name
$vmfile = "DRP_vm_list.csv"

# Set the working folder the same as where the current script is located
Set-Location $PSScriptRoot

Function Connect2vCenter {
    Param 
    (
        [string]$vCenter
    )
    # Connecting to vCenter and check for failed logins
    $login = "0"
    While ($login -eq "0") {
        Try {
                            
            Write-Host -ForegroundColor Yellow "Connecting to vCenter $vCenter!"
            Connect-VIServer $vCenter -User test -ErrorAction stop -WarningAction SilentlyContinue
            $login = "1"
        }
        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin] {
            Write-Host -ForegroundColor Red "Wrong username or password. Please try again!"
            $login = "0"
        }
    }
}



# Ask for confirmation before executing the script
Write-Host -ForegroundColor Yellow "You are about the unregister the VMs from the file $vmfile" `n
$confirm = Read-Host "Are you sure you want to continue? Type [Yes] to confirm"

if ($confirm -eq 'Yes') {
    Connect2vCenter $vCenter

    $csv = Import-csv  $vmfile -Delimiter ";"

    foreach ($row in $csv) { 
        Write-host "Removing $($row.name) from datastore $($row.Datastore) in folder $($row.Folder)"
        Remove-VM $row.Name -Confirm:$false        
    } 

    # Closing vCenter connection
    Disconnect-VIserver -Confirm:$false  
    
    Write-Host -ForegroundColor Yellow "VMs have been unregistered based on file $vmfile."

}

Else {
    Write-host -ForegroundColor Red  "You have not typed Yes as answer but $confirm so the script will exit. Thank you for flying with us today."
}



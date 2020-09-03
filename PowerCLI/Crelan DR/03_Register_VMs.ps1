<#
.Synopsis
   This script will register all VMs from an CSV file in the clusters/hosts where the Datastores they are hostsed on are connected to.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

# vCenter FQDN
$vCenter = "hn1584.crelan.be"

# CSV file name
$vmfile = "DRP_vm_list.csv"

# Log file name
$logfile = "VM_Register_log.csv"

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
                            
            Write-Host -ForegroundColor Yellow "Connecting to vcenter $vCenter!"
            Connect-VIServer $vCenter -User test -ErrorAction stop -WarningAction SilentlyContinue
            $login = "1"
        }
        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin] {
            Write-Host -ForegroundColor Red "Wrong username or password. Please try again!!"
            $login = "0"
        }
    }
}


# Ask for confirmation before executing the script
Write-host -ForegroundColor Yellow "You are about the register the VMs from the file $vmfile" `n
$confirm = Read-Host "Are you sure you want to continue? Type [Yes] to confirm"

if ($confirm -eq 'Yes') {
    Connect2vCenter $vCenter
    $csv = Import-csv  $vmfile -Delimiter ";"

    foreach ($row in $csv) { 
        $datastore = $row.Datastore
        $vmhost = Get-VMHost -PipelineVariable ESXiHost  | Get-Datastore | Where-Object { $_.name -like "$datastore*" } | Select-Object @{N = 'vmhost'; E = { $ESXiHost.Name } }
        $NewVmHost = $vmhost.vmhost
        
        New-VM -VMFilePath $($row.VMXPath) -VMHost $NewVmHost -Location $($row.Folder) -RunAsync
        Start-Sleep 2
        Get-Folder $($row.Folder) | Get-VM $($row.Name) | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $($row.Vlan) -StartConnected:$true -Confirm:$false

    } 
     
    # Closing vCenter connection
    Disconnect-VIServer -Confirm:$false
    Write-Host -ForegroundColor Yellow "VMs have been registered. Check log file $logfile for the details of which vm has been registered."
}
Else {
    Write-host -ForegroundColor Red  "You have not typed 'Yes' as answer so the script will exit. Thank you for flying with us today!"
}



<# examples

#Output to Console
Get-VM "name"| Get-VMDisk | ft -AutoSize

#Export to CSV
Get-VM "name"| Get-VMDisk | Export-Csv -NoTypeInformation -UseCulture -Path "VM-Disks.csv"

#>

function Get-VMDisk {

[CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "VMs to process")]
        [ValidateNotNullorEmpty()]
          [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]] $myVMs
    )
Process {
        $View = @()
        foreach ($myVM in $myVMs){
            $VMDKs = $myVM | get-HardDisk
            foreach ($VMDK in $VMDKs) {
                if ($VMDK -ne $null){
                    [int]$CapacityGB = $VMDK.CapacityKB/1024/1024
                    $Report = [PSCustomObject] @{
                            Name = $myVM.name 
                            PowerState = $myVM.PowerState
                            Datastore = $VMDK.FileName.Split(']')[0].TrimStart('[')
                            VMDK = $VMDK.FileName.Split(']')[1].TrimStart('[')
                            StorageFormat = $VMDK.StorageFormat
                            CapacityGB = $CapacityGB
                            Controller = $VMDK.ExtensionData.ControllerKey -1000
                            Unit = $VMDK.ExtensionData.UnitNumber
                        }
                        $View += $Report
                    }   
                }
            }
    $View | Sort-Object VMname, Controller, Unit
    }
}

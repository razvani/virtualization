#################################################################################################################
# This PowerShell Script is used to get all VMs that have mounted and ISO image from "ISO" datstores
#
#################################################################################################################

$vm_list_with_iso = @()

$VMs = Get-datastore | Where {$_.name -like 'ISO_HAS_AZ1' -or $_.name -like 'ISO_HAS_AZ2' -or $_.name -like 'ISO_GEL_AZ1' -or $_.name -like 'ISO_GEL_AZ2'} | Get-VM
foreach ($vm in $VMs){
	$cdinfo = Get-CDDrive $vm
	$details = @{
			VM_name = $vm.name
			ISOPath = $cdinfo.IsoPath

		}
	$vm_list_with_iso += New-Object PSObject -Property $details | Select VM_name, ISOPath
}

$vm_list_with_iso | Export-Csv "vms_with_isos.csv"
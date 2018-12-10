$VM = "HI84576-SWARG624"

if (Get-VM $VM) {

    $Disks = Get-VM $VM | Get-HardDisk | Where {$_.DiskType -like "Raw*"}

    Foreach ($Disk in $Disks) {
			$Lun = Get-SCSILun $Disk.SCSICanonicalName -VMHost (Get-VM $VM).VMHost
			$Lun |`
			Select-Object CanonicalName, CapacityGB, @{Name="LUN ID";Expression={$Lun.RuntimeName.Substring($Lun.RuntimeName.Length-2,2)} }       
			}
};



#$Disk = Get-VM CI00003465-SVPVNORAA0001 | Get-HardDisk | Where {$_.DiskType -eq "RawVirtual"}

#Get-SCSILun $Disk.SCSICanonicalName -VMHost (Get-VM HI84576-SWARG624.SIMARG.LAN).VMHost


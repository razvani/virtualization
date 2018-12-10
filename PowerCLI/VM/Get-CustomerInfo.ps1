Function Get-CustomerInfo {

param (

    [string]$FolderName = (Read-Host "Please provide a Customer")

)

    If ($FolderName -eq "") {

    Write-Host -ForegroundColor Red "No customer provided (e.g. Cegeka)"

    } 
    
    Else { 
    
    
        Get-Folder $FolderName ; 

        $GetVM = Get-VM

            ForEach ($VM in $GetVM){

                $VMName = $VM.Name

                    Get-HardDisk -VM $VMName | Select Name, StorageFormat, DiskType, CapacityGB, FileName | ft -Wrap
    
                    Write-Host -ForegroundColor Green "VM $VM found with following disks:"

                    }

           }
    

}

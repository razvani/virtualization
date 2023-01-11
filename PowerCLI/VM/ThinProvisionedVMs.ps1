# Ask for vCenter server
$vCenterServer = Read-Host "Provide the vCenter FQDN Address"

# Check if the C:\Temp directory exists
if (!(Test-Path "C:\Temp")) {
    # Create the C:\Temp directory
    New-Item -ItemType Directory -Path "C:\Temp"
}

# Connect to vCenter
Connect-VIServer -Server $vCenterServer -Credential (Get-Credential) -AllLinked

# File name
$location = "C:\Temp\$(Get-Date -Format "yyyyMMdd")-ThinProvisioned.csv"

# Create an empty array to store the thin provisioned VMs
$thinProvisionedVMs = @()

# Get all VMs
$vms = Get-VM

# Loop through each VM
foreach ($vm in $vms) {
    if ($vm.name -notlike "vCLS*") {
        try {
            # Get the virtual disk objects for the VM
            $virtualDisks = Get-HardDisk -VM $vm

            # Loop through each virtual disk
            foreach ($virtualDisk in $virtualDisks) {
                # Check if the virtual disk is thin provisioned
                if ($virtualDisk.StorageFormat -eq "Thin") {
                    # Add the VM to the array
                    $thinProvisionedVMs += $vm.Name
                    # Output the VM name
                    Write-Host "VM $($vm.Name) is thin provisioned."
                }
            }
        } catch {
            Write-Error -Message "Error checking VM $($vm.Name): $_"
        }
    }
}

# Check if the array is not empty
if ($thinProvisionedVMs) {
    # Export the array to a CSV file
    $thinProvisionedVMs | Export-Csv -Path "$location" -NoTypeInformation
    Write-Host "The Results were saved on $location"
} else {
    Write-Host "No thin provisioned VMs found."
}
Disconnect-VIServer * -Confirm:$false

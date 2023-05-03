# Credentials

$credentials = Get-credential

# Connect to vCenter
try {

  Connect-VIServer sharbehavcsa101.cegekavirtual.local -Credential $credentials -Alllinked
}

catch {

  Write-Error "Error connecting to vCenter: $_"
  exit

}

# Get the current date and time
$date = Get-Date

# Format the date and time in the desired format
$formattedDate = $date.ToString("yyyyMMddHHmm")

# Build the filename using the formatted date
$filename = "$formattedDate-VMwareToolsISO.csv"

# Get list of all virtual machines
$vms = Get-VM

# Create array to store results
$results = @()

# Loop through each virtual machine
foreach ($vm in $vms) {
    # Get the CD/DVD drive for the virtual machine
    $cdrom = Get-CDDrive -VM $vm

    # Check if an ISO is mounted in the CD/DVD drive
    if ($cdrom.IsoPath -like "*VMware Tools*") {
        $status = "VMware tools ISO mounted"
    }
    else {
        $status = "VMware tools ISO not mounted"
    }

    # Create object to store results for the virtual machine
    $obj = [PSCustomObject]@{
        Name = $vm.Name
        Status = $status
    }

    # Add object to results array
    $results += $obj
}

# Export results to CSV file
$results | Where-Object { $_.Status -eq "VMware tools ISO mounted" } | Export-Csv -Path "E:\PowerShellExports\$filename" -NoTypeInformation

# Disconnect from vSphere server
Disconnect-VIServer -Confirm:$false

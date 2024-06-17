# Credentials

$credentials = Get-credential

# Connect to vCenter
try {

  Connect-VIServer vcenter.domain.corp -Credential $credentials -Alllinked
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
$filename = "$formattedDate-HostExportInfo.csv"

# Get a list of all ESXi hosts with SHAR in their name
try {
  $hosts = Get-VMHost | Where-Object { $_.Name -like "*SHAR*" }
}
catch {
  Write-Error "Error getting list of hosts: $_"
  exit
}

# Initialize an array to store the host information
$hostInfo = @()

# For each host, set the values of the properties and add them to the array
foreach ($VMHost in $hosts) {
  # Determine the value of the new property
  switch -wildcard ($VMHost.Parent) {
    "*DR*" { $os = "" }
    "*CLUW*" { $os = "MICROSOFT" }
    "*CLUL*" { $os = "LINUX" }
    default { $os = "" }
  }

  # Determine the value of the datacenter property
  switch -wildcard ($VMHost.Name) {
    "*NLGEESX*" { $datacenter = "GELEEN" }
    "*BEHAESX*" { $datacenter = "HASSELT" }
    "*BEHAESXDR*" { $datacenter = "HASSELT-T3" } 
    "*NLGEESXDR*" { $datacenter = "GELEEN-T3" }
    default { $datacenter = "" }
  }

  # Add the host's name, memory, number of CPUs, new property value, and parent cluster to the array
  # only if it is not excluded
  if (!($VMHost.Name -like "*upl*") -and !($VMHost.Name -like "*migtoaci*") -and !($VMHost.Parent -like "*install*") -and !($VMHost.Parent -like "*TEST*") -and !($VMHost.Parent -like "*rep*") -and !($VMHost.Parent -like "*new*")) {
    $hostInfo += [PSCustomObject]@{
      Name = $VMHost.Name
      NumCPU = $VMHost.NumCpu
      MemoryGB = [Math]::Round($VMHost.MemoryTotalGB)
      OS = $os
      Datacenter = $datacenter
      Cluster = $VMHost.Parent
    }
  }
}

# Export the array to a CSV file with the formatted date in the filename
try {
  $hostInfo | Export-Csv -Path "E:\PowerShellExports\$filename" -NoTypeInformation
}
catch {
  Write-Error "Error exporting to CSV file: $_"
}

Disconnect-VIServer * -Confirm:$false

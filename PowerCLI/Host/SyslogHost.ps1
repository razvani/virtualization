#################################################################################
# This script is created for configuring SNMP on multiple ESXi hosts
# Parameters:
#
# CSV file
$CSVfile = 'ESXiHosts.csv' #Default name for CSV input file ## CSV header: Name
$CSVfileDelimiter = ','
#
# Syslog host
$SyslogHost = "ip or dns record"
#
# Output CSV file
$OutputCSV = 'ESXiHosts_Output.csv'
#
#################################################################################

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

try {
    # Importing VMWare.VimAutomation.Core module
    Write-Host -ForegroundColor Green "`r`nImporting VMware PowerCLI module..."
    Import-Module -Name VMWare.VimAutomation.Core -ErrorAction Stop

    # Set location the same as the folder where the current script is located
    Set-Location $PSScriptRoot

    # Importing CSV file that contains the ESXi hosts FQDN.
    $DataFile = $CSVfile | %{ If($Entry = Read-Host "`r`nInput the name of the import CSV file ($_)"){$Entry} Else {$_} }
    Write-Host -ForegroundColor Yellow "Importing CSV file $DataFile"
    $ESXiHosts = Import-Csv -Path $DataFile -Delimiter $CSVfileDelimiter

    $ESXiCredentials = Get-Credential -Message "Please enter the ESXi host account credentials."

    # Initialize an empty array to store the modified ESXi host objects
    $ModifiedESXiHosts = @()

    # Setting the syslog host and restarting the syslog service on each host.
    foreach ($ESXiHost in $ESXiHosts) {
        try {
            Write-Host -ForegroundColor Yellow "`r`nConnecting to" $ESXiHost.Name
            Connect-VIServer $ESXiHost.Name -Credential $ESXiCredentials -ErrorAction Stop

            $esxiHost = Get-VMHost -Name $ESXiHost.Name

            $esxiHost | Set-VMHostSysLogServer -SysLogServer $SyslogHost -ErrorAction Stop

            Write-Host "Syslog server updated successfully."

            $syslogService = $esxiHost | Get-VMHostService | Where-Object { $_.Key -eq "vmsyslogd" }
            if ($syslogService) {
                $syslogService | Restart-VMHostService -Confirm:$false -ErrorAction Stop
                Write-Host "Syslog service restarted successfully."
            } else {
                Write-Host "Syslog service not found on $($ESXiHost.Name)."
            }

            # Add the modified ESXi host object to the array
            $ModifiedESXiHosts += $esxiHost

        } catch {
            Write-Host "Error occurred while configuring syslog on $($ESXiHost.Name):"
            Write-Host $_.Exception.Message
        } finally {
            Disconnect-VIServer -Server * -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # Export the modified ESXi host objects to CSV
    $ModifiedESXiHosts | Export-Csv -Path $OutputCSV -Delimiter $CSVfileDelimiter -NoTypeInformation
    Write-Host "Modified ESXi hosts exported to $OutputCSV successfully."

} catch {
    Write-Host "Error occurred while importing PowerCLI module:"
    Write-Host $_.Exception.Message
}

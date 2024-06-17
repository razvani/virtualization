# CSV file path (current folder)
$ImportFile = '.\vCenterVMs_list.csv'

# Get the current logged on account for snapshot description
$loggedOnUserAccount = whoami

# Import VM list from CSV file
Import-csv $ImportFile | ForEach-Object {
    $vmName = $_.vmName
    $esxiHost = $_.esxiHost


    #Connect to ESXi host
    $esxiCred = Get-Credential -Message "ESXi host $esxiHost credentials:" -UserName root
    Connect-VIServer -Server $esxiHost -Credential $esxiCred

    #Check if VM is Powered Off
    $vmState = (Get-VM -Name $vmName).ExtensionData.guest.guestState
    if ($vmState -ne "notRunning") {
        Write-Host -ForegroundColor Red "`r`n$vmName is NOT Powered Off!"
        Write-Host "CTRL+C to stop the script"
        pause "Press any key to continue"
    }


    #Create VM snapshot
    Write-Host -ForegroundColor Yellow "`r`n$vmName - Create VM snapshot"
    Get-VM $vmName | New-Snapshot -Name OfflineSnapshot -Description "Created $(Get-Date) by $loggedOnUserAccount"

    #Get VM snapshot info
    Get-VM $vmName | Get-Snapshot | Select-Object VM,Name,Description,
    PowerState,Quiesced,Created,Parent,
    @{Name="Age";Expression={(Get-Date) - $_.Created }},
    @{Name="SizeMB";Expression={[math]::Round($_.SizeMB,2)}} |
    Sort VM,Created


    #Start VM
    Start-VM -VM $vmName -Confirm

    #Disconnect from ESXi host
    Disconnect-VIServer * -confirm:$false

}

Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
#####################################################################################################
# Define the vCenter name list array
$vms = @('CI00164296-SHARBEHAVCSA101',
         'CI00164302-SHARBEHAVCSA201',
         'CI00164301-SHARNLGEVCSA101',
         'CI00164303-SHARNLGEVCSA201'
        )
#####################################################################################################

# Set the CSV file path
$csvFilePath = ".\vCenterVMs_list.csv"

# Define CSV header
$header = "vmName", "esxiHost"

# Write the header to the CSV file
$header -join "," | Out-File -FilePath $csvFilePath -Encoding UTF8

#vCenter to connect to run the script.
$vCenter = Read-Host -Prompt "Enter vCenter FQDN"

$credentials = Get-Credential -Message "Enter your vCenter $vCenter credentials:"
Connect-VIServer -Server $vCenter -Credential $credentials -AllLinked:$true


foreach ($vmName in $vms) {
    
    $vm = Get-VM $vmName | Where-Object {$_.ExtensionData.Config.ManagedBy.ExtensionKey -NotMatch 'com.vmware.vcDr'} | Select-Object VMHost 
    $vmHost = $vm.VMHost.Name

    $output = """$vmName"",""$vmHost"""
    Add-Content -Path $csvFilePath -Value $output
}

#Disconnect from all vCenters
Disconnect-VIServer * -confirm:$false
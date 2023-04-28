# Set location the same as the folder where the current script is located
Set-Location $PSScriptRoot

# Connect to vCenter - function
. "./Connect2vCenter.ps1"

# Importing VMWare.VimAutomation.Core module
Write-Host -ForegroundColor Green "Importing VMware PowerCLI module..."
Import-Module -Name VMWare.VimAutomation.Core

# Clearing the default error array
$Error.clear()

# vCenter that will be used to connect to.
$vCenter = Read-Host -Prompt "Input vCenter FQDN or IP address"
#$vCenter = "pocbehavcsa001.pocvirtual.local"
#$vCenter = "sharbehavcsa003.cegekavirtual.local"
#$vCenter = "argbehavcsa001argvirtual.local"

# vCenter credentials
Write-Host -ForegroundColor Green "Enter your username and password to make a connection to $vCenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for $vCenter"

$NoToolsRunning = "VMs_ToolsNotRunning_$(get-date -Format yyyyddmm_hhmmtt).csv"
$sleepCounter = 1

# Importing CSV file that contains the VM list.  (sample: Tier3_ACC_Servers.csv)
# CSV header:   Name
$DataFile = Read-Host -Prompt "Input the name of the import CSV file"
Write-Host -ForegroundColor Yellow "Importing CSV file $DataFile"
$DataContent = Import-Csv -Path $DataFile -Delimiter ";"
$DataContentCount = ($DataContent | Measure-Object).count
$VMsCount = 1

#Measure the run-time of a PowerShell script
$StopWatch = [system.diagnostics.stopwatch]::startNew()

# Connecting to vCenter
Connect2vCenter $vCenter -Credential $vCenterCredentials

ForEach ($vm in $DataContent){
 
	Write-Host -ForegroundColor Yellow "`r`nChecking $($vm.name) - $VMsCount\$DataContentCount"
	$tempVM = Get-VM $vm.Name | Where-Object {$_.ExtensionData.Config.ManagedBy.ExtensionKey -NotMatch 'com.vmware.vcDr'}
	If ($tempVM.PowerState -eq "PoweredOn"){
		Write-Host "$tempVM is PoweredOn. VMware Tools will be checked...."
		$vmView = $tempVM | Get-View
		$vmToolsStatus = $vmView.summary.guest.toolsRunningStatus
		If ($vmToolsStatus -eq "guestToolsRunning") {
			# Graceful VM shutdown
			Write-Host -ForegroundColor Green "$tempVM will be gracefully Shutdown!"
			$tempVM | Shutdown-VMGuest -Confirm:$false
			$sleepCounter++
			Write-host -ForegroundColor Green "Counter before sleep: $sleepCounter from 12"
		} else {
			Write-Host -ForegroundColor Red "Vmware tools status is" ($vmToolsStatus).Substring(10)
			$tempVM | Select-Object Name, VMHost, PowerState, @{Label="VmToolsStatus"; Expression={($vmToolsStatus).Substring(10)}} | Export-Csv -Path $NoToolsRunning -NoTypeInformation -Append -Delimiter ";"
		}
	} else {
		Write-Host -ForegroundColor Green "$tempVM is already Powered Off"
	}

    $VMsCount++

	If ($sleepCounter -gt 11) {
		Write-host "Sleeping for 5 seconds"
		Start-Sleep 5
		$sleepCounter = 0
	}
} 

# Exporting the error array to a txt file
If ($Error) {
	$Error > error_log.txt
	Write-Host -ForegroundColor Red "`r`nThere are errors! Check the file: error_log.txt"
}
    
#Disconnecting from vCenter.
Write-Host -ForegroundColor Green "Disconnecting from $vCenter please wait...."
Disconnect-VIServer -Server $vCenter -Confirm:$false

#Done
$StopWatch.Stop()
Write-Host  -ForegroundColor Green ("`r`nThis script took {0:N3} minutes to run." -f $StopWatch.Elapsed.TotalMinutes)
Write-Host -ForegroundColor Green "`r`nDone!"

If ($NoToolsRunning) {
	Write-Host -ForegroundColor Blue "`r`nCheck the export CSV file for VMs without running VMware tools: $VmwareToolsStatus"
}


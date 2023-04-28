﻿# Set location the same as the folder where the current script is located
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

# vCenter credentials
Write-Host -ForegroundColor Green "Enter your username and password to make a connection to $vCenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for $vCenter"

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
	If ($tempVM.PowerState -eq "PoweredOff"){
		Start-VM -VM $tempVM
		If ($sleepCounter -gt 5){
			Write-Host "Sleeping for 5 seconds!"
			Start-Sleep 5
			$sleepCounter = 0
		}
		$sleepCounter++
	} else {
		Write-Host -ForegroundColor Green "$($vm.Name) is already Powered On"
	}
	$VMsCount++
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


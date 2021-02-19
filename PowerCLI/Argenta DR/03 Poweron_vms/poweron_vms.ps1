#connection to vcenter

Function Connection-vCenter
{

    Param 
        (
            [string]$Vcenter,
            [System.Management.Automation.PSCredential]$Credential
        )

     #Connecting to vcenter with check for failed logins
                $login = "0"
                
                While ($login -eq "0")
                    {
                        Try
                            {
                            
                                Write-Host -ForegroundColor Green "Connecting to vcenter $vcenter!"
                                Connect-VIServer $Vcenter -Credential $Credential -AllLinked -ErrorAction stop -WarningAction SilentlyContinue
                                $login = "1"
                            }

                        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
                            {
                                Write-Host -ForegroundColor Red "Wrong username or password. Please try again!!"
                                $login = "0"
                                Write-host -ForegroundColor Green "Enter correct username and password to make a connection to vcenter"
                                $Credential = Get-Credential -Message "Enter correct username name and password for vcenter"
                                $script:vCenterCredentials=$Credential
                                
                            }
                    }
}

#Importing module needed for this script
Write-Host -ForegroundColor Green "Importing VMware PowerCLI module"
Import-Module vmware.vimautomation.core


#Set location the same as the folder where the current script is saved
set-location $PSScriptRoot

#Clearing the default error arrayr as it will be checked later in the script and mailed if it contains data.
$error.clear()


$vcenter="sharbehavcsa003.cegekavirtual.local"
$counter=1

Write-host -ForegroundColor Green "Enter your username and password to make a connection to $vcenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for $vcenter"

#Importing CSV file
Write-Host -ForegroundColor Yellow "Importing CSV file"
$DataFile = "poweron_vms.csv"
$DataContent = Import-Csv -Path $DataFile -Delimiter ";" | Sort-Object Location -Descending

#Connecting to vcenter with custom function
Connection-vcenter $vcenter -Credential $vCenterCredentials



 foreach ($vm in $DataContent){
 
 	    Write-host "Checking $($vm.name)"
        

        if ($vm.PowerState -eq "PoweredOn"){
            
            $tempVM = Get-VM $vm.Name | Where-Object {$_.ExtensionData.Config.ManagedBy.ExtensionKey -ne 'com.vmware.vcDr'}
            
            if ($tempVM.PowerState -ne "PoweredOn"){
                
                Start-VM -VM $tempVM
              
                if ($counter -gt 1001){
                Write-host "Sleeping for 5 seconds"
                sleep 5
                $counter=0
                }
            }
            
            else {
                Write-Host -ForegroundColor Green "$($vm.Name) is already powered on"
            } 
        }

        else {
        Write-Host -ForegroundColor Green "$($vm.name) was not powered on when we started"
        }
 
        

}

#exporting the error array to a txt file
$error > error_log.txt

    
#Disconnecting from vcenter.
Write-host -ForegroundColor Green "Disconnecting from $vcenter please wait...."
Disconnect-VIServer -Server $vcenter -Confirm:$false   

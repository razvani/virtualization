<#
.Synopsis
   This script will create all the rules (affinity and anti-affinity) based on a CSV file needed for the customer FluviusOT
   The CSV file is the same as the one for deploying vm's at FluviusOT.
#>
function Verb-Noun
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1,

        # Param2 help description
        [int]
        $Param2
    )

    Begin
    {
    }
    Process
    {
    }
    End
    {
    }
}
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
                                Connect-VIServer $Vcenter -Credential $Credential -ErrorAction stop -WarningAction SilentlyContinue
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
 
#Importing CSV file
Write-Host -ForegroundColor Green "Importing CSV file"
$DataFile = "set_affinity_rules.csv"
$DataContent = Import-Csv -Path $DataFile -Delimiter ";" | Sort-Object Location -Descending

#write-host -ForegroundColor Yellow "Showing content from data file"
$DataContent | ft -AutoSize

#Error check variable
$Errorcheck="99" 


#Clearing the default error arrayr as it will be checked later in the script and mailed if it contains data.
$error.clear()

Write-host -ForegroundColor Green "Enter your username and password to make a connection to vcenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for vcenter"

Foreach ($vm in $DataContent)
{
    #checking which template need to be used
        write-host "=========================================="
        Write-Host "Affinity rule creation started..."
  
  
        #Checking where the rule must be deployed (Vcenter+Cluster)
        $DestinationSite = $vm.Location
        if ($vm.Location  -eq "Kortrijk" -and $vm.OTAP -eq "PRD") 
            {
                Write-host -ForegroundColor Green "Location is Kortrijk PROD"
                $DestinationCluster = "SV81-ESX-P500"
                $vCenter = "SV81-ESX-P100.nbs.ndis.be"
                $Location = "Kortrijk"
                $dvswitch = "EANDIS-Kortrijk"
            
            }

        Elseif ($vm.Location -eq "Kortrijk" -and $vm.OTAP -eq "ACC/TST") 
            {
                Write-host -ForegroundColor Green "Location is Kortrijk TST"
                $DestinationCluster = "SV81-ESX-A500"
                $vCenter = "SV81-ESX-P100.nbs.ndis.be"
                $Location = "Kortrijk"
                $dvswitch = "EANDIS-Kortrijk"
            
            }

         Elseif ($vm.Location -eq "Kortrijk" -and $vm.OTAP -eq "TRN") 
            {
                Write-host -ForegroundColor Green "Location is Kortrijk TST"
                $DestinationCluster = "SV81-ESX-A500"
                $vCenter = "SV81-ESX-P100.nbs.ndis.be"
                $Location = "Kortrijk"
                $dvswitch = "EANDIS-Kortrijk"
            
            }

        Elseif ($vm.Location -eq "Merksem") 
            {
                Write-host -ForegroundColor Green "Location is Merksem"
                $DestinationCluster = "SV83-ESX-P500"
                $vCenter = "SV83-ESX-P100.nbs.ndis.be"
                $Location = "Merksem"   
                $dvswitch = "EANDIS-Merksem"
            }

        else 
            {
                Write-Host "Incorrect location, VI server not found." -ForegroundColor Red
                $Errorcheck=1
            }

      

        #Connecting to vcenter with custom function
        Connection-vcenter $vcenter -Credential $vCenterCredentials

        #Setting vcentername
        $VmvCenterName = $vm.CI +"-" + $vm.name
        write-host "showing vcentername $($VmvCenterName)"

        $tempvm = get-vm $VmvCenterName
        Write-host "Showing tempvm $($tempvm)"

        $vmdrsgroup = $vm.ESXDC+"-vm-group"
        #Write-Host "Showing drs group $vmdrsgroup for vm $tempvm for cluster $DestinationCluster"

        if ($tempvm)
            {
                #Creating the vmdrs group       
                Try
                {
                   
                    Write-host -ForegroundColor Green "Checking if Vm drs group $vmdrsgroup already exist or not. If it does adding $tempvm to this group"
                    Get-DrsClusterGroup -name $vmdrsgroup -ErrorAction Stop | Set-DrsClusterGroup -VM $tempvm -Add #-WhatIf
                    #For debugging I've put a pause till any key is pressed
                    #Read-Host 'Press any key to continue…' | Out-Null
                }

                Catch
                {
                    Write-host -ForegroundColor Green "VM drs group not found, $($vmdrsgroup) will be created"
                    New-DrsClusterGroup -name $vmdrsgroup -cluster $DestinationCluster -VM $tempvm  -Confirm:$false #-WhatIf
                }
               
            }

        Else
            {
                Write-host "VM doesn't exist yet"
            }
        
        


        #Check if the vm is part of software cluster. This is needed to make sure vm's never run on same host.
        If($vm.vmrule) 
            {
                Write-host "Vm rule found in the CSV file for $($vm.name) with the rule $($vm.vmrule)"
                #Creating a list so we can sort the items to create a rule name with sorted hostnames
                $list=$vm.vmrule,$vm.name | Sort-Object
                Write-host "Showing list content $list"
                $vmDRSrule = $list[0]+"-"+$list[1]
                $vm1 = $list[0]
                $vm2 = $list[1]
                Write-host "Vm DRS rule is $($vmDRSrule)"
                Write-host "VM1 = $($vm1)"
                Write-host "VM2 = $($vm2)"
                
                #Doing a get-vm to see if both vm's are created in vcenter and if the rule already exists. Only then the rule will be created.
                $check_vm1 = get-vm "*$vm1"
                $check_vm2 = get-vm "*$vm2"
                $check_drsrule = Get-DrsRule -cluster $DestinationCluster -name $vmDRSrule
                #Write-host "If the rule already exist it will show some output $check_drsrule"

                If (($check_vm1) -and ($check_vm2) -and (!$check_drsrule))
                    {
                        Write-host "Vm's found $check_vm1 and $check_vm2. The Rule $vmDRSrule will be created."
                        New-DrsRule -Cluster $DestinationCluster -Name $vmDRSrule -KeepTogether $false -VM $check_vm1,$check_vm2

                    }
                
                else
                    {
                        Write-host "Either both vm's not created yet or rule already exist."
                    }
                    


            }

        Else
            {
                Write-host "Vm is not part of a software cluster"
            }

        #For debugging I've put a pause till any key is pressed
        #Read-Host 'Press any key to continue…' | Out-Null
                
        #Disconnect from vcenter
        disconnect-viserver * -force -Confirm:$false

}

#exporting the error array to a txt file
$error > "set_affinity_rules_error.txt"
    
    
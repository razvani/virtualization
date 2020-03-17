<#
.Synopsis
    Eandis/FluviusOT deploy script with a join domain for windows vm.
    This script can be used for deployment of vm's on Eandis-Fluvius dedicated environment. It will use a CSV file with a certain layout. More info can found on our sharepoint "FluviusOT - Deploy vm"
#>

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
 
#Loading  "System.Web" assembly to generate random password
[Reflection.Assembly]::LoadWithPartialName("System.Web")


#Importing CSV file
Write-Host -ForegroundColor Green "Importing CSV file"
$DataFile = "eandis_deploy_script_with_join_domain.csv"
$DataContent = Import-Csv -Path $DataFile -Delimiter ";" | Sort-Object Location -Descending

#write-host -ForegroundColor Yellow "Showing content from data file"
$DataContent

#Error check variable
$Errorcheck="99" 

#Getting windows credentials to add vm to a domain.
$domain="nbs.ndis.be"
Write-host -ForegroundColor Green "Enter password for the account SA_AdJoinVmware that will be used to add the windows vm's to the domain"
$DomainCredentials=Get-Credential SA_AdJoinVmware -message "Enter password for SA_AdJoinVmware"

Write-host -ForegroundColor Green "Enter your username and password to make a connection to vcenter"
$vCenterCredentials = Get-Credential -Message "Enter your username name and password for vcenter"

Foreach ($vm in $DataContent) 
{
    
    $Folder=""
    
    #checking which template need to be used
    write-host "=========================================="
    Write-Host "Deploying "$vm.name -ForegroundColor Green
   
    #Checking where vm must be deployed (Vcenter+Cluster)
    $DestinationSite = $vm.Location
    if ($vm.Location  -eq "Kortrijk" -and $vm.OTAP -eq "PRD") 
        {
            Write-host -ForegroundColor Green "Location is Kortrijk PROD"
            $DestinationCluster = "SV81-ESX-P500"
            $vCenter = "SV81-ESX-P100.nbs.ndis.be"
            $Location = "Kortrijk"
            $dvswitch = "EANDIS-Kortrijk"
            
        }

    Elseif ($vm.Location -eq "Kortrijk" -and $vm.OTAP -eq "TST") 
        {
            Write-host -ForegroundColor Green "Location is Kortrijk TST"
            $DestinationCluster = "SV81-ESX-A500"
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
   

    #Checking for the storage
    If ($vm.storageclass -eq "Bronze")
        {
            
            $DestinationStorageCluster = $DestinationCluster+"-Bronze"
            
            
        }

    Elseif ($vm.storageclass -eq "Gold")
        {
            
            $DestinationStorageCluster = $DestinationCluster+"-Gold"
            
            
        }

    Else
        {
            Write-host "Incorrect storage class"
            $Errorcheck =1 
        }
    
    #Set location based on Owner
    If ($vm.FolderESX)
        {
            
            $Folder=$vm.FolderESX
        }

    Else
        {
            Write-Host "No folder ESX detected, using discovered virtual machine"
            $Folder= "Discovered virtual machine"
        }

    

    #Write-Host -ForegroundColor Yellow "Checking status error" $Errorcheck

    #Create vm from template if there wasn't any error in previous steps
    If ($Errorcheck ="99")
        {
            $VmvCenterName = $vm.CI +"-" + $vm.name
            $VmName = $vm.name
            #Initially it was needed to have a random password for each server hence the line below. But this is handled by GPO now so we can use the same password for all servers
            #$localAdminpwd = $([System.Web.Security.Membership]::GeneratePassword(10,3))
            $localAdminpwd= "Cegeka2018!2019"
            $IPAddress = $vm.IP
            $IPSubnetMask = $vm.subnetmask
            $IPGateway = $vm.DGW
            $MemoryGB = $vm.Vram
            $vCPU = $vm.vCPU
            $vmvlanId = $vm.VLANId
            $vmhost = get-cluster $DestinationCluster | Get-VMHost | Where-Object {$_.connectionState -eq "Connected"} | Get-Random
            $datastore = Get-DatastoreCluster $DestinationStorageCluster | Get-Datastore | Where-Object {$_.FreeSpaceGB -gt 100} | select -First 1
            $disksize = $vm.storage
            
            
            If ($Location -eq "Kortrijk")
                {
                    $IPDNSServer1 = "10.127.37.170"
                    $IPDNSServer2 = "10.127.37.171"
                }
            Else
                {
                    $IPDNSServer1 = "10.127.38.170"
                    $IPDNSServer2 = "10.127.38.171"
                }
            

            If ($vm.OS -eq "Win Svr 2016")
                {
                    #Update the template name should there be a new template or when it's updated.
                    $templateName = "Tmpl_W2016Std_20190114_v1.1"
                    $VMTemplate = Get-Template -Name $templateName
                    Write-Host "Template selected: $VMTemplate"
                    # Create CustomizationSpecs
                    Write-Host -ForegroundColor Green "Create OSCustomizationSpec for $VmName"
                    #change this depending on the fact if the vm needs to join the domain or not.

                    $CustSpec = New-OSCustomizationSpec  -Name $VmName -OSType "Windows" -OrgName "FluviusOT" `
                   -FullName "Administrator" -AdminPassword $localAdminpwd -AutoLogonCount 1 -Description "Temporary Spec for $VmName" -ChangeSid -NamingScheme Fixed `
                    -NamingPrefix $VmName -TimeZone 110 -Domain $domain -DomainCredentials $DomainCredentials -ErrorAction Stop # -Workgroup test 
                    
                    #For debugging I've put a pause till any key is pressed
                    #Read-Host 'Press any key to continue…' | Out-Null
                    
                    <#$CustSpec = New-OSCustomizationSpec  -Name $VmName -OSType "Windows" -OrgName "FluviusOT" `
                   -FullName "Administrator" -AdminPassword $localAdminpwd -AutoLogonCount 1 -Description "Temporary Spec for $VmName" -ChangeSid -NamingScheme Fixed `
                    -NamingPrefix $VmName -TimeZone 110  -Workgroup test  -ErrorAction Stop
		    #>


                    # Set network config
                    Write-Host -ForegroundColor Green "Create network config"
                    Get-OSCustomizationSpec $CustSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
                        -IpMode UseStaticIP `
                        -IPAddress $IPAddress `
                        -SubnetMask $IPSubnetMask `
                        -DefaultGateway $IPGateway `
                        -Dns $IPDNSServer1,$IPDNSServer2 | Out-Null #-ErrorAction:Stop
                    
                    #For debugging I've put a pause till any key is pressed
                    #Read-Host 'Press any key to continue…' | Out-Null
                    

                    
                    # Create VM
                    Write-Host -ForegroundColor Green "Create VM $VmName on $DestinationCluster!!"
   
                    Try {
                                Write-Host -ForegroundColor Green "Creating $vmname with following details: `n On $($vmhost.name) with template $VMTemplate  `n On datastore $datastore with customspec $CustSpec  `n In folder  $Folder  `n Local admin password is $localAdminpwd  `n Ip settings are ip:$IPAddress / subnet:$IPSubnetMask / Gateway:$IPGateway"
                        New-VM -Name $VmName -Template $VMTemplate -VMHost $vmhost.name -Datastore $Datastore -OSCustomizationSpec $CustSpec -Location $Folder #-WhatIf -ErrorAction Continue
                        #For debugging I've put a pause till any key is pressed
                        #Read-Host 'Press any key to continue…' | Out-Null


                    }
                    Catch {
                        Write-Host $_.Exception.Message -foregroundcolor red
                        Continue
                    }
                    Finally {
                        Remove-OSCustomizationSpec $VmName -confirm:$false
                    }
                }
            If ($vm.OS -eq "Windows 10")
                {
                    #Update the template name should there be a new template or when it's updated.
                    $templateName = "Tmpl_Empty_Windows_Vm"
                    $VMTemplate = Get-Template -Name $templateName
                    Write-Host "Template selected: $templateName"
                    # Create VM
                    Write-Host -ForegroundColor Green "Create VM $VmName on $DestinationCluster!!"
                    Try {
                                Write-Host -ForegroundColor Green "Creating $vmname with following details: `n On $($vmhost.name) with template $VMTemplate  `n On datastore $datastore `n In folder  $Folder "
                        New-VM -Name $VmName -Template $VMTemplate -VMHost $vmhost.name -Datastore $Datastore -Location $Folder #-WhatIf 
                        #For debugging I've put a pause till any key is pressed
                        #Read-Host 'Press any key to continue…' | Out-Null

                    }
                    Catch {
                        Write-Host $_.Exception.Message -foregroundcolor red
                        Continue
                    }
                    Finally {
                        #Leaving finally section empty at the moment
                    }

                    #set size hard disk 1
                    #Get-HardDisk $vmname | Set-HardDisk -CapacityGB $disksize -Confirm:$false
                }
            If ($vm.OS -eq "RHEL7")
                {
                    #Update the template name should there be a new template or when it's updated.
                    $templateName = "Tmpl_Empty_Linux_Vm"
                    $VMTemplate = Get-Template -Name $templateName
                    Write-Host "Template selected: $templateName"
                    # Create VM
                    Write-Host -ForegroundColor Green "Create VM $VmName on $DestinationCluster!!"
                    Try {
                                Write-Host -ForegroundColor Green "Creating $vmname with following details: `n On $($vmhost.name) with template $VMTemplate  `n On datastore $datastore `n In folder  $Folder "
                        New-VM -Name $VmName -Template $VMTemplate -VMHost $vmhost.name -Datastore $Datastore -Location $Folder #-WhatIf 
                        #For debugging I've put a pause till any key is pressed
                        #Read-Host 'Press any key to continue…' | Out-Null

                    }
                    Catch {
                        Write-Host $_.Exception.Message -foregroundcolor red
                        Continue
                    }
                    Finally {
                        #Leaving finally section empty at the moment
                    }

                    #set size hard disk 1
                    #Get-HardDisk $vmname | Set-HardDisk -CapacityGB $disksize -Confirm:$false
                }
        
        }
 

    # Set correct Memory & CPU
    Write-Host -ForegroundColor Green "Set $MemoryGB GB Memory & $vCPU vCPU"
    Set-Vm -VM $VmName -MemoryGB $MemoryGB -NumCpu $vCPU -Confirm:$false | Out-Null


    # Set networkadapter
    $vlans = Get-VirtualSwitch -Name $dvswitch | Get-VirtualPortGroup | Select Name, @{N="VLANId";E={$_.Extensiondata.Config.DefaultPortCOnfig.Vlan.VlanId}}
  

    #Write-Host -ForegroundColor Yellow "list of vlans's `n $vlans"
    

    foreach($vlan in $vlans)
        {
            #write-host -ForegroundColor Yellow "compairing $($vlan.vlanid) and $vmlanid"
            if ($vlan.vlanid -eq $vmvlanId)
                {
                  #write-host -ForegroundColor Yellow "$VlanName is the same as $vlan.name"
                  $VlanName = $vlan.name   
                }
        }
    
    Write-Host -ForegroundColor Green "Set network adapter to VLAN $VLANName"
    Get-Vm -name $VmName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $VLANName -Confirm:$false

    
    # Start VM
    Write-Host "Start VM $VmName" -ForegroundColor Green
    Start-Vm -VM $VmName | Out-Null 

    
    #Rename is failing because startup is on going, so a wait of 5 seconds is needed
    Write-host -ForegroundColor Green "Sleeping for 5 seconds to give the vm the time to bootup before rename"
    Start-Sleep -s 5


    # Renaming vm to Cegeka standards
    Write-Host "Renaming vm to Cegeka standards CI+name"
    set-vm $VmName -name $VmvCenterName -confirm:$false
    

    #Disconnect from vcenter
    disconnect-viserver * -force -Confirm:$false

  
}



    








        



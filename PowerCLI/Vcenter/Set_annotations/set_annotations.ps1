<#
.Synopsis
   Created by Remco Dils.
   Use this script to create custom annotions.
.DESCRIPTION
   This script can be used in combination of a CSV file to create our default custom attributed and set them also correctly in vcenter.
   Make sure that the csv file is the same name as the script and in the same folder.
.EXAMPLE
   nothing special to mention here
.EXAMPLE
   
#>
#Function to handle vcenter connection with error catching for wrong username and password but also for unable to contact vcenter.
Function Connection-vCenter
{

    Param 
        (
            [string]$Vcenter
        )

     #Connecting to vcenter Geleen with check for failed logins
                $login = "0"
                While ($login -eq "0")
                    {
                        Try
                            {
                            
                                Write-Host -ForegroundColor Yellow "Connecting to vcenter $vcenter!"
                                Connect-VIServer $Vcenter -user test -ErrorAction stop -WarningAction SilentlyContinue
                                $login = "1"
                            }

                        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]
                            {
                                Write-Host -ForegroundColor Red "Wrong username or password. Please try again!"
                                $login = "0"
                            }
                        Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]
                            {
                                Write-Host -ForegroundColor Red "Not able to connecto to $vCenter"
                                $login = "0"
                                Write-Host -ForegroundColor Yellow "Enter the correct vcenter name to which you want to connect to: " -NoNewline 
                                $vCenter = Read-Host
                            }
                    }
}

#Function to handle progress/error lines
Function Progress ($message) {Write-Host -ForegroundColor Yellow (Get-Date -format "yyyyMMdd-HH.mm.ss -") "$message" `n}
Function Error ($message) {Write-Host -ForegroundColor Red (Get-Date -format "yyyyMMdd-HH.mm.ss -") "$message" `n}
Function Warning ($message) {Write-Host -ForegroundColor DarkYellow (Get-Date -format "yyyyMMdd-HH.mm.ss -") "$message" `n}


#Ask for which vcenter you want to connecto to.
Write-host -ForegroundColor Yellow "Enter the vcenter name to which you want to connect to: " -NoNewline
$vCenter = Read-Host

#Connecting to vcenter using the function above
Connection-vCenter $vCenter

#Set location the same as the folder where the current script is saved
set-location $PSScriptRoot

#Importing CSV file
$CSVfile = "set_annotations.csv"
$ListHosts = Import-Csv $CSVfile -Delimiter ";" | Sort-Object host -Descending

#Array with the customer attributes that will be created.
$CustomAttributes= @("CI-nr Blade","CI-nr Cluster","CI-nr Enclosure")



#Create the custom attributes
ForEach ($CustomAttribute in $CustomAttributes)
    {
        try
        {
            New-CustomAttribute -Name $CustomAttribute -TargetType VMHost -ErrorAction Stop -InformationAction:SilentlyContinue
            #Get-CustomAttribute -name $CustomAttribute | Remove-CustomAttribute -Confirm:$false
        }
        catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.DuplicateName]
        {
            Warning "This custom attribute $CustomAttribute already exist."
        }
    }



    

#getting all hosts of vcenter
ForEach ($VMHost in $listHosts)
    {
    Progress "=============================================="
    Progress "Settins custom attribute for $($VMhost.host)" 
    Set-Annotation -Entity $vmhost.host -CustomAttribute "CI-nr Blade" -Value $VMhost.'CI-nr_Blade' | Out-Null
    Set-Annotation -Entity $vmhost.host -CustomAttribute "CI-nr Cluster" -Value $VMhost.'CI-nr_Cluster' | Out-Null
    Set-Annotation -Entity $vmhost.host -CustomAttribute "CI-nr Enclosure" -Value $VMhost.'CI-nr_Enclosure' | Out-Null
    Progress "Done"
    Progress "=============================================="
    }

#Closing connection to vcenter.
disconnect-viserver -confirm:$false     
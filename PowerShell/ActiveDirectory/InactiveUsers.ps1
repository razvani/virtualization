<#

A few settings need to be adapted before running this script / scheduled task:

    1. Create a BASIC domain user (sa_ad_read)
    2. Update the default domain policy (GPO)
    
        Computer Configuration \ Policies \ Windows Settings \ Security Settings \ Local Policies \ User Rights Assignment

            Log on as a batch job "POCVIRTUAL\sa_ad_read"
            Log on as a service "POCVIRTUAL\sa_ad_read"

    3. Create a scheduled task

        Name

            Query - AD - InactiveUsers

        When running the task, use the following user account

            DOMAIN\sa_ad_read

        Run wheter user is logged on or not
        
        Trigger 
        
            monthly 01-01-2020 at 0:01:00

        Action

            Program/script

                C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

            Arguments
                
                -NoProfile -WindowStyle Hidden -File E:\Scripts\InactiveUsers.ps1

        Settings

            Stop the task if it runs longer than 1 hour
#>

### Timing ###

$DaysOfInactivity = 35
$time = (Get-Date).Adddays(-($DaysOfInactivity)) 
$TimeStamp = Get-Date -Format "yyyyMMdd"

### Location ###

$Location = "E:\Scripts\Exports\"
$FileName = "$Location" + "$TimeStamp" + " InactiveUsers.csv"
$NetBIOSName = (Get-ADDomain).NetBIOSName
$Hostname = Hostname


### Send-MailMessage Parameters ###

$From = "Virtualisatie <virtualisatie@cegeka.com>"
$To = "Virtualisatie <virtualisatie@cegeka.com>"
$Subject = "[PROACTIVE MANAGEMENT] - " + "$NetBIOSName" + " - Users attached to this mail have not logged on since " + "$DaysInactive" + " Days"

$Body = @"
Dear Co, 

Check if the corresponding CEGEKANV account is still active before you disable the user account. 

Best regards,
Virtualization

* script ran on $Hostname
"@

$Attachment = $FileName
$SMTPServer = "smtp.cegeka.be"

Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties LastLogonTimeStamp | select-object Name, SamAccountName, @{Name="LastLogon"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | Export-Csv -Path $FileName -NoTypeInformation

### Wait on file generation ###

Start-Sleep -Seconds 30

### Send Mail ###

Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -Attachments $FileName -SmtpServer $SMTPServer

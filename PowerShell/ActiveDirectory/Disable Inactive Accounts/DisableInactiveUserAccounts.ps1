#################################################################################################################
# Disable users if are not logged on for more than a certain ammount of days and move them in a different OU
# 
# Requires: Windows PowerShell Module for Active Directory
# 
#################################################################################################################
# Variables


$SearchBase="OU=Users,OU=Cegeka,DC=cegekavirtual,DC=local" # User account orgranization unit
$InactiveUsers="OU=Inactive Users,OU=Disabled users,DC=cegekavirtual,DC=local" # Organizational unit to move disabled user account

$smtpServer="smtp.cegeka.be" # SMTP server
$adminEmailAddr = "vCenterAlerts@cegeka.com" #,"Admin2@example.com","Admin3@example.com" #multiple addr allowed but MUST be independent strings separated by comma
$from = "Shared.Cegekavirtual.Administrator <no-reply@cegeka.com>"

$testing = $true # Set to $true to not disable Users

$xDays = 186 # Ammount of days for user accounts not logged on
$logFile = "Logs\DisabledInactiveUserAccounts_log.csv"

$exceptionUsersList = "DisableInactiveUserAccounts_ExceptionUsersList.csv"  # The excepted user list.   SAMAccountName
#################################################################################################################

# Set location the same as the folder where the current script is located
Set-Location $PSScriptRoot

# Import the list of users that will be excepted
$exceptedUsers = Import-Csv -Path $exceptionUsersList

# System Settings
$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -format yyyy-MM-dd

# Domain name
$DomainName = Get-ADDomainController | Select-Object Name, Domain
$domain = ($DomainName.Domain).split(".")[0]

$users = Get-ADUser -SearchBase $SearchBase -SearchScope Subtree -Filter {(Enabled -eq $true)} -Properties sAMAccountName, displayName, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress, lastLogon, whenCreated, LastLogonDate

$notLoggedOnForXdays = (get-date).adddays(-$xDays)

# Initializing the counters
$counterNeverLoggedOn = 0
$counternotLoggedOnForXdays = 0

# Count all users that will be processed
$countprocessed=${users}.Count
Write-Host `Users to process: ` -ForegroundColor Cyan $countprocessed


# Create CSV Log
Out-File $logfile
Add-Content $logfile "`"Date`",`"SAMAccountName`",`"DisplayName`",`"Created`",`"PasswordSetDate`",`"LastLogonDate`",`"Details`""

$found = $false;

foreach ($user in $users) {
    $dName = $user.displayName
    $sName = $user.sAMAccountName
    $whencreated = $user.whencreated
    $passwordSetDate = $user.PasswordLastSet
    $LastLogonDate = $user.LastLogonDate

    
    If ($LastLogonDate -eq $null -and !($exceptedUsers -match $sName)) {
        # Write-Host "$dName Account=$sName AccountCreated=$whencreated PasswordSetDate=$passwordSetDate LastLogonDate=$LastLogonDate`n" -ForegroundColor Yellow
        $counterNeverLoggedOn++
        
        if($testing -eq $false) {
        
            # Disable user account
            Disable-ADAccount $user
            
            # Move user account
            Get-ADUser $user | Move-ADObject -TargetPath $InactiveUsers
        };

        # Logging
        Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$LastLogonDate`",`"Account was disabled`""
        
        $found = $true;

    } ElseIf ($LastLogonDate -le $notLoggedOnForXdays -and !($exceptedUsers -match $sName)) {
        # Write-Host "$dName Account=$sName AccountCreated=$whencreated PasswordSetDate=$passwordSetDate LastLogonDate=$LastLogonDate`n" -ForegroundColor Yellow
        $counternotLoggedOnForXdays++

        if($testing -eq $false) {
        
            # Disable user account
            Disable-ADAccount $user
            
            # Move user account
            Get-ADUser $user | Move-ADObject -TargetPath $InactiveUsers
        };

        # Logging
        Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$LastLogonDate`",`"Account was disabled`""
        
        $found = $true;

    }

} # End User Processing


Write-Host `Never logged on: ` $counterNeverLoggedOn ` users`
Write-Host `Not logged on for` $xDays `days:` $counternotLoggedOnForXdays ` users`


##############################################
# Send mail message 

$subject = "[$domain] Disabled accounts not logged on for more than $xDays days"
    # Email Body Set Here, Note You can use HTML, including Images.

$body="
    <p>Hello,<br></p>

    <p>In attachment you can find the accounts that are not logged on for more than $xDays days.</p>
    <p>These accounts have been disabled and moved to $InactiveUsers organizataional unit.</br>
    Total <b>active</b> user accounts: $countprocessed</br>
    Never logged on users: $counterNeverLoggedOn</br>
    Not logged on for $xDays days: $counternotLoggedOnForXdays</br>

    <p>This is an automatic email sent from $env:computername.</p>

    <p>Kind regards,<br>
    Virtualization team<br>
    </p>
    "

if ($found) {
    Send-Mailmessage -smtpServer $smtpServer -from $from -to $adminEmailAddr -subject $subject -body $body -bodyasHTML -Attachments "$logFile" -priority High -Encoding $textEncoding -ErrorAction Stop -ErrorVariable err
};
##############################################
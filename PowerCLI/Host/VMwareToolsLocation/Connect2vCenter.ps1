# Connect to vCenter

Function Connect2vCenter
{
    Param 
        (
            [string]$vCenter,
            [System.Management.Automation.PSCredential]$Credential
        )

    # Connecting to vCenter with check for failed logins
    $login = "0"
    While ($login -eq "0") {
        Try {
            Write-Host -ForegroundColor Green "`r`nConnecting to vCenter $vCenter"
            Connect-VIServer $vCenter -Credential $Credential -ErrorAction Stop -WarningAction SilentlyContinue -AllLinked:$true
            $login = "1"
        }
        Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin] {
            Write-Host -ForegroundColor Red "Wrong username or password. Please try again!"
            $login = "0"
            Write-host -ForegroundColor Green "Enter correct username and password to make a connection to vCenter!"
            $Credential = Get-Credential -Message "Enter correct username name and password for vCenter!"
            $script:vCenterCredentials = $Credential
        }
    }
}
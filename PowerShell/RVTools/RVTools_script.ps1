# =============================================================================================================
# Script:    RVTools_script.ps1
# Version:   1.0
# Date:      27/10/2022
# =============================================================================================================
<#
.SYNOPSIS
With this RVTools Automation script, you can start the RVTools export to xlsx function for one vCenter server.

.DESCRIPTION
With this RVTools Automation script, you can start the RVTools export to xlsx function for one vCenter server.

.EXAMPLE
 .\RVTools_script.ps1 -vc 'vCenter.virtual.local' -u 'usernmae' -p 'password1' -d 'R:\RVTools_files\vCenter\'
#>

# Parameters
param (
    [String]$vc, # vCenter FQDN
    [String]$u,  # User account
    [String]$p,  # Account encryted password
    [String]$d   # Export directory path
)

# Set RVTools directory path
[string] $RVToolsFolderPath = 'D:\RVTools\'

# =============================================================================================================


[string] $RVTools = $RVToolsFolderPath + 'RVTools.exe'

# Set the running script directory
Set-Location -Path $RVToolsFolderPath  

# RVTools arguments
$Arguments = "-u $u -p $p -s $vc -c ExportAll2xlsx -d $d"

# Debugging
#Write-host $RVTools $Arguments

# Runs the RVTools process with all arguments from above
$Process = Start-Process -FilePath "$RVTools" -ArgumentList $Arguments -PassThru
Wait-Process -InputObject $Process

if ($Process.ExitCode -eq -1) {
    Write-Host "$vc : Connection FAILED!"
    exit 1
} elseif ($Process.ExitCode -eq 0) {
    Write-Host "$vc : Export Successful"
} else {
    Write-Warning "$Process exited with status code $($Process.ExitCode)"
    exit 1
}

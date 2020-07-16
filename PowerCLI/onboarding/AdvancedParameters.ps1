# VARS
$VIServerName = "vcenter.domain.com"
$VIUser = "username"

### VM Information ###
$VMNames = @("SERVER001", "SERVER002", "SERVER003", "SERVER004", "SERVER005")


### Connect-vCenter ###

Try
{
    Connect-VIServer -Server $VIServerName -AllLinked -Credential (Get-Credential -UserName $VIUser -Message "Please supply username and password for connection to $VIServerName")
}
Catch
{
    Write-Warning "Failed connecting to $VIServerName : $($_.Exception.Message)"
}



### Advanced Parameters ###

$DCMHash = @{

    'ctkEnabled' = 'TRUE'
    'evcCompatibilityMode' = 'TRUE'
    'isolation.bios.bbs.disable' = 'TRUE'
    'isolation.device.connectable.disable' = 'TRUE'
    'isolation.device.edit.disable' = 'TRUE'
    'isolation.ghi.host.shellAction.disable' = 'TRUE'
    'isolation.tools.diskShrink.disable' = 'TRUE'
    'isolation.tools.dispTopoRequest.disable' = 'TRUE'
    'isolation.tools.getCreds.disable' = 'TRUE'
    'isolation.tools.ghi.autologon.disable' = 'TRUE'
    'isolation.tools.ghi.launchmenu.change' = 'TRUE'
    'isolation.tools.ghi.protocolhandler.info.disable' = 'TRUE'
    'isolation.tools.ghi.trayicon.disable' = 'TRUE'
    'isolation.tools.guestDnDVersionSet.disable' = 'TRUE'
    'isolation.tools.hgfsServerSet.disable' = 'TRUE'
    'isolation.tools.memSchedFakeSampleStats.disable' = 'TRUE'
    'isolation.tools.trashFolderState.disable' = 'TRUE'
    'isolation.tools.unity.disable' = 'TRUE'
    'isolation.tools.unity.push.update.disable' = 'TRUE'
    'isolation.tools.unity.taskbar.disable' = 'TRUE'
    'isolation.tools.unity.windowContents.disable' = 'TRUE'
    'isolation.tools.unityActive.disable' = 'TRUE'
    'isolation.tools.unityInterlockOperation.disable' = 'TRUE'
    'isolation.tools.vixMessage.disable' = 'TRUE'
    'isolation.tools.vmxDnDVersionGet.disable' = 'TRUE'
    'log.keepOld' = '10'
    'log.rotateSize' = '1024000'
    'mks.enable3d' = 'FALSE'
    'tools.guestlib.enableHostInfo' = 'FALSE'
}

$VMCount = $VMNames.Count
$VMProcessed = 0
ForEach($VM in $VMNames) {
    Write-Progress -Activity "Checking advanced settings" -PercentComplete ($VMProcessed*100/$VMCount) -Status "Processing VM $VM" -CurrentOperation "Getting existing advanced settings"
    Try
    {
        $VMAdvancedSettings = Get-AdvancedSetting -Entity $VM -ErrorAction Stop
    }
    Catch
    {
        Write-Warning "Failed to get Advanced settings for $VM : $($_.Exception.Message)"
        continue
    }
    
    
    $VMAdvancedSettingsHash = @{}
    foreach ($VMAdvancedSetting in $VMAdvancedSettings)
    {
        $VMAdvancedSettingsHash.Add($VMAdvancedSetting.Name,$VMAdvancedSetting.Value)
    }
    $VMProcessed++
    $SettingCount = $DCMHash.Count
    $SettingsProcessed = 0
    foreach($SettingName in @($DCMHash.Keys))
    {
        Write-Progress -Activity "Apply DCM on VM" -PercentComplete ($SettingsProcessed*100/$SettingCount) -Status "Processing advanced settings for $VM"
        if($VMAdvancedSettingsHash[$SettingName])
        {
            #AdvancedSetting found
            if($VMAdvancedSettingsHash[$SettingName] -ne $DCMHash[$SettingName])
            {
                #AdvancedSetting value needs update
                Try
                {
                    Write-Progress -Activity "Apply DCM on VM" -PercentComplete ($SettingsProcessed*100/$SettingCount) -Status "Processing advanced settings for $VM" -CurrentOperation "Updating setting $SettingName"
                    $VMAdvancedSettings | Where-Object {($_.Name) -eq $SettingName} | Set-AdvancedSetting -Value $DCMHash[$SettingName] -Confirm:$false | Out-Null
                    $Result = "Succes"
                }
                Catch
                {
                    Write-Warning "Failed to update setting $SettingName to value $DCMHash[$SettingName] for VM $VM with error: $($_.Exception.Message)"
                    $Result = "Failed"
                }
                $SettingName | Select-Object @{N="Entity";E={$VM}},@{N="SettingName";E={$SettingName}},@{N="Old Value";E={$VMAdvancedSettingsHash[$SettingName]}},@{N="New Value";E={$DCMHash[$SettingName]}},@{N="Action";E={"Update"}},@{N="Result";E={$Result}}

            }
            else
            {
                #AdvancedSetting value is correct
                $Result = "Success"
                $SettingName | Select-Object @{N="Entity";E={$VM}},@{N="SettingName";E={$SettingName}},@{N="Old Value";E={$VMAdvancedSettingsHash[$SettingName]}},@{N="New Value";E={$DCMHash[$SettingName]}},@{N="Action";E={"No Change"}},@{N="Result";E={$Result}}

            }
        }
        else
        {
            #AdvancedSetting is missing
            Try
            {
                Write-Progress -Activity "Apply DCM on VM" -PercentComplete ($SettingsProcessed*100/$SettingCount) -Status "Processing advanced settings for $VM" -CurrentOperation "Creating new setting $SettingName"
                New-AdvancedSetting -Entity $VM -Name $SettingName -Value $DCMHash[$SettingName] -Confirm:$false | Out-Null
                $Result = "Success"
            }
            Catch
            {
               Write-Warning "Failed to create setting $SettingName with value $DCMHash[$SettingName] for VM $VM with error: $($_.Exception.Message)"
               $Result = "Failed"
            }
            $SettingName | Select-Object @{N="Entity";E={$VM}},@{N="SettingName";E={$SettingName}},@{N="Old Value";E={$null}},@{N="New Value";E={$DCMHash[$SettingName]}},@{N="Action";E={"New"}},@{N="Result";E={$Result}}
        }
        $SettingsProcessed++
    }
}

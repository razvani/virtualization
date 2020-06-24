### VM Information ###

$VMName = Read-Host "VMName e.g. CI000000-VMName"

### Advanced Parameters ###

$DesiredConfig = @(

    @{

        Name = 'ctkEnabled'
        Value = 'TRUE'

        },

    @{

        Name = 'evcCompatibilityMode'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.bios.bbs.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.device.connectable.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.device.edit.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.ghi.host.shellAction.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.diskShrink.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.dispTopoRequest.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.getCreds.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.ghi.autologon.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.ghi.launchmenu.change'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.ghi.protocolhandler.info.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.ghi.trayicon.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.guestDnDVersionSet.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.hgfsServerSet.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.memSchedFakeSampleStats.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.trashFolderState.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unity.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unity.push.update.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unity.taskbar.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unity.windowContents.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unityActive.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.unityInterlockOperation.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.vixMessage.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'isolation.tools.vmxDnDVersionGet.disable'
        Value = 'TRUE'

    },

    @{

        Name = 'log.keepOld'
        Value = '10'

    },

    @{

        Name = 'log.rotateSize'
        Value = '1024000'

    },

    @{

        Name = 'mks.enable3d'
        Value = 'FALSE'

    },

    @{

        Name = 'tools.guestlib.enableHostInfo'
        Value = 'FALSE'

    }
)

ForEach($VM in $VMName) {

    $DesiredConfig | %{

        $setting = Get-AdvancedSetting -Entity $vm -Name $_.Name

        if($setting){

            if($setting.Value -eq $_.Value){

                Write-Output "Setting $($_.Name) present and set correctly"

            }

            else{

                Write-Output "Setting $($_.Name) present but not set correctly" 

                Set-AdvancedSetting -AdvancedSetting $setting -Value $_.Value -Confirm:$false

            }

        }

        else{

            Write-Output "Setting $($_.Name) not present."

            New-AdvancedSetting -Name $_.Name -Value $_.Value -Entity $vm -Confirm:$false

        }

    }

}

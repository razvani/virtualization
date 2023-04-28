#
# You need to be connected to only one vCenter connection. Script doesn't work with "Connect-VIServer -AllLinked:$true"
#
#

# Group name
$groupName = "CEGEKAVIRTUAL\GG-CI00286195-VRPL-INTE"

# Get the Authentication Manager
$serviceInstance = Get-View ServiceInstance -ErrorAction Stop
$authMgr = Get-View -Id $serviceInstance.Content.AuthorizationManager -ErrorAction Stop

# You can user account also but you need to change the parameter '1' value with '0' from line 25 (RemoveEntityPermission)
# Get the group object
$group = Get-VIAccount -Group -Name $groupName


## You can use this script for other objects. All you need to do is to replace the get objects and foreach loop ##
# Get portgroups objects
$pgs = Get-VDPortgroup

foreach ($pg in $pgs){
	try{
		# Remove Permission from portgroup
		$authMgr.RemoveEntityPermission($pg.ExtensionData.MoRef,$group,1)
	}
	catch {
		<#Do nothing. Portgroup does not have permission asigned for $groupName #>
	}

}

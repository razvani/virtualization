#first connect to correct vcenter
#Create on each host in a cluster (a) new portgroup(s) on an existing standard switch

$clusterName = "POCBEHACLU_MIX_01"
$vSwitch="vSwitchMig"
$vlans = 123,456

foreach($esx in (Get-Cluster -Name $clusterName | Get-VMHost)){
    $vSw = $esx | Get-VirtualSwitch -Name $vSwitch
    $vlans | %{
        New-VirtualPortGroup -Name "$($_)_Kris" -VLanId $_ -VirtualSwitch $vSw -Confirm:$false #this will create "123_Kris" with vlan 123 and "456_Kris" with vlan 456
    }
}

#first connect to correct vcenter
#remove (a) portgroup(s) on a standard switch on each host in a datacenter
#select only the datacenter to which you vcenter is connected

#$Datacenter="STAGING_HASSELT"
#$Datacenter="CGK_SHAR_HASSELT"
$Datacenter="CGK_SHAR_GELEEN"
$vSwitch="vSwitchMig"
$VirtualPortGroup="642_nl_asp_rws","1268_terumo_sap_gtwy","1323_nibc_dmz_webacc","1941_nl_asp_leystromen","1951_nl_asp_elan_tst2","1999_nl_huis_itris"

    foreach ($PG in $VirtualPortGroup) {
        Get-Datacenter -Name $Datacenter | Get-VMHost | Get-VirtualSwitch -Name $vSwitch |Get-VirtualPortGroup -Name $PG | Remove-VirtualPortGroup -Confirm:$false
    }

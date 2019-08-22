$ImportFile = '.\veeamjobs.csv'
Import-csv $ImportFile -delimiter ";" | ForEach-Object {

#### Migration Host ####
$MIGhost = Get-VBRServer -Type ESXi -Name $_.MIGhost

#### Migration Datastore ####
$MIGdatastore = Find-VBRViDatastore -Server $MIGhost -Name $_.MIGdatastore

#### DiskType ####
$DiskType = "Thick" #default Thick uses Lazy Zeroed > ThickEaggerZeroed can be used as well

#### Migration Folder name NIBC ####
$MIGfolder = Find-VBRViFolder -Server $MIGhost -Name $_.Iteration

#### Migration Resource Pool ####
$MIGresourcePool = Find-VBRViResourcePool -Server $MIGhost -Name $_.Iteration

#### Create Replication JOB ####
#### VMname ####
$VMname = Find-VBRViEntity -Server $_.SourcevCenter -Name $_.VMname
#### Jobname ####
$RepJobName = $_.IterationName
#### SourceProxy ####
$ObjSourceProxy = @()
$ObjSourceProxy += Get-VBRViProxy -Name $_.SourceProxy01
IF(![string]::IsNullOrEmpty($_.SourceProxy02)) { $ObjSourceProxy += Get-VBRViProxy -Name $_.SourceProxy02 }

#### Create Replication Job ####
Add-VBRViReplicaJob -Entity $VMname -Name $RepJobName -Server $MIGhost -Datastore $MIGdatastore -DiskType $DiskType -ResourcePool $MIGResourcePool -Folder $MIGfolder -Suffix "_replica" -RestorePointsToKeep 1 -SourceProxy $ObjSourceProxy -Description "migration to Cegeka"

#### Set the job Schedule ####

if ($_.PrimaryJob -like "No") {
$AfterJob = Get-VBRJob -Name $_.AfterJobName
Get-VBRJob -Name $RepJobName | Set-VBRJobSchedule -After -AfterJob $AfterJob | Enable-VBRJobSchedule ;  New-VBRBackupWindowOptions -FromDay Sunday -FromHour 6 -ToDay Saturday -ToHour 18 -enabled
}

elseif ($_.PrimaryJob -like "Yes") 
{
Get-VBRJob -Name $RepJobName | Set-VBRJobSchedule -Daily -At $_.DailyAt | Enable-VBRJobSchedule ;  New-VBRBackupWindowOptions -FromDay Sunday -FromHour 6 -ToDay Saturday -ToHour 18 -enabled
}

} 


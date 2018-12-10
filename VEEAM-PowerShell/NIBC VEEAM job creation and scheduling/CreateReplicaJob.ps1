#NIBC VEEAM job creation and scheduling

$ImportFile = '.\VM_jobs.csv'
Import-csv $ImportFile | ForEach-Object {

#Migration Host
$MIGhost = Get-VBRServer -Type ESXi -Name $_.MIGhost

#Migration Datastore
$MIGdatastore = Find-VBRViDatastore -Server $MIGhost -Name $_.MIGdatastore

#Migration Folder name NIBC
$MIGfolder = Find-VBRViFolder -Server $MIGhost -Name NIBC

#### Create Replication JOB
# VMname
$VMname = Find-VBRViEntity -Server $_.NIBCvCenter -Name $_.VMname
# Jobname
$RepJobName = $_.IterationName + "-" + $_.VMname
# SourceProxy
$ObjSourceProxy = @()
$ObjSourceProxy += Get-VBRViProxy -Name $_.SourceProxy01
IF(![string]::IsNullOrEmpty($_.SourceProxy02)) { $ObjSourceProxy += Get-VBRViProxy -Name $_.SourceProxy02 }

# Create Replication Job
Add-VBRViReplicaJob -Entity $VMname -Name $RepJobName -Server $MIGhost -Datastore $MIGdatastore -Folder $MIGfolder -Suffix "_replica" -RestorePointsToKeep 1 -SourceProxy $ObjSourceProxy

# Set the job Schedule

if ($_.PrimaryJob -like "No") {
$AfterJob = Get-VBRJob -Name $_.AfterJobName
Get-VBRJob -Name $RepJobName | Set-VBRJobSchedule -After -AfterJob $AfterJob | Enable-VBRJobSchedule
}
elseif ($_.PrimaryJob -like "Yes") 
{
Get-VBRJob -Name $RepJobName | Set-VBRJobSchedule -Daily -At $_.DailyAt | Enable-VBRJobSchedule
}


}

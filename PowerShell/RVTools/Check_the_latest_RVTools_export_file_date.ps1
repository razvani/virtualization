$path = 'R:\RVTools_files\'

$vCenters = Get-ChildItem -Path $path | Sort-Object -Property Name | select Name

foreach ($vCenter in $vCenters) {

    $vCentersRVToolsPath = $path + $vCenter.Name
    
    if ($vCenter.Name -NotLike '_Archive' ){

        $start = Get-ChildItem -Path $vCentersRVToolsPath -File | Sort-Object -Property CreationTime | Select-Object -ExpandProperty CreationTime -Last 1  
        $end = Get-Date  
        $numberOfDays = (New-TimeSpan -Start $start -End $end).Days

        Write-host "`n"$vCenter.Name
        Write-host $numberOfDays "days passed from the last export."
    
        if ($numberOfDays -gt 0){

            Write-host "`n`n Check RVTools export for vCenter" $vCenter.Name "in folder" $vCentersRVToolsPath "on SHARBEHAPSH101.`n`n"

            throw "Check RVTools export for vCenter!"
        }

     }

}


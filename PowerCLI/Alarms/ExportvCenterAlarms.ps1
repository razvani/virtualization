$output = foreach ($alarm in (Get-AlarmDefinition | Sort Name | Get-AlarmAction))

{

    $threshold = foreach ($expression in ($alarm | %{$_.AlarmDefinition.ExtensionData.Info.Expression.Expression}))

    {

        if ($expression.EventTypeId -or ($expression | %{$_.Expression}))

        {

            if ($expression.Status) { switch ($expression.Status) { "red" {$status = "Alert"} "yellow" {$status = "Warning"} "green" {$status = "Normal"}}; "" + $status + ": " + $expression.EventTypeId } else { $expression.EventTypeId }         

        }

        elseif ($expression.EventType)

        {

            $expression.EventType

        }

        if ($expression.Yellow -and $expression.Red)

        {

            if (!$expression.Yellow) { $warning = "Warning: " + $expression.Operator } else { $warning = "Warning: " + $expression.Operator + " to " + $expression.Yellow };

            if (!$expression.Red) { $alert = "Alert: " + $expression.Operator } else { $alert = "Alert: " + $expression.Operator + " to " + $expression.Red };

            $warning + " " + $alert

        }

    }  
 

    $alarm | Select-Object @{N="Alarm";E={$alarm | %{$_.AlarmDefinition.Name}}},

                           @{N="Description";E={$alarm | %{$_.AlarmDefinition.Description}}},

                           @{N="Threshold";E={[string]::Join(" // ", ($threshold))}},

                           @{N="Action";E={if ($alarm.ActionType -match "SendEmail") { "" + $alarm.ActionType + " to " + $alarm.To } else { "" + $alarm.ActionType }}}

}

    
$output | Export-Csv alarm.csv -UseCulture -NoTypeInformation
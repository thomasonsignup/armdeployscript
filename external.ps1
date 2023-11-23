$Headers = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token)" }
if ($EnvOutput) { 
    $EnvOutput = "Environment var exists" 
}
else { 
    $EnvOutput = "Environment var no exists" 
}
$App = Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$($AppDisplayName)'" -Headers $Headers -ContentType "application/json"
$AppOutput = $app | ConvertTo-Json
If ([string]::IsNullOrEmpty($app.value)) {
    $output = "Create new app"
    Write-Output $output
}
else {
    $output = "Fix existing"
    Write-Output $output
}

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['AppStatus'] = $output
$DeploymentScriptOutputs['EnvOutput'] = $EnvOutput
$DeploymentScriptOutputs['AppOutput'] = $AppOutput

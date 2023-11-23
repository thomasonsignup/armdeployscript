$Headers = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token)" }
$AppDisplayName = "SignupSoftwareAB-ExFlowCloud-FO-72b08bde-b1b7-4138-a615-9f6790947849"
$EnvOutput = ${Env:AzureADApplicationName}
Write-output "this is verification"
if (!($EnvOutput)) { 
    $EnvOutput = "no environment output" 
}
else { 
    Write-Output $EnvOutput
    $EnvOutput = "environment output hit else clause" 
}
$App = Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$($AppDisplayName)'" -Headers $Headers -ContentType "application/json"

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

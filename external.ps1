param([string] $azureADApplicationName)
$Headers = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token)" }

$App = Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$($AazureADApplicationName)'" -Headers $Headers -ContentType "application/json"

If ([string]::IsNullOrEmpty($app.value)) {
    $output = "Create new app"
    Write-Output $output
} else {
    $output = "Fix existing"
    Write-Output $output
}

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['AppStatus'] = $output

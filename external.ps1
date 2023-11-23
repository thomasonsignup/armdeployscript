$Headers = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token)" }
$AppDisplayName = "SignupSoftwareAB-ExFlowCloud-FO-72b08bde-b1b7-4138-a615-9f6790947849"
$App = Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$($AppDisplayName)'" -Headers $Headers -ContentType "application/json"

If ([string]::IsNullOrEmpty($app.value)) {
    Write-Output "Create new app"
} else {
    Write-Output "Fix existing"
}

param(
    [string]$Dynamics,
    [string]$TenantId,
    [string]$Appid,
    [string]$customerName,
    [string]$dnsDomainName,
    [string]$WebVersionName,
    [string]$IntermediateVaultUrl
)
$Headers = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token)" }
$AppDisplayName = "SignupSoftwareAB-ExFlowCloud-$Dynamics-$TenantId"
Switch ($WebVersionName) {
    vOld { $replyUrlEndpoint = "inbox.aspx" }
    vNext { $replyUrlEndpoint = "signin-oidc" } 
}

$CustomerUrl = "https://" + $customerName + ".$dnsDomainName/$replyUrlEndpoint"
$App = (Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$($AppDisplayName)'" -Headers $Headers -ContentType "application/json").value

If (-not($app)) {
    $output = "Create new app"
    Write-Output $output
    # Required Resource Access
    # Graph Permissions (Default for all)
    $GraphAccess = '{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"},{"id":"b340eb25-3456-403f-be2f-af7a0d370277","type":"Scope"}]}' | ConvertFrom-Json

    # ERP Permissions
    Switch ($Dynamics) {
        BCOnprem { $ERPAccess = "" <#No resource access needed (yet?)#> }
        BC { $ERPAccess = '{"resourceAppId":"996def3d-b36c-4153-8607-a6fd3c01b89f","resourceAccess":[{"id":"a42b0b75-311e-488d-b67e-8fe84f924341","type":"Role"}]}' } 
        FO { $ERPAccess = '{"resourceAppId":"00000015-0000-0000-c000-000000000000","resourceAccess":[{"id":"6397893c-2260-496b-a41d-2f1f15b16ff3","type":"Scope"},{"id":"a849e696-ce45-464a-81de-e5c5b45519c1","type":"Scope"},{"id":"ad8b4a5c-eecd-431a-a46f-33c060012ae1","type":"Scope"}]}' } 
    }
    $ERPAccess = $ERPAccess | ConvertFrom-Json
    $requiredResourceAccess = @($GraphAccess; $ERPAccess) 
    $web = @{
        'homePageUrl'           = 'http://localhost'
        'implicitGrantSettings' = @{
            'enableIdTokenIssuance' = 'True'
        }
        'redirectUris'          = @('https://consent.$dnsDomainName')
    }
  
    $AppObject = [pscustomobject]@{
        displayName            = $AppDisplayName
        requiredResourceAccess = $requiredResourceAccess
        signInAudience         = "AzureADMultipleOrgs"
        web                    = $web
    }
    $body = $AppObject | ConvertTo-Json -Depth 10

    $App = Invoke-RestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/applications" -body $body -Headers $Headers -ContentType "application/json"
}

# Add reply URL if not exists 
If ($app.Web.redirectUris -notcontains $CustomerUrl) {
    $app.Web.redirectUris += $customerUrl
    $body = @{'web' = @{'redirectUris' = $app.Web.redirectUris } } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method PATCH -Uri "https://graph.microsoft.com/v1.0/applications/$($App.id)" -body $body -Headers $Headers -ContentType "application/json"
}

# Add App Password if not exists
if ($App.passwordCredentials.displayName -notcontains $customerName) {
    $body = @{'passwordCredential' = @{'displayName' = $customerName } } | ConvertTo-Json -Depth 10
    $clientSecret = Invoke-RestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/applications/$($App.id)/addPassword" -body $body -Headers $Headers -ContentType "application/json"
}

# Set secret in KV?
$KvHeaders = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl 'https://vault.azure.net').Token)" }
$body = @{value = $clientSecret.SecretText; contentType = $clientSecret.keyId } | ConvertTo-Json
Invoke-RestMethod -Method PUT -Uri "$IntermediateVaultUrl/secrets/$($customerName)?api-version=7.4" -body $body -Headers $KvHeaders -ContentType "application/json"
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ClientId'] = $app.appid
$DeploymentScriptOutputs['AdminConsent'] = "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=$($app.appid)&state=$($customerName + ".$dnsDomainName")&redirect_uri=https://consent.$dnsDomainName&scope=https://erp.dynamics.com/.default"
$DeploymentScriptOutputs['ClientSecret'] = $clientSecret.SecretText
$DeploymentScriptOutputs

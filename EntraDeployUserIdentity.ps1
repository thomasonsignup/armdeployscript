# https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/deployment-script-azcli-graph-azure-ad/
#Create managed user identity for Scripts
$managedIdentityName = 'xfw-deploy-EntraApp-MUI'
$resourceGroupName = 'xfw-Automation-Resources'
$location = 'westeurope'

$userAssignedIdentity = New-AzUserAssignedIdentity `
  -Name $managedIdentityName `
  -ResourceGroupName $resourceGroupName `
  -Location $location
$managedIdentityObjectId = $userAssignedIdentity.PrincipalId

$tenantID = '7a4ea3a9-b367-4611-b1b5-1622bf4d47d3'
Connect-MgGraph -TenantId $tenantID -Scopes "Directory.AccessAsUser.All"

# Get the app role for the Graph API.
$graphAppId = '00000003-0000-0000-c000-000000000000' # This is a well-known Microsoft Graph application ID.
$graphApiAppRoleName = 'Application.ReadWrite.All'
$graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"
$graphApiAppRole = $graphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $graphApiAppRoleName -and $_.AllowedMemberTypes -contains "Application"}

# Assign the role to the managed identity.
New-MgServicePrincipalAppRoleAssignment `
  -ServicePrincipalId $managedIdentityObjectId `
  -PrincipalId $managedIdentityObjectId `
  -ResourceId $graphServicePrincipal.Id `
  -AppRoleId $graphApiAppRole.Id
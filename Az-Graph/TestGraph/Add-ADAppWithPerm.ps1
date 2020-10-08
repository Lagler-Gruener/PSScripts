Install-Module AzureAD -ErrorAction SilentlyContinue
Import-Module AzureAD

$tenant = Connect-AzureAD
$tenantId = $tenant.TenantId
$appName = "TestApp"
if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $appName
}
$clientId = $myApp.AppId
$objectId = $myApp.ObjectId
$startDate = Get-Date
$endDate = $startDate.AddYears(100)
$aadAppsecret01 = New-AzureADApplicationPasswordCredential -ObjectId $myApp.ObjectId -CustomKeyIdentifier "Secret01" -StartDate $startDate -EndDate $endDate
$AppSecret = $aadAppsecret01.Value

#get full_access_as_app ROLE
$prinicpal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Office 365 Exchange Online" }
$role = $prinicpal.AppRoles | ? { $_.Value -match "full_access_as_app" }


#add permissions
$exi = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$exi.ResourceAppId = $prinicpal.AppId

$perm = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $role.Id, "Role"
$exi.ResourceAccess = $perm

Set-AzureADApplication -ObjectId $myApp.ObjectId -RequiredResourceAccess $exi





$t = $(Get-AzureADApplication -ObjectId $myApp.ObjectId).RequiredResourceAccess





$body = @{
    clientId    = $clientID
    consentType = "AllPrincipals"
    principalId = $null
    resourceId  = $resourceID
    scope       = "full_access_as_app"
    startTime   = "2019-10-19T10:37:00Z"
    expiryTime  = "2019-10-19T10:37:00Z"
}


$apiUrl = "https://graph.microsoft.com/beta/oauth2PermissionGrants"
Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization = "Bearer $($token)" } -Method POST -Body $($body | convertto-json) -ContentType "application/json"

$url = "https://graph.microsoft.com/v1.0/users"
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = "Bearer $token"} 


$clientID = "d1f8f3dc-2047-4429-a6dd-fa3461c19f8e"
$tenantName = "acpdemot.onmicrosoft.com"
$ClientSecret = "35._RQ1Hvj~mxjo~6Z5O46OGVWuIq~2DW-"
$Username = "admin@demo.acp.at"
$Password = "Tdegfur62384Fstw01938s--"
 
 
$ReqTokenBody = @{
    Grant_Type    = "Password"
    client_Id     = $clientID
    Client_Secret = $clientSecret
    Username      = $Username
    Password      = $Password
    Scope         = "https://graph.microsoft.com/.default"
} 
 
$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody




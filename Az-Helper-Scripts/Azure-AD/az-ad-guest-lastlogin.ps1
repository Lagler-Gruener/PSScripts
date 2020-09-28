<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES  
        Minimum req. Azure AD P1 Lizenz
        Max. 30 Days back
        
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $UPN
)

#######################################################################################################################
#region define global variables

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#endregion
#######################################################################################################################

#######################################################################################################################
#region Functions

#login to azure and get access token
function get-msgraphtoken
{
<#
    SYNOPSIS
        This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
        The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
        Get-AuthToken
    Authenticates you with the Graph API interface
        .NOTES
    NAME: Get-AuthToken
#>

    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('delegated','delegatedwithadminconsent','application')]
        $Connectiontype,
        [Parameter(Mandatory=$true)]
        $UserUPN,
        [Parameter(Mandatory=$true)]
        $AppId,
        [Parameter(Mandatory=$true)]
        $AppSecred,
        [Parameter(Mandatory=$true)]
        $Tenant
    )

    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    switch ($Connectiontype)
    {
        application
        {
            $body = @{grant_type="client_credentials";resource=$resourceAppIdURI;client_id=$AppId;client_secret=$AppSecred}
            $oauth = Invoke-RestMethod -Method Post -Uri $authority/oauth2/token?api-version=1.0 -Body $body

            if($oauth.access_token)
            {
                # Creating header for Authorization token

                $authHeader = @{
                        'Content-Type'='application/json'
                        'Authorization'="Bearer " + $oauth.access_token
                        'ExpiresOn'= $oauth.expires_on
                }

                return $authHeader
            }
            else 
            {
                Write-Host
                Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                Write-Host
                break
            }
        }
        default
        {
            Write-Host "start with delegated authentication"
            $AadModule = Get-Module -Name "AzureAD" -ListAvailable
            if($AadModule.count -gt 1){

                $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
                $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
         
                    # Checking if there are multiple versions of the same module found
                    if($AadModule.count -gt 1)
                    {
                        $aadModule = $AadModule | select -Unique
                    }

                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }
            else
            {
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }

            [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

            [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null


            try {
                $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

                # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
                # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

                $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

                $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($UserUPN, "OptionalDisplayableId")

                if ($Connectiontype -eq "delegated")
                {
                    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$AppId,$redirectUri,$platformParameters,$userId).Result
                }
                else
                {
                    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$AppId,$redirectUri,$platformParameters,$userId,"prompt=admin_consent").Result
                }
        
                if($authResult.AccessToken)
                {

                    # Creating header for Authorization token

                    $authHeader = @{
                        'Content-Type'='application/json'
                        'Authorization'="Bearer " + $authResult.AccessToken
                        'ExpiresOn'=$authResult.ExpiresOn
                        }

                    return $authHeader

                }
                else 
                {
                    Write-Host
                    Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                    Write-Host
                    break
                }
            }
            catch 
            {
                write-host $_.Exception.Message -f Red
                write-host $_.Exception.ItemName -f Red
                write-host
                break
            }
        }
    }
}

#endregion
#######################################################################################################################


#######################################################################################################################
#region Script start

    $token = get-msgraphtoken -Connectiontype application `
                            -UserUPN "Null" `
                            -AppId "d2a2d727-cce6-433d-9986-9cac4c29b5ec" `
                            -AppSecred "DYaa9x43JvQCSPMa6qJ_9Xt2P19NA__33." `
                            -Tenant "acpdemot.onmicrosoft.com"
    
    $getguestuser = 'https://graph.microsoft.com/beta/users?$filter=userType eq ''Guest'''
    $responseguestuser = Invoke-RestMethod -Method Get -Uri $getguestuser -Headers @{Authorization = $token.Authorization}   

    foreach ($users in $responseguestuser.value)
    {
        Write-Output "Last Login for User $($users.displayName)"

        $lastloginurl = 'https://graph.microsoft.com/beta/auditLogs/signIns?$top=1&$filter=userPrincipalName eq ''' + $users.mail + "'"
        $responselastlogin = Invoke-RestMethod -Method Get -Uri $lastloginurl -Headers @{Authorization = $token.Authorization} 
        
        if($responselastlogin.value.Length -gt 0)
        {
            Write-Host "LastLogin: $($responselastlogin.value.createdDateTime)"
            Write-Host "#########################"
        }
        else {
            Write-Host "LastLogin >30 Days"
            Write-Host "#########################"
        }

        Write-Host " "
    }

   

    Write-Host " "
    Write-Host "#########################"
    Write-Output "Result"
    foreach ($logs in $response.value)
    {
        Write-Host "Displayname: $($logs.userDisplayName)"
        Write-Host "UPN: $($logs.userPrincipalName)"
        Write-Host "LastLogin: $($logs.createdDateTime)"
        Write-Host "#########################"
        Write-Host " "
    }

#endregion
#######################################################################################################################

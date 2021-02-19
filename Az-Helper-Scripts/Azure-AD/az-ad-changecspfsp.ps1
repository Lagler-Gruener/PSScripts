  <#
    .SYNOPSIS
        This script assign the CSP forign security principal to customer subscriptions
        
        
    .DESCRIPTION
        

    .EXAMPLE
        -    

    .NOTES  
        Required modules: 
            - Az.Resources

        Required permissions:
            - Owner permission on all customer subscriptions!
            
                                   
#>


#region Functions

function getsubscriptions
{
    param (
    [parameter (Mandatory=$true, 
        HelpMessage="Please enter a valid user tenantid.")]
        [string] $CustomerTenantID
    )

    try {
        Write-Host "Connect to AzureAD tenant: $CustomerTenantID"
            Login-AzureRmAccount -TenantId $CustomerTenantID -ErrorAction Stop
        Write-Host -ForegroundColor Green "Done"

        Write-Host "Get all available subscriptions"
            $avsubscriptions = Get-AzureRMSubscription -TenantID $CustomerTenantID -ErrorAction Stop | Select-Object Id, Name
        Write-Host -ForegroundColor Green "Done" 

        return $avsubscriptions
    }
    catch {
        throw "Error in function 'getsubscriptions' Error message: $($_.Exception.Message)"
    }
}

#endregion

Write-Host -ForegroundColor Black -BackgroundColor Blue `
           "                       ## Please select the transfere scenario: ##                                 "
Write-Host "###################################################################################################"
Write-Host "#                                                                                                 #"
Write-Host "# Select 1 to Migrate the CSP Subscription from the 'old' ACP CSP Tenant to the 'new' ACP Tenant. #"
Write-Host "# Select 2 to Migrate the CSP Subscription from the 'old' ACP CSP Tenant to another Partner.      #"
Write-Host "# Select 3 to Migrate the CSP Subscription from the 'new' ACP CSP Tenant to another Partner.      #" 
Write-Host "#                                                                                                 #"
Write-Host "###################################################################################################"

$selectedszenario = Read-Host

Clear-Host

try {    

    if(-not (Get-Module AzureRM.Resources)) {
        Import-Module AzureRM.Resources
    }
    
    switch ($selectedszenario) {
        1 { 
            #region Migrate the CSP Subscription from the 'old' ACP CSP Tenant to the 'new' ACP Tenant selected.

            Write-Host -ForegroundColor Black -BackgroundColor Blue `
                       "Migrate the CSP Subscription from the 'old' ACP CSP Tenant to the 'new' ACP Tenant selected."            
            Write-Host "############################################################################################" 
            $tenantid = Read-Host "Enter the source Customer TenantID:"
            Write-Output " "

            Clear-Host
            Write-Host -ForegroundColor Black -BackgroundColor Blue `
                        "Login with the delegated admin Account from CSP Tenant 'old'"
            Write-Host " "
            $subscriptions = getsubscriptions -CustomerTenantID $tenantid

            foreach ($subscription in $subscriptions) {
                if($null -ne $subscription.Name)
                {
                    Write-Host " "
                    Write-Output "Assign AdminAgents group from the target tenant to the Subscription $($subscription.Name)"
            
                    try {
                        New-AzureRMRoleAssignment -ObjectId "7669022b-c256-43eb-83af-29d74afb8d79" -RoleDefinitionName Owner -Scope "/subscriptions/$($subscription.Id)"   
                        Write-Host -ForegroundColor Green "Done"
                        Write-Host "############################################################################################" 
                        
                    }
                    catch {
                        throw "Error assing permission. Error Message: $($_.Exception.Message)"
                    }    
                }
            }

            #endregion
        }
        2 {
            #region Migrate the CSP Subscription from the 'old' ACP CSP Tenant to another Partner.

            Write-Host "Migrate the CSP Subscription from the 'old' ACP CSP Tenant to another Partner."
            $tenantid = Read-Host "Enter the source Customer TenantID:"
            Write-Output " "

            Clear-Host            
            Write-Host -ForegroundColor Black -BackgroundColor Blue `
                        "Login with the delegated admin Account from CSP Tenant 'old'"
            Write-Host " "
            $subscriptions = getsubscriptions -CustomerTenantID $tenantid      

            $adminagentid = Read-Host "Enter the AdminAgents object ID from the Partner tenant."

            foreach ($subscription in $subscriptions) {
                if($null -ne $subscription.Name)
                {
                    Write-Host " "
                    Write-Output "Assign AdminAgents group from the target tenant to the Subscription $($subscription.Name)"
            
                    try {
                        #New-AzureRMRoleAssignment -ObjectId $adminagentid -RoleDefinitionName Owner -Scope "/subscriptions/$($subscription.Id)"   
                        Write-Host -ForegroundColor Green "Done"
                        Write-Host "############################################################################################" 
                        
                    }
                    catch {
                        throw "Error assing permission. Error Message: $($_.Exception.Message)"
                    }    
                }
            }

            #endregion
        }
        3{
            #region Migrate the CSP Subscription from the 'new' ACP CSP Tenant to another Partner.

            Write-Host "Migrate the CSP Subscription from the 'new' ACP CSP Tenant to another Partner."
            $tenantid = Read-Host "Enter the source Customer TenantID:"
            Write-Output " "

            Clear-Host            
            Write-Host -ForegroundColor Black -BackgroundColor Blue `
                        "Login with the delegated admin Account from CSP Tenant 'new'"
            Write-Host " "
            $subscriptions = getsubscriptions -CustomerTenantID $tenantid      

            $adminagentid = Read-Host "Enter the AdminAgents object ID from the Partner tenant."

            foreach ($subscription in $subscriptions) {

                if($null -ne $subscription.Name)
                {
                    Write-Host " "
                    Write-Output "Assign AdminAgents group from the target tenant to the Subscription $($subscription.Name)"
            
                    try {
                        #New-AzureRMRoleAssignment -ObjectId $adminagentid -RoleDefinitionName Owner -Scope "/subscriptions/$($subscription.Id)"   
                        Write-Host -ForegroundColor Green "Done"
                        Write-Host "############################################################################################" 
                        
                    }
                    catch {
                        throw "Error assing permission. Error Message: $($_.Exception.Message)"
                   }    
                }
            }

            #endregion
        }
        Default {
            Write-Host "Please select the right szenario!"
        }
    }

    Read-Host "Script finish, Press enter to close the script."

}
catch {
    Write-Host -BackgroundColor Red -ForegroundColor Black "Error in script. Error message: $($_.Exception.Message)" 
    
    Read-Host "Script failed, please contact johannes lagler-gruener."
}
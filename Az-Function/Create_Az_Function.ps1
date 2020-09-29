



######################################################################################################
#region Connect to Azure AD
    
$SelectAzureSubscription = "24464ef0-3fec-4a59-9338-3b3b98606a2d"

Login-AzAccount

#Get-AzSubscription

Select-AzSubscription -Subscription $SelectAzureSubscription 

#endregion
######################################################################################################



######################################################################################################
#region Define Global Variables

#Global Variables
$resourceGroupName = "rg-demodeployment"    
$location = "West Europe"

#Storage Acount Variables
$storageAccountName = "straccfunctionappdemo01"
$storageSku = 'Standard_LRS'
$storageConnectionString = ""
$accountKey = ""

#Function Variables
$functionAppName = 'funcfundemo01'
$WEBSITE_CONTENTSHARE = "$($functionAppName)share"
$FUNCTIONS_WORKER_RUNTIME = "dotnet"
$FUNCTIONS_EXTENSION_VERSION = "~3"
$functionmanagedidentityPrincipalId = ""
$functionmanagedidentityTenantId = ""

#App Service Plan Variables
$AppServicePlanName = "DemoPlan02"
$AppServiceSkuName = "Y1"
$AppServiceSkuTier = "Dynamic"    

#Application Insight Variables
$InsightsName = "$($functionAppName)insight"
$Kind = "web" #web, other, Node.js, java   


#endregion
######################################################################################################



######################################################################################################
#region Create Azure Storage Account

$newStorageParams = @{
    ResourceGroupName = $resourceGroupName
    AccountName       = $storageAccountName
    Location          = $location
    SkuName           = $storageSku
}

$storageAccount = New-AzStorageAccount @newStorageParams
#$storageAccount


# Get storage account key and create connection string
$accountKey = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName |
              Where-Object {$_.KeyName -eq 'Key1'} | Select-Object -ExpandProperty Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$accountKey"

#endregion
######################################################################################################



######################################################################################################
#region Create Azure Application Insight

$appinsight = New-AzApplicationInsights -ResourceGroupName $resourceGroupName -Location $location `
                                        -Name $InsightsName -Kind $Kind

#endregion
######################################################################################################



######################################################################################################
#region Create the Function App       

#Create App Service Plan

    $fullObject = @{
            location = $location
            sku = @{
                name = $AppServiceSkuName
                tier = $AppServiceSkuTier
            }
    }

    $appserviceplan = New-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/serverfarms `
                                     -Name $AppServicePlanName -IsFullObject -PropertyObject $fullObject -Force


#Create App Service

    $Properties = @{
        ServerFarmId=$appserviceplan.ResourceId
    }

    $functionApp = New-AzResource -Location $location -ResourceType 'Microsoft.Web/Sites'`
                                  -Kind 'functionapp' -ResourceGroupName $resourceGroupName `
                                  -ResourceName $functionAppName -Properties $Properties -Force


#Update Azure Function

    $Properties = @{}
    $Properties = @{'FUNCTIONS_WORKER_RUNTIME' = $FUNCTIONS_WORKER_RUNTIME;
                    'FUNCTIONS_EXTENSION_VERSION' = $FUNCTIONS_EXTENSION_VERSION;
                    'AzureWebJobsStorage' = $storageConnectionString;
                    'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING' = $storageConnectionString;
                    'WEBSITE_CONTENTSHARE' = $WEBSITE_CONTENTSHARE;
                    'APPINSIGHTS_INSTRUMENTATIONKEY' = $appinsight.InstrumentationKey;               
                    }

    $functionApp = Set-AzWebApp -Name $functionAppName `
                                -ResourceGroupName $resourceGroupName `
                                -AppSettings $Properties `
                                -AssignIdentity $true

    $functionmanagedidentityPrincipalId = $functionApp.Identity.PrincipalId
    $functionmanagedidentityTenantId = $functionApp.Identity.TenantId

#endregion
######################################################################################################

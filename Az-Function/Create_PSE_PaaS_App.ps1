#############################################################################################
#
# Create Application with Frontend and Backend Component including private Service Endpoint
# Also create a seperate VNet
#
#############################################################################################

#############################################################################################
#region functions

Function connectazure
{
    param (
        [Parameter()]
        [string]
        $TenantID,
        [Parameter()]
        [string]
        $SubscriptionID
    )

    Login-AzAccount -Tenant $TenantID
    Select-AzSubscription -Subscription $SubscriptionID
}

Function createresourcegroup
{
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [String]
        $location
    )

    New-AzResourceGroup -Name $ResourceGroupName -Location $location -Force
}

function createazurevnet
{
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $VNetName,
        [Parameter(Mandatory=$true)]
        [string]
        $ResourceGroup,
        [Parameter(Mandatory=$true)]
        [string]
        $Location,
        [Parameter(Mandatory=$true)]
        [string]
        $AdressPrefix,
        [Parameter(Mandatory=$true)]
        [string]
        $FrontendSubnet,
        [Parameter(Mandatory=$true)]
        [string]
        $BackendSubnet
    )    

    
    $frontsub = New-AzVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix $FrontendSubnet -ServiceEndpoint Microsoft.Web
    $backSub  = New-AzVirtualNetworkSubnetConfig -Name backendSubnet  -AddressPrefix $BackendSubnet -ServiceEndpoint Microsoft.Sql
    New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup -Location $location `
                         -AddressPrefix $AdressPrefix -Subnet $frontsub, $backSub -Force
}

function createwebapp
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceGroup,
        [Parameter(Mandatory = $true)]
        [String]
        $location        
    )

    $asplan =  New-AzAppServicePlan -Location $location -Name $PlanName -Tier $Tier `
                                    -WorkerSize $WorkerSize -NumberofWorkers $NumberofWorkers `
                                    -ResourceGroupName $ResourceGroup
    
    $asplan = New-AzResource -ResourceGroupName $ResourceGroup -Location $Location -ResourceType microsoft.web/serverfarms `
                             -ResourceName $AppServicePlanName -kind linux -Properties @{reserved="false"} `
                             -Sku @{name="S1";tier="Standard"; size="S1"; family="S"; capacity="1"} -Force

    $appservice = New-AzWebApp -ResourceGroupName $ResourceGroup -Location $location -Name $AppServiceName `
                               -AppServicePlan $asplan.ResourceId
}

#endregion
#############################################################################################

#############################################################################################
#region Global variables

    #Global variable for whole script
    $location = "West Europe"
    $ResourceGroup = "rg-demo-pse-paas"

    #Variables to create azure vnet
    $VNetName = "vnet-pse-paas"
    $AdressPrefix = "192.168.0.0/16"
    $FrontendSubnet = "192.168.1.0/24"
    $BackendSubnet = "192.168.2.0/24"

    $AppServicePlanName = "asp-pse-frontend"
    $AppServicePlanTier = "Standard" #Basic,Free,Premium,PremiumContainer,Shared,Standard
    $AppServicePlanWorkerSize = "Small" #ExtraLarge,Large,Medium,Small
    $AppServicePlanNumberofWorkers = 1       
    $AppServiceName = "as-pse-frontend"

#endregion
#############################################################################################

#############################################################################################
#region

    connectazure -TenantID "cd068396-db7e-4b8f-ad7e-df116cdf03be" `
                  -SubscriptionID "24464ef0-3fec-4a59-9338-3b3b98606a2d"


    $rgexist = Get-AzResourceGroup -Location $location -Name $ResourceGroup -ErrorAction SilentlyContinue
    if (!$rgexist)
    {
        createresourcegroup -ResourceGroupName $ResourceGroup -location $location
    }

    $vnetexist = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    if(!$vnetexist)
    {
        createazurevnet -VNetName $VNetName -ResourceGroup $ResourceGroup -Location $location -AdressPrefix $AdressPrefix `
                        -FrontendSubnet $FrontendSubnet -BackendSubnet $BackendSubnet
    }
    

    $appserviceexist = Get-AzWebApp -Name $AppServiceName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    if(!$appserviceexist)
    {
        createwebapp -ResourceGroup $ResourceGroup -location $Location -PlanName $AppServicePlanName `
                     -Tier $AppServicePlanTier -WorkerSize $AppServicePlanWorkerSize -NumberofWorkers $AppServicePlanNumberofWorkers `
                     -AppServiceName $AppServiceName
    }

#endregion
#############################################################################################


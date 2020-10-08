Login-AzAccount

#region Enable Prerequisits:

    # Register for Azure Image Builder Feature
    Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
    Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

    # check you are registered for the providers, ensure RegistrationState is set to 'Registered'.
    Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
    Get-AzResourceProvider -ProviderNamespace Microsoft.Storage 
    Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
    Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

    ## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
    ## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
    ## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
    ## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

#endregion

#region prepare env

    # Step 1: Import module
    Import-Module Az.Accounts

    # Step 2: get existing context
    $currentAzContext = Get-AzContext

    # destination image resource group
    $imageResourceGroup="ACP-Demo-Images"

    # location (see possible locations in main docs)
    $location="West Europe"

    ## if you need to change your subscription: Get-AzSubscription / Select-AzSubscription -SubscriptionName 

    # get subscription, this will get your current subscription
    $subscriptionID=$currentAzContext.Subscription.Id

    # name of the image to be created
    $imageName="win2019image1"

    # image distribution metadata reference name
    $runOutputName="win2019ManImg01ro"

    # image template name
    $imageTemplateName="window2019Template01"

    # distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
    $runOutputName="winSvrSigR01"

    # create resource group for image and image template resource
    New-AzResourceGroup -Name $imageResourceGroup -Location $location

#endregion

#region Create user identity

    # setup role def names, these need to be unique
    $timeInt=$(get-date -UFormat "%s")
    $imageRoleDefName="Azure Image Builder Image Def"+$timeInt
    $idenityName="LaglerhImageMi"+$timeInt

    ## Add AZ PS module to support AzUserAssignedIdentity
    Install-Module -Name Az.ManagedServiceIdentity

    # create identity
    New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName

    $idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
    $idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId

#endregion

#region Assign permissions for identity to distribute images

    $aibRoleImageCreationUrl="https://raw.githubusercontent.com/Lagler-Gruener/PSScripts/Dev/Az-ImageBuilder/ARM/CreateImageRole.json"
    $aibRoleImageCreationPath = "CreateImageRole.json"

    # download config
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

    # create role definition
    New-AzRoleDefinition -InputFile  ./CreateImageRole.json

    # grant role definition to image builder service principal
    New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

#endregion



#region Download and update template

    # update AIB image config template
    $templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin01.json"
    $templateFilePath = "helloImageTemplateWin01.json"

    # download configs
    Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

    ((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
    ((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
    ((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
    ((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath
    ((Get-Content -path $templateFilePath -Raw) -replace '<imageName>',$imageName) | Set-Content -Path $templateFilePath
    ((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath

#endregion
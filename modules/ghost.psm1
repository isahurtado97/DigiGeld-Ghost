function EnsureAzModule {
    try {
        # Try to import the Az module
        Import-Module Az -Force -ErrorAction Stop
        Write-Host "Az module successfully imported."
    } catch {
        Write-Host "Az module not found. Attempting to install..."
        # Set PSGallery as trusted repository
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        # Install Az module
        Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
        Install-Module -Name Az.Aks -AllowClobber -Scope CurrentUser -Force
        # Try importing again after installation
        Import-Module Az -Force
        Import-Module Az.Aks -Force
        Write-Host "Az module successfully installed and imported."
    }
}
function NewDeployAzResourceGroup {
    param(
        [string]$resourceGroupName,
        [string]$location
    )
    process{
        # Check if Resource Group exists
        $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $resourceGroup) {
            Write-Host "Creating Resource Group..."
            New-AzResourceGroup -Name $resourceGroupName -Location $location
        } else {
            Write-Host "Resource Group '$resourceGroupName' already exists."
        }
    }
}
function NewDeployLogAnalyticsWorkspace {
    param(
        [string]$resourceGroupName,
        [string]$location,
        [string]$clusterName
    )
    # Check if Log Analytics Workspace exists
    $workspace = Get-AzOperationalInsightsWorkspace -resourceGroupName $resourceGroupName -Name "$clusterName-Workspace" -ErrorAction SilentlyContinue
    if ($workspace) {
        Write-Host "Log Analytics Workspace $clusterName-Workspace already exists."
    } else {
        # Create Log Analytics Workspace
        Write-Host "Creating Log Analytics Workspace: $clusterName-Workspace"
        $workspace = New-AzOperationalInsightsWorkspace `
            -resourceGroupName $resourceGroupName `
            -Name "$clusterName-Workspace" `
            -Location $location `
            -Sku $Sku `
            -RetentionInDays 30 # Optional: Adjust retention as needed
        Write-Host "Log Analytics Workspace created successfully."
    }
}
function NewDeploySecurityConfig {
    param(
        [string]$resourceGroupName,
        [string]$location,
        [string]$clusterName
    )

    # Step 1: Azure Application Gateway
    Write-Host "Checking if Azure Application Gateway exists..."
    $appGateway = Get-AzApplicationGateway -resourceGroupName $resourceGroupName -Name "$clusterName-appgw" -ErrorAction SilentlyContinue
    if ($appGateway) {
        Write-Host "Resource $resourceGroupName-vault already exists."
    } else {
        Write-Host "Creating Application Gateway..."
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name "$clusterName-sn" -AddressPrefix 10.0.0.0/24
        $VNet = New-AzVirtualNetwork -Name "$clusterName-appgw-vn" -resourceGroupName $resourceGroupName -Location "northeurope" -AddressPrefix 10.0.0.0/16 -Subnet $Subnet -Force
        $VNet = Get-AzVirtualNetwork -Name "$clusterName-vn" -resourceGroupName $resourceGroupName 
        $Subnet = Get-AzVirtualNetworkSubnetConfig -Name "$clusterName-sn"  -VirtualNetwork $VNet 
        $GatewayIPconfig = New-AzApplicationGatewayIPConfiguration -Name "$clusterName-gw-ip" -Subnet $Subnet
        $Pool = New-AzApplicationGatewayBackendAddressPool -Name "$clusterName-pool" -BackendIPAddresses 10.10.10.1, 10.10.10.2, 10.10.10.3
        $PoolSetting = New-AzApplicationGatewayBackendHttpSetting -Name "$clusterName-poolsettings"  -Port 80 -Protocol "Http" -CookieBasedAffinity "Disabled"
        $FrontEndPort = New-AzApplicationGatewayFrontendPort -Name "$clusterName-fe"  -Port 80
        # Create a public IP address
        $PublicIp = New-AzPublicIpAddress -resourceGroupName $resourceGroupName -Name "$clusterName-pip" -Location "northeurope" -AllocationMethod "Static" -sku Standard -Force
        $FrontEndIpConfig = New-AzApplicationGatewayFrontendIPConfig -Name "$clusterName-feconfig" -PublicIPAddress $PublicIp
        $Listener = New-AzApplicationGatewayHttpListener -Name "$clusterName-listener" -Protocol "Http" -FrontendIpConfiguration $FrontEndIpConfig -FrontendPort $FrontEndPort
        $Rule = New-AzApplicationGatewayRequestRoutingRule -Name "$clusterName-routing-rule01" -RuleType basic -BackendHttpSettings $PoolSetting -HttpListener $Listener -BackendAddressPool $Pool -Priority 200
        $Sku = New-AzApplicationGatewaySku -Name "Standard_v2" -Tier Standard_v2 -Capacity 2
        $Gateway = New-AzApplicationGateway -Name "$clusterName-appgw"  -resourceGroupName $resourceGroupName -Location "northeurope" -BackendAddressPools $Pool -BackendHttpSettingsCollection $PoolSetting -FrontendIpConfigurations $FrontEndIpConfig  -GatewayIpConfigurations $GatewayIpConfig -FrontendPorts $FrontEndPort -HttpListeners $Listener -RequestRoutingRules $Rule -Sku $Sku
        Write-Host "Creating Application Gateway Deployed..."
    }

}
function NewDeployvnetPeer{
    # Variables
    param(
        $ResourceGroupName
        )


    # Get the AKS VNet
    $aksVnet = Get-AzVirtualNetwork -ResourceName "*aks-vnet*" -ResourceGroupName $ResourceGroupName
    $appGwnet= Get-AzVirtualNetwork -ResourceName "*-appgw-vn*" -ResourceGroupName $ResourceGroupName
    # Create the VNet Peering
    Add-AzVirtualNetworkPeering -Name "AkstoGW" `
    -VirtualNetwork $aksVnet `
    -RemoteVirtualNetworkId $appGwnet.Id `
    -AllowVirtualNetworkAccess $true
}
function NewDeployinfra{
    param(
     [string]$resourceGroupName,
     [string]$Location,
     [string]$clusterName,
     [string]$acrName,
     [string]$basepath
    )
    begin{
        Ensure-AzModule
    }
    process{
        DeployAzResourceGroup -resourceGroupName $resourceGroupName -location $Location
        DeploySecurityConfig -resourceGroupName $resourceGroupName -Location $Location -clusterName $clusterName
        CreateLogAnalyticsWorkspace -resourceGroupName $resourceGroupName -Location $Location -acrName $acrName -clusterName $clusterName -sku 'Standard'
        $AppGatewayID=Get-AzResource -ResourceName "$clusterName-appgw" -resourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $PublicIpID=Get-AzResource -ResourceName "$clusterName-pip" -resourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $LogAWID=Get-AzResource -ResourceName "$clusterName-Workspace" -resourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $parameters = @{
        resourceGroupName = $resourceGroupName
        vaults_dg_aks_prod_vault_name  = "$clusterName-vault"
        registries_dgacrprod_name = $acrName
        managedClusters_dg_aks_prod_name  = $clusterName
        applicationGateways_dg_aks_prod_appgw_externalid  = $AppGatewayID
        workspaces_dg_aks_prod_Workspace_externalid  = $LogAWID
        publicIPAddresses_bd1aec30_36bc_48ef_8301_435ccbf0d11f_externalid  = $PublicIpID
        }
        New-AzResourceGroupDeployment -resourceGroupName $resourceGroupName -TemplateFile "$basepath/infra.bicep" -TemplateParameterObject $parameters -Verbose
        Enable-AzAksAddon -resourceGroupName $resourceGroupName -clusterName $clusterName -Name AzurePolicy
        identityAzKeyvaultAks -resourceGroupName $resourceGroupName -clusterName $clusterName -keyVaultName "$clusterName-vault"
        DeployvnetPeer -ResourceGroupName $resourceGroupName
    }
}
function identityAzKeyvaultAks{ 
    param(
        [string]$resourceGroupName,
        [string]$clusterName,
        [string]$keyVaultName

    )
    # Get the AKS Managed Identity Object ID
    Write-Host "Fetching AKS Managed Identity Object ID..."
    $aks = Get-AzAksCluster -resourceGroupName $resourceGroupName -Name $clusterName
    $aksIdentityObjectId = $aks.IdentityProfile["kubeletidentity"].ObjectId
    Write-Host "AKS Managed Identity Object ID: $aksIdentityObjectId"

    # Get the Key Vault Resource ID
    Write-Host "Fetching Key Vault Resource ID for Key Vault: $KeyVaultName"
    $keyVault = Get-AzKeyVault -VaultName $KeyVaultName -resourceGroupName $resourceGroupName
    $keyVaultResourceId = $keyVault.ResourceId
    Write-Host "Key Vault Resource ID: $keyVaultResourceId"

    # Assign Key Vault Secrets User Role
    Write-Host "Assigning Key Vault Secrets User role to AKS Managed Identity..."
    New-AzRoleAssignment -ObjectId $aksIdentityObjectId -RoleDefinitionName "Key Vault Secrets User" -Scope $keyVaultResourceId
    Write-Host "Key Vault Secrets User Role assigned successfully."

    # Assign Key Vault Certificate User Role
    Write-Host "Assigning Key Vault Certificate User role to AKS Managed Identity..."
    New-AzRoleAssignment -ObjectId $aksIdentityObjectId -RoleDefinitionName "Key Vault Certificate User" -Scope $keyVaultResourceId
    Write-Host "Key Vault Certificate User Role assigned successfully."


}
function Setup-Ghost-Files{
    param(
        [string]$filepath,
        [string]$filefinalpath,
        [string]$image
    )
    process{
        $file = Get-Content $filepath
        $file = $file -replace 'CHANGE_IMAGE', $image
        $file | Out-File -FilePath $filefinalpath
    }
}


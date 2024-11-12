function Ensure-AzModule {
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
function Create-AzResorceGroup {
    param(
        [string]$resourceGroupName,
        [string]$location
    )
    # Check if Resource Group exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        Write-Host "Creating Resource Group..."
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    } else {
        Write-Host "Resource Group '$resourceGroupName' already exists."
    }
}
function Create-AzContainerRegistry {
    param(
        [string]$resourceGroupName,
        [string]$location,
        [string]$acrName
    )
    # Check if Azure Container Registry (ACR) exists
    $acr = Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -RegistryName $acrName -ErrorAction SilentlyContinue
    if (-not $acr) {
        Write-Host "Creating Azure Container Registry..."
        New-AzContainerRegistry `
            -ResourceGroupName $resourceGroupName `
            -RegistryName $acrName `
            -Sku 'Basic' `
            -Location $location
    } else {
        Write-Host "Azure Container Registry '$acrName' already exists."
    }
}
function Create-LogAnalyticsWorkspace {
    param(
        [string]$resourceGroupName,
        [string]$location,
        [string]$aksClusterName
    )
    # Check if Log Analytics Workspace exists
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name "$aksClusterName-Workspace" -ErrorAction SilentlyContinue
    if ($workspace) {
        Write-Host "Log Analytics Workspace $aksClusterName-Workspace already exists."
    } else {
        # Create Log Analytics Workspace
        Write-Host "Creating Log Analytics Workspace: $aksClusterName-Workspace"
        $workspace = New-AzOperationalInsightsWorkspace `
            -ResourceGroupName $ResourceGroupName `
            -Name "$aksClusterName-Workspace" `
            -Location $location `
            -Sku $Sku `
            -RetentionInDays 30 # Optional: Adjust retention as needed
        Write-Host "Log Analytics Workspace created successfully."
    }
}
function Deploy-SecurityConfig {
    param(
        [string]$resourceGroupName,
        [string]$location,
        [string]$aksClusterName
    )

    # Step 1: Azure Application Gateway
    Write-Host "Checking if Azure Application Gateway exists..."
    $appGateway = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name "$aksClusterName-appgw" -ErrorAction SilentlyContinue
    if ($appGateway) {
        Write-Host "Resource $resourceGroupName-vault already exists."
    } else {
        Write-Host "Creating Application Gateway..."
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name "$aksClusterName-sn" -AddressPrefix 10.0.0.0/24
        $VNet = New-AzVirtualNetwork -Name "$aksClusterName-vn" -ResourceGroupName $resourceGroupName -Location "northeurope" -AddressPrefix 10.0.0.0/16 -Subnet $Subnet -Force
        $VNet = Get-AzVirtualNetwork -Name "$aksClusterName-vn" -ResourceGroupName $resourceGroupName 
        $Subnet = Get-AzVirtualNetworkSubnetConfig -Name "$aksClusterName-sn"  -VirtualNetwork $VNet 
        $GatewayIPconfig = New-AzApplicationGatewayIPConfiguration -Name "$aksClusterName-gw-ip" -Subnet $Subnet
        $Pool = New-AzApplicationGatewayBackendAddressPool -Name "$aksClusterName-pool" -BackendIPAddresses 10.10.10.1, 10.10.10.2, 10.10.10.3
        $PoolSetting = New-AzApplicationGatewayBackendHttpSetting -Name "$aksClusterName-poolsettings"  -Port 80 -Protocol "Http" -CookieBasedAffinity "Disabled"
        $FrontEndPort = New-AzApplicationGatewayFrontendPort -Name "$aksClusterName-fe"  -Port 80
        # Create a public IP address
        $PublicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "$aksClusterName-pip" -Location "northeurope" -AllocationMethod "Static" -sku Standard -Force
        $FrontEndIpConfig = New-AzApplicationGatewayFrontendIPConfig -Name "$aksClusterName-feconfig" -PublicIPAddress $PublicIp
        $Listener = New-AzApplicationGatewayHttpListener -Name "$aksClusterName-listener" -Protocol "Http" -FrontendIpConfiguration $FrontEndIpConfig -FrontendPort $FrontEndPort
        $Rule = New-AzApplicationGatewayRequestRoutingRule -Name "$aksClusterName-routing-rule01" -RuleType basic -BackendHttpSettings $PoolSetting -HttpListener $Listener -BackendAddressPool $Pool -Priority 200
        $Sku = New-AzApplicationGatewaySku -Name "Standard_v2" -Tier Standard_v2 -Capacity 2
        $Gateway = New-AzApplicationGateway -Name "$aksClusterName-appgw"  -ResourceGroupName $resourceGroupName -Location "northeurope" -BackendAddressPools $Pool -BackendHttpSettingsCollection $PoolSetting -FrontendIpConfigurations $FrontEndIpConfig  -GatewayIpConfigurations $GatewayIpConfig -FrontendPorts $FrontEndPort -HttpListeners $Listener -RequestRoutingRules $Rule -Sku $Sku
        Write-Host "Creating Application Gateway Deployed..."
    }

}
function Deploy-infra{
    param(
     [string]$resourceGroupName,
     [string]$Location,
     [string]$aksClusterName,
     [string]$acrName,
     [string]$basepath
    )
    begin{
        Ensure-AzModule
    }
    process{
        Deploy-SecurityConfig -resourceGroupName $resourceGroupName -Location $Location -aksClusterName $aksClusterName
        Create-LogAnalyticsWorkspace -ResourceGroupName $resourceGroupName -Location $Location -acrName $acrName -aksClusterName $aksClusterName -sku 'Standard'
        $AppGatewayID=Get-AzResource -ResourceName "$aksClusterName-appgw" -ResourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $PublicIpID=Get-AzResource -ResourceName "$aksClusterName-pip" -ResourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $LogAWID=Get-AzResource -ResourceName "$aksClusterName-Workspace" -ResourceGroupName $resourceGroupName | Select-Object -ExpandProperty ResourceId
        $parameters = @{
        resourceGroupName = $resourceGroupName
        vaults_dg_aks_prod_vault_name  = "$aksClusterName-vault"
        registries_dgacrprod_name = $acrName
        managedClusters_dg_aks_prod_name  = $aksClusterName
        applicationGateways_dg_aks_prod_appgw_externalid  = $AppGatewayID
        workspaces_dg_aks_prod_Workspace_externalid  = $LogAWID
        publicIPAddresses_bd1aec30_36bc_48ef_8301_435ccbf0d11f_externalid  = $PublicIpID
        }
        New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "$basepath/infra.bicep" -TemplateParameterObject $parameters -Verbose
    }
}
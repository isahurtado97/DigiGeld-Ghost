# Variables
param(
    [string]$resourceGroupName,
    [string]$location,
    [string]$acrName,
    [string]$aksClusterName,
    [string]$mysqlPassword
)
begin{
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
            [string]$acrName,
            [string]$aksClusterName
        )
        # Get the ACR resource ID (used for AKS integration)
        $acrResourceId = (Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -RegistryName $acrName).Id
        # Check if Log Analytics Workspace exists
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name "$aksClusterName-Workspace" -ErrorAction SilentlyContinue
        if ($workspace) {
            Write-Host "Log Analytics Workspace '$aksClusterName-Workspace' already exists."
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
        $appGateway = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name "$aksClusterName-gw" -ErrorAction SilentlyContinue
        if ($keyvault) {
            Write-Host "Resource $resourceGroupName-vault already exists."
        } else {
        
            $Subnet = New-AzVirtualNetworkSubnetConfig -Name "$aksClusterName-sn" -AddressPrefix 10.0.0.0/24
            $VNet = New-AzVirtualNetwork -Name "$aksClusterName-vn" -ResourceGroupName $resourceGroupName -Location "northeurope" -AddressPrefix 10.0.0.0/16 -Subnet $Subnet
            $VNet = Get-AzVirtualNetwork -Name "$aksClusterName-vn" -ResourceGroupName $resourceGroupName 
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name "$aksClusterName-sn"  -VirtualNetwork $VNet 
            $GatewayIPconfig = New-AzApplicationGatewayIPConfiguration -Name "$aksClusterName-gw-ip" -Subnet $Subnet
            $Pool = New-AzApplicationGatewayBackendAddressPool -Name "$aksClusterName-pool" -BackendIPAddresses 10.10.10.1, 10.10.10.2, 10.10.10.3
            $PoolSetting = New-AzApplicationGatewayBackendHttpSetting -Name "$aksClusterName-poolsettings"  -Port 80 -Protocol "Http" -CookieBasedAffinity "Disabled"
            $FrontEndPort = New-AzApplicationGatewayFrontendPort -Name "$aksClusterName-fe"  -Port 80
            # Create a public IP address
            $PublicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "$aksClusterName-pip" -Location "northeurope" -AllocationMethod "Static" -sku Standard
            $FrontEndIpConfig = New-AzApplicationGatewayFrontendIPConfig -Name "$aksClusterName-feconfig" -PublicIPAddress $PublicIp
            $Listener = New-AzApplicationGatewayHttpListener -Name "$aksClusterName-listener" -Protocol "Http" -FrontendIpConfiguration $FrontEndIpConfig -FrontendPort $FrontEndPort
            $Rule = New-AzApplicationGatewayRequestRoutingRule -Name "$aksClusterName-routing-rule01" -RuleType basic -BackendHttpSettings $PoolSetting -HttpListener $Listener -BackendAddressPool $Pool
            $Sku = New-AzApplicationGatewaySku -Name "Standard_v2" -Tier Standard_v2 -Capacity 2
            $Gateway = New-AzApplicationGateway -Name "$aksClusterName-appgwconfig"  -ResourceGroupName $resourceGroupName -Location "northeurope" -BackendAddressPools $Pool -BackendHttpSettingsCollection $PoolSetting -FrontendIpConfigurations $FrontEndIpConfig  -GatewayIpConfigurations $GatewayIpConfig -FrontendPorts $FrontEndPort -HttpListeners $Listener -RequestRoutingRules $Rule -Sku $Sku
        }
    }
}
process {
    # Ensure Az module is installed and imported
    Ensure-AzModule

    # Deploy Resource Group if not exists
    Create-AzResorceGroup -ResourceGroupName $ResourceGroupName -Location $location   
    
    # Deploy AzContainerRegistry if not exists
    Create-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Location $location -acrName $acrName
    
    # Deploy Create-LogAnalyticsWorkspace if not exists
    Create-LogAnalyticsWorkspace -ResourceGroupName $ResourceGroupName -Location $location -acrName $acrName -aksClusterName $aksClusterName
    
    #Deploy Security Configuration
    #Deploy-SecurityConfig -resourceGroupName $aksClusterName -Location $location -aksClusterName $aksClusterName
    
    # Enable addons
    Write-Host "Enabling Azure Policy addon for Pod Security..."
    #Enable-AzAksAddon -ResourceGroupName $resourceGroupName -ClusterName $aksClusterName -Name AzurePolicy
    Write-Host "Enabling Application Gateway Ingress Controller addon for AKS..."
    #Enable-AzAksAddon -ResourceGroupName $resourceGroupName -ClusterName $aksClusterName -AddonName ingress-appgw -AppGatewayId $appGatewayId
}
# Variables
param(
    [string]$resourceGroupName,
    [string]$location,
    [string]$acrName,
    [string]$aksClusterName
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
    if (-not (Get-AzContext)) {
        # Authenticate using the Azure DevOps pipeline environment
        $AzConnection = Connect-AzAccount -Identity -ErrorAction Stop
        Write-Host "Azure authenticated successfully."
    } else {
        Write-Host "Azure context already set. Proceeding with the script."
    }
}
process {
    # Ensure Az module is installed and imported
    Ensure-AzModule
    # Check if Resource Group exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        Write-Host "Creating Resource Group..."
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    } else {
        Write-Host "Resource Group '$resourceGroupName' already exists."
    }

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

    # Get the ACR resource ID (used for AKS integration)
    $acrResourceId = (Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -RegistryName $acrName).Id

    # Check if AKS Cluster exists
    $aksCluster = Get-AzAksCluster -ResourceGroupName $resourceGroupName -Name $aksClusterName -ErrorAction SilentlyContinue
    if (-not $aksCluster) {
        Write-Host "Creating AKS Cluster..."
        New-AzAksCluster `
            -ResourceGroupName $resourceGroupName `
            -Name $aksClusterName `
            -NodeCount 3 `
            -NodeVmSize "Standard_DS2_v2" `
            -AddOnNameToBeEnabled  "Monitoring" `
            -EnableNodeAutoScaling `
            -NodeMinCount 1 `
            -NodeMaxCount 5 `
            -AcrNameToAttach $acrName `
            -Location $location `
            -GenerateSshKey
    } else {
        Write-Host "AKS Cluster '$aksClusterName' already exists."
    }
    Write-Host "Script execution completed."
    #az aks enable-addons --addons monitoring --resource-group $ResourceGroupName --name $AksClusterName
}
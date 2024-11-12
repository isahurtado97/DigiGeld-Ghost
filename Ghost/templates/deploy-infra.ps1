param(
     [string]$resourceGroupName,
     [string]$Location,
     [string]$aksClusterName,
     [string]$acrName,
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
    vaults_dg_aks_prod_vault_name  = "$aksClusterName-vault"
    registries_dgacrprod_name = $acrName
    managedClusters_dg_aks_prod_name  = $aksClusterName
    applicationGateways_dg_aks_prod_appgw_externalid  = $AppGatewayID
    workspaces_dg_aks_prod_Workspace_externalid  = $LogAWID
    publicIPAddresses_bd1aec30_36bc_48ef_8301_435ccbf0d11f_externalid  = $PublicIpID
    }
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "infra.bicep" -TemplateParameterObject $parameters -Verbose
}

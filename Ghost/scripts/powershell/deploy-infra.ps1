param(
    [string]$ResourceGroupName,
    [string]$acrName,
    [string]$location,
    [string]$aksClusterName,
    [string]$basepath
)
process {
    Import-Module $basepath/deploy-infra.psm1
    # Ensure Az module is installed and imported
    Ensure-AzModule

    # Deploy Resource Group if not exists
    Create-AzResorceGroup -ResourceGroupName $ResourceGroupName -Location $location   
    
    # Deploy AzContainerRegistry if not exists
    Create-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Location $location -acrName $acrName
    
    # Deploy Create-LogAnalyticsWorkspace if not exists
    Create-LogAnalyticsWorkspace -ResourceGroupName $ResourceGroupName -Location $location -acrName $acrName -aksClusterName $aksClusterName -sku 'Standard'

    #Wait for all to be deploy and recognized
    Start-Sleep -Seconds 120
    Write-host "All is deployed and recognized"
}
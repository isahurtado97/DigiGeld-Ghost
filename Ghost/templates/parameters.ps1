$parameters = @{
    deployAll = $true
    deployAcr = $true
    deployLogAnalytics = $true
    deployKeyVault = $true
    acrName="dgacrprod"
    location="northeurope"
    logAnalyticsWorkspaceName="dg-rg-prod-Workspace"
    KeyvaultName="dg-rg-prod-vault"
}

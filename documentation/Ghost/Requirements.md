- service connection
- az ad sp create-for-rbac --name "<YourServicePrincipalName>" --role Contributor --scopes /subscriptions/<SubscriptionID>
az keyvault secret set --vault-name <keyvault-name> --name root-password --value "MyStrongPassword123"
az keyvault secret set --vault-name <keyvault-name> --name user --value "my-database-user"
az keyvault secret set --vault-name <keyvault-name> --name password --value "MyDatabasePassword456"
Assign Permissions for the AKS Cluster to the keyvault
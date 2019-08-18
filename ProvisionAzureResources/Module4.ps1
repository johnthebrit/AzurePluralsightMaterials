$GitBasePath = '<repo clone path>\ProvisionAzureResources'

#Deploy simple template creating a storage account
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\StorageAccount.json" `
    -TemplateParameterFile "$GitBasePath\StorageAccount.parameters.json"
#Note deploying to an RG. To deploy to a subscription and create RGs and multiple RGs use New-AzDeployment
#https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy

$GitBasePath = '<repo clone path>\ImpInfraasCode'

#Deploy simple template creating a storage account
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\Module3\StorageAccount.json" `
    -TemplateParameterFile "$GitBasePath\Module3\StorageAccount.parameters.json"

#Run same template again but override the type of the storage account
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\\Module3\StorageAccount.json" `
    -TemplateParameterFile "$GitBasePath\\Module3\StorageAccount.parameters.json" `
    -StorageAccountType 'Standard_GRS'

#Could rerun without the parameter and would set it back to LRS!

#Create a virtual network
#No parameter file. Terrible but not the focus here :-)
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\\Module3\VirtualNetwork1Subnet.json"

#Run the 2 subnet version
#Forcing complete mode (instead of default incremental). Watch the storage account!
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\\Module3\VirtualNetwork2Subnets.json" `
    -Mode Complete

#Deploy a nested template. Note the variables and parameters come from the main template and not from the nested area
#Deploy simple template creating a storage account
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\Module3\StorageAccountNested.json"

#Deploy a linked template that is stored in blob (via a SAS since no public anonymous)
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\Module3\StorageAccountLinked.json" `
    -StorageAccountType 'Standard_LRS'

#Looking at a secret
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\\Module3\keyvaulttest.json" `
    -TemplateParameterFile "$GitBasePath\\Module3\keyvaulttest.parameters.json"

#Create a full VM
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "$GitBasePath\\Module3\SimpleWindowsVM.json" `
    -TemplateParameterFile "$GitBasePath\\Module3\SimpleWindowsVM.parameters.json"
#Once deployed try and connect with a domain cred via aka.ms/bastionhost! Don't need domain as part of name, just John for me!
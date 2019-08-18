
#Device Code Flow
Connect-AzAccount
Get-Alias Add-AzAccount | Format-List   # Can also use Add-AzAccount!
#Enter token via https://microsoft.com/devicelogin and authenticate with account

#For CLI
az login


#Cloud Shell
Get-CloudDrive
Get-PSProvider



#### Az Module Install

#Check current Az and latest available
Get-Module az -ListAvailable
Find-Module az

#Cannot just update module as a meta. Need to remove old version and install new

#Uninstall all Az modules
#Run elevated
#Also option from https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-2.5.0
#Remember also exist in file system so can be removed. Path shown via Get-Module
$AzModules = (Get-Module -ListAvailable Az.*).name | Get-Unique
foreach($AzModule in $AzModules)
{
    Uninstall-Module $AzModule -Force
}
Uninstall-Module Az

#Install latest
Install-Module Az -AllowClobber -Repository "PSGallery"


#Contexts
Get-AzContext
Get-AzContext -ListAvailable

$context = Get-AzContext
Rename-AzContext $context.Name 'SavillTech Dev'

Get-AzContextAutosaveSetting


#Az Module PowerShell Commands
#Note Most AzureRM commands can be replaced with Az
Select-AzContext "SavillTech Prod"

Get-Command -Module Az.Compute
Get-Command -Module Az.Compute -Verb New
Get-Command -Module Az.Compute -Noun AzVM

Get-AzResourceGroup

Get-AzVM
Get-AzVM -status | ft name, powerstate -AutoSize
Get-AzVM -status | where {$_.powerstate -ne "VM Running"}

#Look at secrets
(Get-AzKeyVaultSecret –VaultName 'SavKeyVault' `
    -Name TestSecret).SecretValueText

#Look at all extension images
Get-AzVmImagePublisher -Location "southcentralus" | Get-AzVMExtensionImageType | Get-AzVMExtensionImage | Select Type, Version

#View Windows Server images
$loc = 'SouthCentralUS'
#View the templates available
Get-AzVMImagePublisher -Location $loc
Get-AzVMImageOffer -Location $loc -PublisherName "MicrosoftWindowsServer"
Get-AzVMImageSku -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer"
Get-AzVMImage -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter-Core"
#can use -latest when actually using

#View Ubuntu
#View the templates available
Get-AzVMImagePublisher -Location $loc
Get-AzVMImageOffer -Location $loc -PublisherName "Canonical"
Get-AzVMImageSku -Location $loc -PublisherName "Canonical" -Offer "UbuntuServer"
Get-AzVMImage -Location $loc -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS"
Get-AzVMImage -Location $loc -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS" -Version "18.04.201908131"

#Create an RG
New-AzResourceGroup -Name "TestRG" -Location "southcentralus"

#Create easy VM
New-AzVM -Name johnvm -Credential (Get-Credential) -Verbose -WhatIf

New-AzVM -Name johnvm -Credential (Get-Credential) -Image UbuntuLTS -Verbose -WhatIf

#Deploy an ARM template
New-AzResourceGroupDeployment -ResourceGroupName RG-IaCSample `
    -TemplateFile "StorageAccount.json" `
    -TemplateParameterFile "StorageAccount.parameters.json"


#CLI Use
az login

az account list

#To switch I would use (note this automatically uses the profile for the selected subscription including the credential)
az account set --s "subscription name"
#To see the current profile, I can use
az account show

#To view the available regions I would use the following:
az account list-locations

#Create an RG
az group create --location southcentralus --name testRG

#To view the VM sizes available in a region (note the 2 dashes before location)
az vm list-sizes --location eastus2
#To quickly create a VM with many default values
az vm create -n MyVm -g MyResourceGroup --image UbuntuLTS

#Deploy an ARM template (@ for parameter means local file)
az group deployment create --resource-group "RG-IaCSample" --template-file "StorageAccount.json" --parameters "@StorageAccount.parameters.json"
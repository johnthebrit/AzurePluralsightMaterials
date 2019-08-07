$Region = "southcentralus"
$VNetName = "VNet-Infra-SCUS"
$VNetRG = "RG-Infra-SCUS"
$VNetSubnetName = "TestSub"
$VMRG = "RG-Test-SouthCentralUS"

$VMName = "AZUUSCVM01"
$VMSize = "Standard_DS3_v2" #4vcpu 16GB memory

$VMDiagName = "savhybridinfradiag"

#Domain Join Strings
$string1 = '{
    "Name": "savilltech.net",
    "User": "savilltech.net\\adminname",
    "OUPath": "OU=Servers,OU=Hybrid,OU=Environments,DC=savilltech,DC=net",
    "Restart": "true",
    "Options": "3"
        }'
$string2 = '{ "Password": "rawpasswordhere" }'
# #Or use a secret from Key Vault which would be better!!!   e.g.
$secretstring = (Get-AzKeyVaultSecret –VaultName 'SavKeyVault' `
    -Name TestSecret).SecretValueText
$string2 = "{ `"Password`": `"$secretstring`" }"

#Get the network subnet
$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $VNetRG
$VNetSubnet = Get-AzVirtualNetworkSubnetConfig -Name $VNetSubnetName -VirtualNetwork $VNet

#Local Credential
$user = "localadmin"
$password = 'localadminpasshere'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword)

# Antimalware extension
$SettingsString = '{ "AntimalwareEnabled": true,"RealtimeProtectionEnabled": true}';
$allVersions= (Get-AzVMExtensionImage -Location $Region -PublisherName "Microsoft.Azure.Security" -Type "IaaSAntimalware").Version
$typeHandlerVer = $allVersions[($allVersions.count)-1]
$typeHandlerVerMjandMn = $typeHandlerVer.split(".")
$typeHandlerVerMjandMn = $typeHandlerVerMjandMn[0] + "." + $typeHandlerVerMjandMn[1]

#Create the resource group
New-AzResourceGroup -Name $VMRG -Location $Region

#Create the diagnostics storage account
New-AzStorageAccount -ResourceGroupName $VMRG -Name $VMDiagName -SkuName Standard_LRS -Location $Region

# Create VM Object
$vm = New-AzVMConfig -VMName $VMName -VMSize $VMSize

$nic = New-AzNetworkInterface -Name ('nic-' + $VMName) -ResourceGroupName $VMRG -Location $Region `
    -SubnetId $VNetSubnet.Id

# Add NIC to VM
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

# VM Storage
$vm = Set-AzVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest
$vm = Set-AzVMOSDisk -VM $vm  -StorageAccountType PremiumLRS -DiskSizeInGB 512 `
    -CreateOption FromImage -Caching ReadWrite -Name "$VMName-OS"
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $SQLVMName `
    -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$diskConfig = New-AzDiskConfig -AccountType PremiumLRS -Location $Region -CreateOption Empty `
        -DiskSizeGB 2048
$dataDisk1 = New-AzDisk -DiskName "$VMName-data1" -Disk $diskConfig -ResourceGroupName $VMRG
$vm = Add-AzVMDataDisk -VM $vm -Name "$VMName-data1" -CreateOption Attach `
    -ManagedDiskId $dataDisk1.Id -Lun 1

$vm = Set-AzVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $VMRG -StorageAccountName $VMDiagName

# Create Virtual Machine
New-AzVM -ResourceGroupName $VMRG -Location $Region -VM $vm

Set-AzVMExtension -ResourceGroupName $VMRG -VMName $SQLVMName -Name "IaaSAntimalware" `
    -Publisher "Microsoft.Azure.Security" -ExtensionType "IaaSAntimalware" `
    -TypeHandlerVersion $typeHandlerVerMjandMn -SettingString $SettingsString -Location $Region

Set-AzVMExtension -ResourceGroupName $VMRG -VMName $SQLVMName -ExtensionType "JsonADDomainExtension" `
    -Name "joindomain" -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.0" -Location $Region `
    -SettingString $string1 -ProtectedSettingString $string2
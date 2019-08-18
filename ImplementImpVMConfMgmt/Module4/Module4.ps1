$ModuleRoot = "C:\<path>\AzurePluralsightMaterials\ImplementImpVMConfMgmt\Module4"

Select-AzContext "SavillTech Prod"

$RG = 'RG-Infra-SCUS'
$storageAccountName = 'sasavpocscus'

$storageAccount = Get-AzStorageAccount -ResourceGroupName $RG -Name $storageAccountName
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $RG -Name $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey
#Blobs need public access if not using SAS for the files


#Start with a Windows target
$RG = 'RG-Infra-SCUS'
$Location = 'southcentralus'
$VMName = 'Savazuusscwin10'
$storageAccountName = "sasavpocscus"
$containerName = "csetesting"

#Upload a batch file
Set-AzStorageBlobContent -File "$ModuleRoot\whoami.bat" `
  -Container $containerName `
  -Blob "whoami.bat" `
  -Context $storageContext

#Apply to VM

#Check on extension version
Get-AzVMExtensionImage -Location southcentralus -PublisherName Microsoft.Compute -Type CustomScriptExtension

#Can be an array of files. Need public access or a SAS to access
$fileUri = @("https://$($storageAccountName).blob.core.windows.net/$($containerName)/whoami.bat")
$ExtensionName = 'WhoAmI1'
$ExtensionType = 'CustomScriptExtension'
$Publisher = 'Microsoft.Compute'
$Version = '1.9'
$timestamp = (Get-Date).Ticks

$PublicConfiguration = @{"commandToExecute" = "whoami.bat";"fileUris" = $fileUri;"timestamp" = "$timestamp"}

Set-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Location $Location `
    -Name $ExtensionName -Publisher $Publisher -ExtensionType $ExtensionType -TypeHandlerVersion $Version `
    -Settings $PublicConfiguration

#Artifacts will download to C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\<CSE version>
#Logs at C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\<CSE version>
Get-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName
#View the output
$output = Get-AzVMDiagnosticsExtension -ResourceGroupName $RG -VMName $VMName `
  -Name $ExtensionName -Status
$output.SubStatuses[0] #stdout
$output.SubStatuses[1] #stderr
#Note in C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.9.5\RuntimeSettings settings the
#command executed etc can be seen in plain text
#Must remove as can only have one CSE per OS instance
Remove-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName -Force



#Now try a PowerShell file and this time with the command as private configuration
#Upload test file
Set-AzStorageBlobContent -File "$ModuleRoot\whoami.ps1" `
  -Container $containerName `
  -Blob "whoami.ps1" `
  -Context $storageContext

$fileUri = @("https://$($storageAccountName).blob.core.windows.net/$($containerName)/whoami.ps1")
$ExtensionName = 'WhoAmI2'
$ExtensionType = 'CustomScriptExtension'
$Publisher = 'Microsoft.Compute'
$Version = '1.9'
$timestamp = (Get-Date).Ticks

$PublicConfiguration = @{"fileUris" = $fileUri;"timestamp" = "$timestamp"}
$PrivateConfiguration = @{"commandToExecute" = "powershell.exe -ExecutionPolicy Unrestricted -Command .\whoami.ps1"}

Set-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Location $Location `
    -Name $ExtensionName -Publisher $Publisher -ExtensionType $ExtensionType -TypeHandlerVersion $Version `
    -Settings $PublicConfiguration -ProtectedSettings $PrivateConfiguration

#Note in C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.9.5\RuntimeSettings settings the protected settings is not readable
#Also under Status can see the output shows running as system
Get-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName
#View the output
$output = Get-AzVMDiagnosticsExtension -ResourceGroupName $RG -VMName $VMName `
  -Name $ExtensionName -Status
$output.SubStatuses[0] #stdout
$output.SubStatuses[1] #stderr

Remove-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName -Force



#Now for Linux
$RG = 'RG-Infra-SCUS'
$Location = 'southcentralus'
$VMName = 'savazuussclnx01'

Set-AzStorageBlobContent -File "$ModuleRoot\whoami.sh" `
  -Container $containerName `
  -Blob "whoami.sh" `
  -Context $storageContext

#Check on extension version
Get-AzVMExtensionImage -Location southcentralus -PublisherName Microsoft.Azure.Extensions -Type customScript

$fileUri = @("https://$($storageAccountName).blob.core.windows.net/$($containerName)/whoami.sh")
$ExtensionName = 'WhoAmI3'
$ExtensionType = 'CustomScript'
$Publisher = 'Microsoft.Azure.Extensions'
$Version = '2.0'

$PublicConfiguration = @{"fileUris" = $fileUri}
$PrivateConfiguration = @{"commandToExecute" = "bash whoami.sh"}

Set-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Location $Location `
    -Name $ExtensionName -Publisher $Publisher -ExtensionType $ExtensionType -TypeHandlerVersion $Version `
    -Settings $PublicConfiguration -ProtectedSettings $PrivateConfiguration

Get-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName
#View the output
#Stored at /var/lib/waagent/custom-script/download/0/
#e.g.   sudo head /var/lib/waagent/custom-script/download/0/stdout
#Log at /var/log/waagent.log
#View the output
((Get-AzVM -Name $VMName -ResourceGroupName $RG -Status).Extensions | Where-Object {$_.Name -eq $ExtensionName}).statuses.Message

Remove-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName -Force



#Advanced Example
#https://savilltech.com/2019/05/17/deploying-agents-to-azure-iaas-vms-using-the-custom-script-extension/

#Back to Windows
$RG = 'RG-Infra-SCUS'
$Location = 'southcentralus'
$VMName = 'Savazuusscwin10'

#This is only valid for 14 days at creation time!
$BLOBSASURI = (Get-AzKeyVaultSecret -vaultName 'SavKeyVault' -Name 'POCBLOBSASURIEsc').SecretValueText

#Container has public access since no sensitive information in files therefore no account or key required in private configuration
$fileUri = @("https://sasavpocscus.blob.core.windows.net/bootstrap/BootStrap.ps1","https://sasavpocscus.blob.core.windows.net/bootstrap/azcopy.exe")

$ExtensionName = 'BootStrap'
$ExtensionType = 'CustomScriptExtension'
$Publisher = 'Microsoft.Compute'
$Version = '1.9'
$timestamp = (Get-Date).Ticks

$PrivateConfiguration = @{"commandToExecute" = "powershell.exe -ExecutionPolicy Unrestricted -Command .\BootStrap.ps1 -SourceURI '$BLOBSASURI'"}
$PublicConfiguration = @{"fileUris" = $fileUri;"timestamp" = "$timestamp"}

Set-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Location $Location `
    -Name $ExtensionName -Publisher $Publisher -ExtensionType $ExtensionType -TypeHandlerVersion $Version `
    -Settings $PublicConfiguration -ProtectedSettings $PrivateConfiguration

Get-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName
#View the output
$output = Get-AzVMDiagnosticsExtension -ResourceGroupName $RG -VMName $VMName `
  -Name $ExtensionName -Status
$output.SubStatuses[0] #stdout
$output.SubStatuses[1] #stderr

((Get-AzVM -Name $VMName -ResourceGroupName $RG -Status).Extensions | Where-Object {$_.Name -eq $ExtensionName}).statuses

Remove-AzVMExtension -ResourceGroupName $RG -VMName $VMName -Name $ExtensionName -Force

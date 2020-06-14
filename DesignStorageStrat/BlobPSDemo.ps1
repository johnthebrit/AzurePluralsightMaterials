$storAccount = "sascussavilltech"
$storAccountRG = "mgmt-centralus"
$storContext = New-AzStorageContext -StorageAccountName $storAccount -UseConnectedAccount

#want to just look
Get-AzStorageAccount -StorageAccountName $storAccount -ResourceGroupName $storAccountRG
#OR to connect with key not OAUTH
$key = (Get-AzStorageAccountKey -Name $storAccount -ResourceGroupName $storAccountRG)[0].Value
$storContext = New-AzStorageContext -StorageAccountName $storAccount -StorageAccountKey $key

$storContainer = 'images2'
New-AzStorageContainer -Context $storContext -Name $storContainer #If wanted public -Permission Blob to download blob or Container to enumerate and access
Get-ChildItem –Path .\samples | Set-AzStorageBlobContent -Context $storContext -Container $storContainer
Get-AzStorageBlob -Context $storContext -Container $storContainer
#Download with Get-AzStorageBlob ... | Get-AzStorageBlobContent -Destination <local> -Context $StrContext
Get-AzStorageBlob -Context $storContext -Container $storContainer | Remove-AzStorageBlob -Context $storContext
Remove-AzStorageContainer -Context $storContext -Container $storContainer

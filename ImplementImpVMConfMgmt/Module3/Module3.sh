#Azure VM Image Builder

#Give image builder service permission into the image gallery
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/<your sub>/resourceGroups/RG-AzureBuilder

#Create the template definition in Azure
az resource create \
    --resource-group RG-AzureBuilder \
    --properties @AzureVMImageBuilderLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n UbuntuCustomTemplate

#To view
az resource list \
    --resource-group RG-AzureBuilder \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates

#Create the target, e.g. a shared image (this will create an actual VM during the process in its RG, e.g)
#IT_RG-AzureBuilder_UbuntuCustomTemplate
az resource invoke-action \
    --resource-group RG-AzureBuilder \
    --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
    -n UbuntuCustomTemplate \
    --action Run


az vm create \
  --resource-group RG-Target \
  --name aibImgVm01 \
  --admin-username tstuser \
  --location southcentralus \
  --image "/subscriptions/<your sub>/resourceGroups/RG-AzureBuilder/providers/Microsoft.Compute/galleries/SharedImages/images/UbuntuServer1804LTS/versions/latest" \
  --generate-ssh-keys


#Linux AAD PAM
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory.LinuxSSH \
    --name AADLoginForLinux \
    --resource-group RG-Infra-SCUS \
    --vm-name savazuussclnx01

#connect from the win10 client
ssh -l john@savilltech.net 10.0.1.40
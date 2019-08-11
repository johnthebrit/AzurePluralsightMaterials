#Resource Provider Commands

    #View all locations
    Get-AzLocation | Format-Table Location, DisplayName -AutoSize

    #List the resource providers that are registered
    Get-AzResourceProvider -Location "southcentralus"
    #Count
    Get-AzResourceProvider -Location "southcentralus" | Measure-Object

    #List all that are available
    Get-AzResourceProvider -Location "southcentralus" -ListAvailable
    Get-AzResourceProvider -Location "southcentralus" -ListAvailable | Where-Object {$_.RegistrationState -eq 'NotRegistered'} | Format-Table ProviderNamespace, ResourceTypes -AutoSize
    Get-AzResourceProvider -Location "southcentralus" -ListAvailable | Where-Object {$_.RegistrationState -eq 'NotRegistered'} | Measure-Object

    #To register all. Don't recommend!!!!
    Get-AzResourceProvider -ListAvailable | foreach-object{Register-AzResourceProvider -ProviderNamespace $_.ProviderNamespace}

    #Custom role for registration
    $role = Get-AzRoleDefinition -Name "Virtual Machine Contributor"
    $role.Id = $null
    $role.Name = "Resource Provider Register"
    $role.Description = "Can register Resource Providers."
    $role.Actions.RemoveRange(0,$role.Actions.Count)
    $role.Actions.Add("*/register/action")
    $role.AssignableScopes.Clear()
    $role.AssignableScopes.Add($sub)
    New-AzRoleDefinition -Role $role
    #Assign to a group
    $group = Get-AzADGroup -SearchString "GroupName"
    New-AzRoleAssignment -ObjectId $group.Id `
        -RoleDefinitionName $role.Name -Scope $sub

    #Look inside a resource provider
    Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
    (Get-AzResourceProvider -ProviderNamespace Microsoft.Compute).ResourceTypes.ResourceTypeName
    #Where is a resource type available
    ((Get-AzResourceProvider -ProviderNamespace Microsoft.Compute).ResourceTypes | Where-Object ResourceTypeName -EQ virtualMachines).Locations
    #Specific permission require to register
    Get-AzResourceProviderAction -OperationSearchString "Microsoft.Compute/register/action" | Format-Table Operation, Description -AutoSize
    #Actions available for a specific type of resource within the provider
    Get-AzResourceProviderAction -OperationSearchString "Microsoft.Compute/virtualMachines/*" | Format-Table Operation, Description -AutoSize
    #Check the API versions available
    ((Get-AzResourceProvider -ProviderNamespace Microsoft.Compute).ResourceTypes | Where-Object ResourceTypeName -EQ virtualMachines).ApiVersions

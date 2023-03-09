
targetScope = 'subscription'

// TODO: verify the required parameters

// Global Parameters

param avdAutoscaleRoleInfo object 
param avdStartOnConnectRoleInfo object 

/*
To assign this role to the Windows Virtual Desktop service principal, use the following PowerShell command:
The application ID for this service principal is 9cdead84-a844-4324-93f2-b2e6bb768d07.
$objId = (Get-AzADServicePrincipal -AppId "9cdead84-a844-4324-93f2-b2e6bb768d07").Id
Get-AzSubscription
$subId = (Get-AzSubscription -SubscriptionName "Microsoft Azure Enterprise").Id
New-AzRoleAssignment -RoleDefinitionName "Desktop Virtualization Power On Off Contributor" -ObjectId $objId -Scope /subscriptions/$subId
Here we are using a custom role definition to assign the required permissions to the Windows Virtual Desktop service principal, but you can 
directly assign the built-in role "Desktop Virtualization Power On Off Contributor" to the service principal if you prefer.
*/
module avdAutoscaleRoleResources '../../modules/Microsoft.Authorization/role.bicep' = {
  name: 'avdAutoscaleRoleRss_Deploy'
  params: {
    name: avdAutoscaleRoleInfo.name
    description: avdAutoscaleRoleInfo.description
    actions: avdAutoscaleRoleInfo.actions
    principalId: avdAutoscaleRoleInfo.principalId
  }
}

module avdStartOnConnectRoleResources '../../modules/Microsoft.Authorization/role.bicep' = {
  name: 'avdStartOnConnectRoleRss_Deploy'
  params: {
    name: avdStartOnConnectRoleInfo.name
    description: avdStartOnConnectRoleInfo.description
    actions: avdStartOnConnectRoleInfo.actions
    principalId: avdStartOnConnectRoleInfo.principalId
  }
}


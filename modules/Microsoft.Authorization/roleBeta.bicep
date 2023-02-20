

param name string 
param description string
param actions array
param principalId string


var roleDefName = guid(name, resourceGroup().id, string(actions))
var roleAssigmentName = guid(name, resourceGroup().id, principalId)



resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefName
  properties: {
    roleName: name
    type: 'customRole'
    assignableScopes: [ 
      '${resourceGroup().id}'
    ]
    description: description
    permissions: [
      {
        actions: actions
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

// az ad sp show --id 26da2792-4d23-4313-b9e7-60bd7c1bf0b1 to get principalId
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleAssigmentName
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: role.id
  }
}

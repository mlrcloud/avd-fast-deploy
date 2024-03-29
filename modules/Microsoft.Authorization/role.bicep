targetScope = 'subscription'

param name string 
param description string
param actions array
param principalId string


var roleDefName = guid(subscription().id, string(actions))


resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefName
  properties: {
    roleName: name
    type: 'customRole'
    assignableScopes: [ 
      '${subscription().id}'
      //'${subscription().id}/resourcegroups/rg-avd-data'
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


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(name, 'Role Assignment')
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: role.id
  }
}

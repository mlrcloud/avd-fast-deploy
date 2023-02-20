
targetScope = 'subscription'

// TODO: verify the required parameters

// Global Parameters

param avdAutoscaleRoleInfo object 
param avdStartOnConnectRoleInfo object 


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


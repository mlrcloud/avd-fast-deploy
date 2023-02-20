

param location string = resourceGroup().location
param tags object
param logWorkspaceName string 
param monitoringResourceGroupName string
param name string
param deployDiagnostic bool 
param hostPoolName string
param applicationGroupFriendlyName string
param description string
param applicationGroupType string 


resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logWorkspaceName
  scope: resourceGroup(monitoringResourceGroupName)
}


resource hostPools 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existing = {
  name: hostPoolName
}

resource applicationGroups 'Microsoft.DesktopVirtualization/applicationgroups@2021-07-12' = {
  name: name
  location: location
  tags: tags
  properties: {
    hostPoolArmPath: hostPools.id
    friendlyName: applicationGroupFriendlyName
    description: description
    applicationGroupType: applicationGroupType
  }
}


resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (deployDiagnostic) {
  name: '${name}-diagsetting'
  scope: applicationGroups
  properties: {
    storageAccountId: null
    eventHubAuthorizationRuleId: null
    eventHubName: null
    workspaceId: logWorkspace.id
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
        retentionPolicy: {
          days: 365
          enabled: true
        }
      }
      {
        category: 'Error'
        enabled: true
        retentionPolicy: {
          days: 365
          enabled: true
        }
      }
      {
        category: 'Management'
        enabled: true
        retentionPolicy: {
          days: 365
          enabled: true
        }
      }
    ]
  }
}


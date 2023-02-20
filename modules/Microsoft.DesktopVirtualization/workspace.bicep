param location string = resourceGroup().location
param tags object
param logWorkspaceName string 
param monitoringResourceGroupName string
param name string
param deployDiagnostic bool 
param applicationGroupIds array


resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logWorkspaceName
  scope: resourceGroup(monitoringResourceGroupName)
}


resource workspace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    applicationGroupReferences: applicationGroupIds
  }
}


resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (deployDiagnostic) {
  name: '${name}-diagsetting'
  scope: workspace
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
      {
        category: 'Feed'
        enabled: true
        retentionPolicy: {
          days: 365
          enabled: true
        }
      }
    ]
  }
}


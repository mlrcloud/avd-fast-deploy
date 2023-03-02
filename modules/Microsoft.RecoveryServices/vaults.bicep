
param location string = resourceGroup().location
param tags object
param name string
param publicNetworkAccess string

resource vaults 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    monitoringSettings: {
      azureMonitorAlertSettings: {
        alertsForAllJobFailures: 'Enabled'
      }
      classicAlertSettings: {
        alertsForCriticalOperations: 'Disabled'
      }
    }
    publicNetworkAccess: publicNetworkAccess
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}



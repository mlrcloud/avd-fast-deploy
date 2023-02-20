
param location string = resourceGroup().location
param tags object
param vmName string


resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' existing = {
  name: vmName
}

resource dependencyAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm
  name: 'DependencyAgentWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.6'
    autoUpgradeMinorVersion: true
  }
}

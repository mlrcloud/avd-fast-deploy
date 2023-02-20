
param location string = resourceGroup().location
param tags object
param name string 
param vmName string
param domainToJoin string
param ouPath string
param domainAdminUsername string
@secure()
param domainAdminPassword string

//TODO: COMPLETE


resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' existing = {
  name: vmName
}

resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: name
  parent: vm
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainAdminUsername}@${domainToJoin}'
      restart: 'true'
      options: '3'
      NumberOfRetries: '4'
      RetryIntervalInMilliseconds: '30000'
    }
    protectedSettings: {
      password: domainAdminPassword
    }
  }
}


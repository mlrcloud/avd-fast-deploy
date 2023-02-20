
param location string = resourceGroup().location
param tags object
param name string 
param avSetSku string



resource availabilitySet 'Microsoft.Compute/availabilitySets@2021-04-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
  sku: {
    name: avSetSku
  }
}

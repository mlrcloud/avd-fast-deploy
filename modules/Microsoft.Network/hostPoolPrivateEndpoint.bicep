
param location string = resourceGroup().location
param tags object
param name string
param vnetName string
param snetName string
param hostPoolName string
param privateDnsZoneName string
param groupIds string
param centralDnsResourceGroupName string
param vnetResourceGroupName string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: snetName
  parent: vnet
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' existing = {
  name: hostPoolName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  scope: resourceGroup(centralDnsResourceGroupName)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          groupIds: [ 
            groupIds 
          ]
          privateLinkServiceId: hostPool.id
        }
      }
    ]
    subnet: {
      id: snet.id
    }
  }
}

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: format('{0}/{1}', name, '${groupIds}PrivateDnsZoneGroup')
  dependsOn: [
    privateEndpoint
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

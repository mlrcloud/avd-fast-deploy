
// TODO: verify the required parameters

// Global Parameters
param location string = resourceGroup().location
param tags object
param privateDnsZoneInfo object
param avdResourceGroupName string
param centralDnsResourceGroupName string
param centralDnsExists bool
param avdVnetName string
param hostPoolName string
param storageAccountInfo object
param profilesInfo object



module privateDnsZone '../../modules/Microsoft.Network/privateDnsZone.bicep' = if (centralDnsExists == false ) {
  name: 'privateDnsZoneRss_Deploy'
  params: {
    location: 'global'
    tags: tags
    name: privateDnsZoneInfo.name
  }
}

module avdVnetLink '../../modules/Microsoft.Network/vnetLink.bicep' = if (centralDnsExists == false ) {
  name: 'avdVnetLinkRss_Deploy'
  dependsOn: [
    privateDnsZone
  ]
  params: {
    tags: tags
    name: '${privateDnsZoneInfo.vnetLinkPrefix}avd'
    vnetName: avdVnetName
    privateDnsZoneName: privateDnsZoneInfo.name
    vnetResourceGroupName: avdResourceGroupName
  }
}

module storageAccountResources '../../modules/Microsoft.Storage/storageAccount.bicep' = {
  name: 'storageAccountRssFor${hostPoolName}_Deploy'
  params: {
    location: location
    tags: tags
    name: '${storageAccountInfo.prefix}${hostPoolName}'
    sku: storageAccountInfo.sku
    kind: storageAccountInfo.kind
  }
}

module fileShareResources '../../modules/Microsoft.Storage/fileShare.bicep' = {
  name: 'fileShareRss_Deploy'
  dependsOn: [
    storageAccountResources
  ]
  params: {
    name: profilesInfo.fileShareName
    storageAccountName: '${storageAccountInfo.prefix}${hostPoolName}'
    tier: profilesInfo.fileShareTier
  }
}

module filePrivateEndpointResources '../../modules/Microsoft.Network/storagePrivateEndpoint.bicep' = {
  name: 'filePrivateEndpointRss_Deploy'
  dependsOn: [
    privateDnsZone
    storageAccountResources
  ]
  params: {
    location: location
    tags: tags
    name: storageAccountInfo.privateEndpointName
    vnetName: avdVnetName
    snetName: profilesInfo.snetName
    storageAccountName: '${storageAccountInfo.prefix}${hostPoolName}'
    privateDnsZoneName: privateDnsZoneInfo.name
    groupIds: 'file'
    centralDnsExists: centralDnsExists
    centralDnsResourceGroupName: centralDnsResourceGroupName
    vnetResourceGroupName: avdResourceGroupName
  }
}





param location string = resourceGroup().location
param tags object

param fileShareName string
param vnetResourceGroupName string
param vnetName string
param snetName string

param domainUsername string
@secure()
param domainPassword string
param domainName string
param serverName string
param dnsAddresses string


module netAppStorage '../../modules/Microsoft.NetApp/netappaccount.bicep' = {
  name: 'netApp_Deploy'
  params: {
    name: fileShareName
    location: location
    tags: tags
    dnsAddresses: dnsAddresses
    serverName: serverName
    subnetName: snetName
    domainUsername: domainUsername
    domainName: domainName
    vnetResourceGroup: vnetResourceGroupName
    vnetName: vnetName
    domainPassword: domainPassword
  }
}

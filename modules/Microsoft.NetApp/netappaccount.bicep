
param name string
param location string
param tags object

param domainName string
param serverName string
param dnsAddresses string
param domainUsername string
@secure()
param domainPassword string

param capacityPoolName string = 'profilesPool'
param capacityPoolServiceLevel string = 'Standard'
param capacityPoolSize int = 4398046511104


param volumenName string = 'profiles'
param filePath string = 'volumes'
param vnetResourceGroup string
param vnetName string
param subnetName string
param volumenThreshold int = 4398046511104


resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)    
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

resource account 'Microsoft.NetApp/netAppAccounts@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    activeDirectories: [
      {
        domain: domainName
        dns: dnsAddresses
        username: domainUsername
        password: domainPassword
        smbServerName: serverName

      }
    ]
  }
}

resource pool 'Microsoft.NetApp/netAppAccounts/capacityPools@2021-08-01' = {
  name: capacityPoolName
  location: location
  tags: tags
  parent: account
  properties: {
    serviceLevel: capacityPoolServiceLevel
    size: capacityPoolSize
  }
}

resource volumen 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2021-08-01' = {
  name: volumenName
  location: location
  tags: tags
  parent: pool
  properties: {
    creationToken: filePath
    subnetId: subnet.id
    usageThreshold: volumenThreshold
  }
}

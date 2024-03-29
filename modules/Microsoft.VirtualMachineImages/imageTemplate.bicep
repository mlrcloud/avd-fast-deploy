
param location string = resourceGroup().location
param tags object
param name string
param vnetName string
param subnetName string
param deployVnetConfig bool
param imageBuilderIdentityName string
param galleryName string
param imageDefinitionName string
param source object
param customize array
param imageVersion string
param runOutputName string
param replicationRegions array
param artifactsTags object

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

resource imageBuilderIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: imageBuilderIdentityName
}

resource gallery 'Microsoft.Compute/galleries@2020-09-30' existing = {
  name: galleryName
}

resource imageDefinition 'Microsoft.Compute/galleries/images@2020-09-30' existing = {
  parent: gallery
  name: imageDefinitionName
}

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2021-10-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${imageBuilderIdentity.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 120
    vmProfile: {
      vmSize: 'Standard_D2as_v4'
      osDiskSizeGB: 127
      vnetConfig: (deployVnetConfig) ? {
        subnetId: subnet.id
      }: json('null')
    }
    source: source
    customize: customize
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: '${imageDefinition.id}/versions/${imageVersion}'
        runOutputName: runOutputName
        artifactTags: artifactsTags
        replicationRegions: replicationRegions
      }
    ]
  }
}



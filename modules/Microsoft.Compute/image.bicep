
param location string = resourceGroup().location
param tags object
param name string 
param galleryName string
param imageDefinitionProperties object

resource gallery 'Microsoft.Compute/galleries@2020-09-30' existing = {
  name: galleryName
}

resource image 'Microsoft.Compute/galleries/images@2020-09-30' = {
  parent: gallery
  name: name
  location: location
  tags: tags
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      offer: imageDefinitionProperties.offer
      publisher: imageDefinitionProperties.publisher
      sku: imageDefinitionProperties.sku
    }
    recommended: {
      vCPUs: {
        min: 2
        max: 8
      }
      memory: {
        min: 16
        max: 48
      }
    }  
    hyperVGeneration: imageDefinitionProperties.vmGeneration
  }
}

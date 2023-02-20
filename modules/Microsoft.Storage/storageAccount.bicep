
param location string = resourceGroup().location
param tags object
param name string 
param sku string
param kind string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
}

// #TODO File services are enabled in every storage account using this module althought
// it may be not needed. 

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

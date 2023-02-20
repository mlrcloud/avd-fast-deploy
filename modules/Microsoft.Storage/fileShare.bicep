

param name string
param storageAccountName string
param tier string

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-06-01' = {
  name: '${storageAccountName}/default/${name}'
  properties: {
    accessTier: tier
  }
}

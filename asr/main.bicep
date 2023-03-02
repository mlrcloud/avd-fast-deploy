targetScope = 'subscription'

// Global Parameters

@description('Azure region where resource would be deployed')
param location string
@description('Tags associated with all resources')
param tags object

// Resource Group Names

@description('Resource Groups names')
param resourceGroupNames object
var asrResourceGroupName = resourceGroupNames.asr

// Vault parameters

param asrConfig object
var vaultName = asrConfig.vaultName
var publicNetworkAccess = asrConfig.publicNetworkAccess

/* 
  ASR Resource Group deployment 
*/
resource asrResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: asrResourceGroupName
  location: location
}

/* 
  Azure Site Recovery Vault resources deployment 
*/
module vaultResources '../modules/Microsoft.RecoveryServices/vaults.bicep' = {
  scope: asrResourceGroup
  name: 'vaultRss_Deploy'
  params: {
    location: location
    tags: tags
    name: vaultName
    publicNetworkAccess: publicNetworkAccess
  }
}


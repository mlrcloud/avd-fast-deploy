
targetScope = 'subscription'

// Global Parameters

@description('Azure region where resource would be deployed')
param location string
@description('Tags associated with all resources')
param tags object

// Resource Group Names

@description('Resource Groups names')
param resourceGroupNames object

/* 
  Azure Files Profiles Resource Group deployment 
*/
resource azFilesProfilesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupNames.azFilesProfiles
  location: location
  tags: tags
}

/* 
  Azure Files Profiles Resources deployment 
*/

var privateDnsZoneInfo = {
  name: format('privatelink.file.{0}', environment().suffixes.storage)
  vnetLinkPrefix: 'vnet-link-file-to-'
}


param hostPoolName string
param storageAccountInfo object
param profilesInfo object
param centralDnsExists bool
param vnets object

module azFilesProfilesResources 'azfilesResources.bicep' = {
  scope: azFilesProfilesResourceGroup
  name: 'azFilesProfilesRss_Deploy'
  params: {
    location: location
    tags: tags
    privateDnsZoneInfo: privateDnsZoneInfo
    avdResourceGroupName: resourceGroupNames.avd
    centralDnsResourceGroupName: resourceGroupNames.centralDns
    centralDnsExists: centralDnsExists
    avdVnetName: vnets.avd
    hostPoolName: hostPoolName
    storageAccountInfo: storageAccountInfo
    profilesInfo: profilesInfo

  }
}

param joinerServerConfiguration object
param monitoringOptions object
@secure()
param vmAdminPassword string
var jsonADDomainExtensionName = 'JsonADDomainExtension'
@secure()
param existingDomainAdminPassword string

module joinerServerResources 'joinerServerResources.bicep' = {
  scope: azFilesProfilesResourceGroup
  name: 'joinerServerRss_Deploy'
  params: {
    location: location
    tags: tags
    resourceGroupNames: resourceGroupNames
    joinerServerConfiguration: joinerServerConfiguration
    vmAdminPassword: vmAdminPassword
    jsonADDomainExtensionName: jsonADDomainExtensionName
    existingDomainAdminPassword: existingDomainAdminPassword
    monitoringOptions: monitoringOptions

  }
}

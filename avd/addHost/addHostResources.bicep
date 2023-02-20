
param location string = resourceGroup().location
param tags object
param artifactsLocation string
param avdNumberOfInstances int
param currentInstances int
param hostPoolName string
param hostPoolType string
param domainToJoin string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

param vmPrefix string
param localVmAdminUsername string
@secure()
param localVmAdminPassword string

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string
param aadLogin bool
param vmSize string
param vmRedundancy string
param availabilityZones array
param existingDomainAdminName string
param existingDomainAdminPassword string
param networkAvdResourceGroupName string
param existingVnetName string
param existingSnetName string

param vmGalleryImage object

param diagnosticsStorageAccountName string
param monitoringResourceGroupName string
param logWorkspaceName string


var avSetSku = 'Aligned'
var networkAdapterPrefix = 'nic-'

var joinDomainExtensionName = 'JsonADDomainExtension'
var aadLoginExtensionName = 'aadLoginExtension'
var dscExtensionName = 'dscExtension'

module nicResources '../../modules/Microsoft.Network/nic.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'nicRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  params: {
    location: location
    tags: tags
    name: '${networkAdapterPrefix}${vmPrefix}-${i + currentInstances}'
    vnetName: existingVnetName
    vnetResourceGroupName: networkAvdResourceGroupName
    snetName: existingSnetName
    nsgName: ''
  }
}]

module availabilitySetResources '../../modules/Microsoft.Compute/availabilitySet.bicep' = if (vmRedundancy == 'availabilitySet') {
  name: 'availabilitySetRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  params: {
    location: location
    tags: tags
    name: '${vmPrefix}-av'
    avSetSku: avSetSku
  }
}

module vmResources '../../modules/Microsoft.Compute/vm.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'vmRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    nicResources
    availabilitySetResources
  ]
  params: {
    location: location
    tags: tags
    name: '${vmPrefix}-${i + currentInstances}'
    aadLogin: aadLogin
    vmSize: vmSize
    vmRedundancy: vmRedundancy
    availabilitySetName: (vmRedundancy == 'availabilitySet') ? '${vmPrefix}-av' : ''
    availabilityZones: availabilityZones
    adminUsername: localVmAdminUsername
    adminPassword: localVmAdminPassword
    nicName: '${networkAdapterPrefix}${vmPrefix}-${i + currentInstances}'
    osDiskName: '${vmPrefix}-${i + currentInstances}-os'
    storageAccountType: vmDiskType
    vmGalleryImage: vmGalleryImage
    loopIndex: avdNumberOfInstances
  }
}]

module joinDomainExtensionResources '../../modules/Microsoft.Compute/joinDomainExtension.bicep' = [for i in range(0, avdNumberOfInstances): if (!aadLogin) {
  name: 'joinDomainExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
  ]
  params: {
    location: location
    tags: tags
    name: joinDomainExtensionName
    vmName: '${vmPrefix}-${i + currentInstances}'
    domainToJoin: domainToJoin
    ouPath: ouPath
    domainAdminUsername: existingDomainAdminName
    domainAdminPassword: existingDomainAdminPassword
  }
}]

module aadLoginExtensionResources '../../modules/Microsoft.Compute/aadLoginExtension.bicep' = [for i in range(0, avdNumberOfInstances): if (aadLogin) {
  name: 'aadLoginExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
  ]
  params: {
    location: location
    tags: tags
    name: aadLoginExtensionName
    vmName: '${vmPrefix}-${i + currentInstances}'
  }
}]

module dscExtensionResources '../../modules/Microsoft.Compute/dscExtension.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'dscExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
    joinDomainExtensionResources
    aadLoginExtensionResources
  ]
  params: {
    location: location
    tags: tags
    name: dscExtensionName
    vmName: '${vmPrefix}-${i + currentInstances}' 
    artifactsLocation: artifactsLocation
    hostPoolName: hostPoolName
  }
}]

module daExtensionResources '../../modules/Microsoft.Compute/daExtension.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'daExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
    dscExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: '${vmPrefix}-${i + currentInstances}'
  }
}]

module diagnosticsExtensionResources '../../modules/Microsoft.Compute/diagnosticsExtension.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'diagnosticsExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
    daExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: '${vmPrefix}-${i + currentInstances}'
    diagnosticsStorageAccountName: diagnosticsStorageAccountName
    monitoringResourceGroupName: monitoringResourceGroupName
  }
}]

module monitoringAgentExtensionResources '../../modules/Microsoft.Compute/monitoringAgentExtension.bicep' = [for i in range(0, avdNumberOfInstances): {
  name: 'monitoringAgentExtensionRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i + currentInstances}'
  dependsOn: [
    vmResources
    diagnosticsExtensionResources
    daExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: '${vmPrefix}-${i + currentInstances}'
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
  }
}]


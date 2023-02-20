
// TODO: verify the required parameters

// Global Parameters
param location string = resourceGroup().location
param tags object
param resourceGroupNames object
param joinerServerConfiguration object
@secure()
param vmAdminPassword string
param jsonADDomainExtensionName string
@secure()
param existingDomainAdminPassword string
param monitoringOptions object


module nicResources '../../modules/Microsoft.Network/nic.bicep' = {
  name: 'nicRss_Deploy'
  params: {
    tags: tags
    name: joinerServerConfiguration.networkConfiguration.nicName
    location: location
    vnetName: joinerServerConfiguration.networkConfiguration.vnetName
    vnetResourceGroupName: resourceGroupNames.avd
    snetName: joinerServerConfiguration.networkConfiguration.snetName
    nsgName: ''
  }
}

module vmResources '../../modules/Microsoft.Compute/vm.bicep' = {
  name: 'vmRss_Deploy'
  dependsOn: [
    nicResources
  ]
  params: {
    location: location
    tags: tags
    name: joinerServerConfiguration.vmName
    aadLogin: joinerServerConfiguration.aadLogin
    vmSize: joinerServerConfiguration.vmSku
    vmRedundancy: joinerServerConfiguration.vmRedundancy
    availabilitySetName: (joinerServerConfiguration.vmRedundancy == 'availabilitySet') ? '${joinerServerConfiguration.vmName}-av' : ''
    availabilityZone: joinerServerConfiguration.vmAzNumber
    adminUsername: joinerServerConfiguration.vmAdminUsername
    adminPassword: vmAdminPassword
    nicName: joinerServerConfiguration.networkConfiguration.nicName
    osDiskName: '${joinerServerConfiguration.vmName}-os'
    storageAccountType: joinerServerConfiguration.vmDiskType
    vmGalleryImage: joinerServerConfiguration.vmImage
  }
}

module joinDomainExtensionResources '../../modules/Microsoft.Compute/joinDomainExtension.bicep' = {
  name: 'joinDomainExtensionRss'
  dependsOn: [
    vmResources
  ]
  params: {
    location: location
    tags: tags
    name: jsonADDomainExtensionName
    vmName: joinerServerConfiguration.vmName
    domainToJoin: joinerServerConfiguration.domainConfiguration.name
    ouPath: joinerServerConfiguration.domainConfiguration.ouPath
    domainAdminUsername: joinerServerConfiguration.domainConfiguration.vmJoinUserName
    domainAdminPassword: existingDomainAdminPassword
  }
}

module daExtensionResources '../../modules/Microsoft.Compute/daExtension.bicep' = {
  name: 'daExtensionRss_Deploy'
  dependsOn: [
    joinDomainExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: joinerServerConfiguration.vmName
  }
}

module diagnosticsExtensionResources '../../modules/Microsoft.Compute/diagnosticsExtension.bicep' = {
  name: 'diagnosticsExtensionRss_Deploy'
  dependsOn: [
    daExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: joinerServerConfiguration.vmName
    diagnosticsStorageAccountName: monitoringOptions.diagnosticsStorageAccountName
    monitoringResourceGroupName: resourceGroupNames.monitoring
  }
}

module monitoringAgentExtensionResources '../../modules/Microsoft.Compute/monitoringAgentExtension.bicep' = {
  name: 'monitoringAgentExtensionRss_Deploy'
  dependsOn: [
    diagnosticsExtensionResources
  ]
  params: {
    location: location
    tags: tags
    vmName: joinerServerConfiguration.vmName
    logWorkspaceName: monitoringOptions.newOrExistingLogAnalyticsWorkspaceName
    monitoringResourceGroupName: resourceGroupNames.monitoring
  }
}





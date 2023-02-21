targetScope = 'subscription'

// Global Parameters

@description('Azure region where resource would be deployed')
param location string
@description('Tags associated with all resources')
param tags object

// Resource Group Names

@description('Resource Groups names')
param resourceGroupNames object

var monitoringResourceGroupName = resourceGroupNames.monitoring
var networkAvdResourceGroupName = resourceGroupNames.avdNetworking
var avdResourceGroupName = resourceGroupNames.avd

// Monitoring resources

@description('Monitoring options')
param monitoringOptions object

var logWorkspaceName = monitoringOptions.newOrExistingLogAnalyticsWorkspaceName
var diagnosticsStorageAccountName = monitoringOptions.diagnosticsStorageAccountName

// Role definitions

@description('Azure ARM RBAC role definitions to configure for autoscale and start on connect')
param roleDefinitions object

var avdAutoscaleRoleInfo = roleDefinitions.avdAutoScaleRole
var avdStartOnConnectRoleInfo = roleDefinitions.avdStartOnConnectRole

// Pool VM configuration

@description('Virtual Machine configuration')
param vmConfiguration object

var vmPrefix = vmConfiguration.prefixName
var vmDiskType = vmConfiguration.diskType
var aadLogin = vmConfiguration.aadLogin
var vmSize = vmConfiguration.sku
var vmRedundancy = vmConfiguration.redundancy
var vmAvailabilityZones = vmConfiguration.availabilityZones
var vmGalleryImage = vmConfiguration.image
var localVmAdminUsername = vmConfiguration.adminUsername
@secure()
param localVmAdminPassword string

var domainToJoin = vmConfiguration.domainConfiguration.name
var ouPath = vmConfiguration.domainConfiguration.ouPath
var existingDomainAdminName = vmConfiguration.domainConfiguration.vmJoinUserName
@secure()
param existingDomainAdminPassword string

var artifactsLocation = vmConfiguration.hostPoolRegistration.artifactsLocation

var existingAvdVnetName = vmConfiguration.networkConfiguration.vnetName
var existingSubnetName = vmConfiguration.networkConfiguration.subnetName

// Azure Virtual Desktop Configuration

@description('Azure Virtual Desktop Configuration')
param avdConfiguration object

// Azure Virtual Desktop Workspace Configuration

param deploymentFromScratch bool
var newScenario = deploymentFromScratch

var newOrExistingWorkspaceName = avdConfiguration.workspaces.feedWorkSpace.name
var workspacePrivateEndpointName = avdConfiguration.workSpace.privateEndpointName
var groupIdWorkspace = avdConfiguration.workSpace.groupId


// Azure Virtual Desktop Private Link Configuration

var avdPrivateLinkEnabled = avdConfiguration.avdPrivateLink.deployPrivateLink
var placeholderWorkspaceName = avdConfiguration.avdPrivateLink.placeholderWorkspace.name
var placeholderWorkspacePrivateEndpointName = avdConfiguration.avdPrivateLink.placeholderWorkspace.privateEndpointName
var groupIdPlaceholderWorkspace = avdConfiguration.avdPrivateLink.placeholderWorkspace.groupId
var deployPlaceholderWorkspaceDiagnostic = avdConfiguration.avdPrivateLink.placeholderWorkspace.deployDiagnostics

// Azure Virtual Desktop Pool Configuration

var addHost = avdConfiguration.hostPool.addHosts

var hostPoolName = avdConfiguration.hostPool.name
var hostPoolFriendlyName = hostPoolName
var hostPoolType = avdConfiguration.hostPool.type
var personalDesktopAssignmentType = avdConfiguration.hostPool.assignmentType

var avdNumberOfInstances = avdConfiguration.hostPool.instances
var currentInstances = avdConfiguration.hostPool.currentInstances
var maxSessionLimit = avdConfiguration.hostPool.maxSessions

var customRdpProperty = avdConfiguration.hostPool.rdpProperties

var tokenExpirationTime = avdConfiguration.hostPool.tokenExpirationTime

var desktopApplicationGroupName = '${hostPoolName}-dag'
var remoteAppApplicationGroupName = '${hostPoolName}-rag'

var appsListInfo = avdConfiguration.hostPool.apps

// Azure Virtual Desktop Scale Plan

var scalingPlanName = avdConfiguration.hostPool.scalePlan.name
var timeZone = avdConfiguration.hostPool.scalePlan.timeZone
var schedules = avdConfiguration.hostPool.scalePlan.schedules
var scalingPlanEnabled = avdConfiguration.hostPool.scalePlan.enabled
var exclusionTag = avdConfiguration.hostPool.scalePlan.exclusionTag
var existingApplicationGroupIds = avdConfiguration.workSpace.existingApplicationGroupIds

// Azure Virtual Desktop Monitoring Configuration

var deployWorkspaceDiagnostic = avdConfiguration.workSpace.deployDiagnostics
var deployHostPoolDiagnostic = avdConfiguration.monitoring.deployHostPoolDiagnostics
var deployDesktopApplicationGroupDiagnostic = avdConfiguration.monitoring.deployDesktopDiagnostics
var deployRemoteAppApplicationGroupDiagnostic = avdConfiguration.monitoring.deployRemoteAppDiagnostics

/* 
  AVD Resource Group deployment 
*/
resource avdResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: avdResourceGroupName
  location: location
}

/* 
  Azure RBAC role resources deployment 
*/
module iamResources 'iam/iamResources.bicep' = if (newScenario) {
  name: 'iamRss_Deploy'
  params: {
    avdAutoscaleRoleInfo: avdAutoscaleRoleInfo
    avdStartOnConnectRoleInfo: avdStartOnConnectRoleInfo
  }
}

/* 
  Azure Virtual Desktop resources deployment 
*/
module environmentResources 'environment/environmentResources.bicep' = if (newScenario) {
  scope: avdResourceGroup
  name: 'environmentRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  params: {
    location: location
    tags: tags
    avdPrivateLinkEnabled: avdPrivateLinkEnabled
    placeholderWorkspaceName: placeholderWorkspaceName
    placeholderWorkspacePrivateEndpointName: placeholderWorkspacePrivateEndpointName
    groupIdPlaceholderWorkspace: groupIdPlaceholderWorkspace
    deployPlaceholderWorkspaceDiagnostic: deployPlaceholderWorkspaceDiagnostic
    newOrExistingWorkspaceName: newOrExistingWorkspaceName
    workspacePrivateEndpointName: workspacePrivateEndpointName
    groupIdWorkspace: groupIdWorkspace
    deployWorkspaceDiagnostic: deployWorkspaceDiagnostic
    hostPoolName: hostPoolName
    hostPoolFriendlyName: hostPoolFriendlyName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    hostPoolType: hostPoolType
    deployHostPoolDiagnostic: deployHostPoolDiagnostic
    maxSessionLimit: maxSessionLimit
    tokenExpirationTime: tokenExpirationTime
    scalingPlanName: scalingPlanName
    timeZone: timeZone
    schedules: schedules
    scalingPlanEnabled: scalingPlanEnabled
    exclusionTag: exclusionTag
    existingApplicationGroupIds: existingApplicationGroupIds
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    desktopApplicationGroupName: desktopApplicationGroupName
    deployDesktopApplicationGroupDiagnostic: deployDesktopApplicationGroupDiagnostic
    remoteAppApplicationGroupName: remoteAppApplicationGroupName
    deployRemoteAppApplicationGroupDiagnostic: deployRemoteAppApplicationGroupDiagnostic
    appsListInfo: appsListInfo
  }
}

/* 
  Azure Virtual Desktop Hosts resources deployment 
*/
module addHostResources 'addHost/addHostResources.bicep' = if (addHost) {
  scope: avdResourceGroup
  name: 'addHostRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    environmentResources
  ]
  params: {
    location: location
    tags: tags
    artifactsLocation: artifactsLocation
    avdNumberOfInstances: avdNumberOfInstances
    currentInstances: currentInstances
    hostPoolName: hostPoolName
    hostPoolType: hostPoolType
    domainToJoin: domainToJoin
    ouPath: ouPath
    vmPrefix: vmPrefix
    localVmAdminUsername: localVmAdminUsername
    localVmAdminPassword: localVmAdminPassword
    vmDiskType: vmDiskType
    aadLogin: aadLogin
    vmSize: vmSize
    vmRedundancy: vmRedundancy
    availabilityZones: vmAvailabilityZones
    existingDomainAdminName: existingDomainAdminName
    existingDomainAdminPassword: existingDomainAdminPassword
    networkAvdResourceGroupName: networkAvdResourceGroupName
    existingVnetName: existingAvdVnetName
    existingSnetName: existingSubnetName
    vmGalleryImage: vmGalleryImage
    diagnosticsStorageAccountName: diagnosticsStorageAccountName
    monitoringResourceGroupName: monitoringResourceGroupName
    logWorkspaceName: logWorkspaceName
  }
}



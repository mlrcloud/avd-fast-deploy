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
var sharedResourceGroupName = resourceGroupNames.shared
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

// Azure Virtual Desktop Workspaces Configuration

param deploymentFromScratch bool
var newScenario = deploymentFromScratch
var placeholderWorkspaceName = avdConfiguration.workspaces.placeholderWorkspace.Name
var deployPlaceholderWorkspace = avdConfiguration.workspaces.placeholderWorkspace.deployWorkspace
var deployPlaceholderWorkspacePrivateLink = avdConfiguration.workspaces.placeholderWorkspace.privateLink.deployPrivateLink
var placeholderWorkspacePrivateEndpointName = avdConfiguration.workspaces.placeholderWorkspace.privateLink.privateEndpointName
var placeholderWorkspacePrivateDnsZoneName = avdConfiguration.workspaces.placeholderWorkspace.privateLink.privateDNSZone
var placeholderWorkspaceGroupId = avdConfiguration.workspaces.placeholderWorkspace.privateLink.groupId
var placeholderWorkspaceSubnetName = avdConfiguration.workspaces.placeholderWorkspace.privateLink.subnetName
var deployPlaceholderWorkspaceDiagnostics = avdConfiguration.workspaces.placeholderWorkspace.deployDiagnostics
var existingPlaceholderWorkspaceApplicationGroupIds = avdConfiguration.workspaces.placeholderWorkspace.existingApplicationGroupIds

var feedWorkspaceName = avdConfiguration.workspaces.feedWorkspace.Name
var deployFeedWorkspace = avdConfiguration.workspaces.feedWorkspace.deployWorkspace
var deployFeedWorkspacePrivateLink = avdConfiguration.workspaces.feedWorkspace.privateLink.deployPrivateLink
var feedWorkspacePrivateEndpointName = avdConfiguration.workspaces.feedWorkspace.privateLink.privateEndpointName
var feedWorkspacePrivateDnsZoneName = avdConfiguration.workspaces.feedWorkspace.privateLink.privateDNSZone
var feedWorkspaceGroupId = avdConfiguration.workspaces.feedWorkspace.privateLink.groupId
var feedWorkspaceSubnetName = avdConfiguration.workspaces.feedWorkspace.privateLink.subnetName
var deployFeedWorkspaceDiagnostics = avdConfiguration.workspaces.feedWorkspace.deployDiagnostics
var existingFeedWorkspaceApplicationGroupIds = avdConfiguration.workspaces.feedWorkspace.existingApplicationGroupIds


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

// Azure Virtual Desktop Pool Private Link Configuration

var deployHostPoolPrivateLink = avdConfiguration.hostPool.privateLink.deployPrivateLink
var hostPoolPrivateEndpointName = avdConfiguration.hostPool.privateLink.privateEndpointName
var hostPoolPrivateDnsZoneName = avdConfiguration.hostPool.privateLink.privateDNSZone
var hostPoolGroupId = avdConfiguration.hostPool.privateLink.groupId
var hostPoolSubnetName = avdConfiguration.hostPool.privateLink.subnetName


// Azure Virtual Desktop Scale Plan

var scalingPlanName = avdConfiguration.hostPool.scalePlan.name
var timeZone = avdConfiguration.hostPool.scalePlan.timeZone
var schedules = avdConfiguration.hostPool.scalePlan.schedules
var scalingPlanEnabled = avdConfiguration.hostPool.scalePlan.enabled
var exclusionTag = avdConfiguration.hostPool.scalePlan.exclusionTag


// Azure Virtual Desktop Monitoring Configuration

var deployHostPoolDiagnostics = avdConfiguration.monitoring.deployHostPoolDiagnostics
var deployDesktopApplicationGroupDiagnostics = avdConfiguration.monitoring.deployDesktopDiagnostics
var deployRemoteAppApplicationGroupDiagnostics = avdConfiguration.monitoring.deployRemoteAppDiagnostics

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
    sharedResourceGroupName: sharedResourceGroupName
    networkAvdResourceGroupName: networkAvdResourceGroupName
    placeholderWorkspaceName: placeholderWorkspaceName
    deployPlaceholderWorkspace: deployPlaceholderWorkspace
    deployPlaceholderWorkspacePrivateLink: deployPlaceholderWorkspacePrivateLink
    placeholderWorkspacePrivateEndpointName: placeholderWorkspacePrivateEndpointName
    placeholderWorkspacePrivateDnsZoneName: placeholderWorkspacePrivateDnsZoneName
    placeholderWorkspaceGroupId: placeholderWorkspaceGroupId
    placeholderWorkspaceVnetName: existingAvdVnetName
    placeholderWorkspaceSubnetName: placeholderWorkspaceSubnetName
    deployPlaceholderWorkspaceDiagnostics: deployPlaceholderWorkspaceDiagnostics
    existingPlaceholderWorkspaceApplicationGroupIds: existingPlaceholderWorkspaceApplicationGroupIds
    feedWorkspaceName: feedWorkspaceName
    deployFeedWorkspace: deployFeedWorkspace
    deployFeedWorkspacePrivateLink: deployFeedWorkspacePrivateLink
    feedWorkspacePrivateEndpointName: feedWorkspacePrivateEndpointName
    feedWorkspacePrivateDnsZoneName: feedWorkspacePrivateDnsZoneName
    feedWorkspaceGroupId: feedWorkspaceGroupId
    feedWorkspaceVnetName: existingAvdVnetName
    feedWorkspaceSubnetName: feedWorkspaceSubnetName
    deployFeedWorkspaceDiagnostics: deployFeedWorkspaceDiagnostics
    existingFeedWorkspaceApplicationGroupIds: existingFeedWorkspaceApplicationGroupIds
    hostPoolName: hostPoolName
    hostPoolFriendlyName: hostPoolFriendlyName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    hostPoolType: hostPoolType
    deployHostPoolDiagnostics: deployHostPoolDiagnostics
    maxSessionLimit: maxSessionLimit
    tokenExpirationTime: tokenExpirationTime
    scalingPlanName: scalingPlanName
    timeZone: timeZone
    schedules: schedules
    scalingPlanEnabled: scalingPlanEnabled
    exclusionTag: exclusionTag
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    desktopApplicationGroupName: desktopApplicationGroupName
    deployDesktopApplicationGroupDiagnostics: deployDesktopApplicationGroupDiagnostics
    remoteAppApplicationGroupName: remoteAppApplicationGroupName
    deployRemoteAppApplicationGroupDiagnostics: deployRemoteAppApplicationGroupDiagnostics
    appsListInfo: appsListInfo
    deployHostPoolPrivateLink: deployHostPoolPrivateLink
    hostPoolPrivateEndpointName: hostPoolPrivateEndpointName
    hostPoolPrivateDnsZoneName: hostPoolPrivateDnsZoneName
    hostPoolGroupId: hostPoolGroupId
    hostPoolVnetName: existingAvdVnetName
    hostPoolSubnetName: hostPoolSubnetName
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



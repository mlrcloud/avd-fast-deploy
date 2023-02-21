

// TODO: verify the required parameters

// Global Parameters

param location string
param tags object

// resourceGroupNames
param monitoringResourceGroupName string

// avdResources Parameters
param newOrExistingWorkspaceName string
param workspacePrivateEndpointName string
param groupIdWorkspace string
param deployWorkspaceDiagnostic bool = true
param tokenExpirationTime string
param hostPoolType string 
param hostPoolName string 
param hostPoolFriendlyName string
param deployHostPoolDiagnostic bool = true
param personalDesktopAssignmentType string 
param maxSessionLimit int = 12

//param loadBalancerType string = 'BreadthFirst'


param customRdpProperty string = 'audiocapturemode:i:0;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectprinters:i:0;redirectsmartcards:i:0;screen mode id:i:2;'

param scalingPlanName string
param timeZone string
param schedules array
param scalingPlanEnabled bool
param exclusionTag string


param existingApplicationGroupIds array = []
param deployDesktopApplicationGroupDiagnostic bool = true
param deployRemoteAppApplicationGroupDiagnostic bool = true
param desktopApplicationGroupName string
param remoteAppApplicationGroupName string
param appsListInfo array

// privatelinkResources
param avdPrivateLinkEnabled bool
param placeholderWorkspaceName string
param placeholderWorkspacePrivateEndpointName string
param deployPlaceholderWorkspaceDiagnostic bool
param groupIdPlaceholderWorkspace string

// monitoringResources
param logWorkspaceName string


// Variables
var desktopApplicationGroupFriendlyName = '${hostPoolName}-dag'
var remoteAppApplicationGroupFriendlyName = '${hostPoolName}-rag'
var desktopApplicationGroupId = array(resourceId('Microsoft.DesktopVirtualization/applicationgroups/', desktopApplicationGroupName))
var remoteAppApplicationGroupId = hostPoolType != 'Pooled' ? [] : array(resourceId('Microsoft.DesktopVirtualization/applicationgroups/', remoteAppApplicationGroupName))
var applicationGroupIds = union(existingApplicationGroupIds,desktopApplicationGroupId,remoteAppApplicationGroupId)
var descriptionPersonalAppGroup = 'Desktop Application Group created through the Hostpool Wizard'
var descriptionPooledAppGroup = 'Remote App Application Group created through the Hostpool Wizard'

// Resources

module hostPoolResources '../../modules/Microsoft.DesktopVirtualization/hostPool.bicep' = {
  name: 'hostPoolRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  params: {
    location: location
    tags: tags
    name: hostPoolName
    friendlyName: hostPoolFriendlyName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    hostPoolType: hostPoolType
    deployDiagnostic: deployHostPoolDiagnostic
    maxSessionLimit: maxSessionLimit
    validationEnvironment: true
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    tokenExpirationTime: tokenExpirationTime
  }
}

module scalingPlanResources '../../modules/Microsoft.DesktopVirtualization/scalingPlan.bicep' = if (hostPoolType == 'Pooled') {
  name: 'scalingPlanRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
  ]
  params: {
    location:location
    tags: tags
    hostPoolName: hostPoolName
    scalingPlanName: scalingPlanName
    timeZone: timeZone
    schedules: schedules
    scalingPlanEnabled: scalingPlanEnabled
    exclusionTag: exclusionTag
  }
}

module desktopApplicationGroupResources '../../modules/Microsoft.DesktopVirtualization/applicationGroup.bicep' = {
  name: 'desktopAppGroupRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
  ]
  params: {
    location:location
    tags: tags
    name: desktopApplicationGroupName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName    
    deployDiagnostic: deployDesktopApplicationGroupDiagnostic
    hostPoolName: hostPoolName
    applicationGroupFriendlyName: desktopApplicationGroupFriendlyName
    description: descriptionPersonalAppGroup
    applicationGroupType: 'Desktop' 
  }
}

module remoteAppApplicationGroupResources '../../modules/Microsoft.DesktopVirtualization/applicationGroup.bicep' = if (hostPoolType == 'Pooled') {
  name: 'pooledAppGroupRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
    desktopApplicationGroupResources
  ]
  params: {
    location:location
    tags: tags
    name: remoteAppApplicationGroupName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName    
    deployDiagnostic: deployRemoteAppApplicationGroupDiagnostic
    hostPoolName: hostPoolName
    applicationGroupFriendlyName: remoteAppApplicationGroupFriendlyName
    description: descriptionPooledAppGroup
    applicationGroupType: 'RemoteApp' 
  }
}

module remoteAppApplicationsResources '../../modules/Microsoft.DesktopVirtualization/application.bicep' = [ for (app, i) in appsListInfo : if (hostPoolType == 'Pooled') {
  name: 'applicationsRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy${i}'
  dependsOn: [
    hostPoolResources
    desktopApplicationGroupResources
    remoteAppApplicationGroupResources
  ]
  params: {
    name: app.remoteAppApplicationName
    applicationGroupName: remoteAppApplicationGroupName
    applicationType: app.applicationType
    description: app.description
    filePath: app.filePath
    friendlyName: app.friendlyName
    iconIndex: app.iconIndex
    iconPath: app.iconPath
    showInPortal: app.showInPortal
  }
}]

module workspaceResources '../../modules/Microsoft.DesktopVirtualization/workspace.bicep' = {
  name: 'workspaceRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
    desktopApplicationGroupResources
    remoteAppApplicationGroupResources
  ]
  params: {
    location: location
    tags: tags
    name: newOrExistingWorkspaceName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    deployDiagnostic: deployWorkspaceDiagnostic
    applicationGroupIds: applicationGroupIds
  }
}

module placeholderWorkspaceResources '../../modules/Microsoft.DesktopVirtualization/workspace.bicep' = if (avdPrivateLinkEnabled) {
  name: 'placeholderWorkspaceRss_Deploy'
  params: {
    location: location
    tags: tags
    name: placeholderWorkspaceName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    deployDiagnostic: deployPlaceholderWorkspaceDiagnostic
    applicationGroupIds: [] //placeholder workspace does not required application groups. It must be an unused placeholder workspace to terminate the global endpoint.
  }
}


module workspacePrivateEndpointResources '../../modules/Microsoft.Network/workspacePrivateEndpoint.bicep' = [for i in range(0, length(snetsInfo)): if (snetsInfo[i].name == 'snet-plinks') {
  name: '${i}WorkspacePrivateEndpointResources_Deploy'
  dependsOn: [
    placeholderWorkspaceResources
    workspaceResources
  ]
  params: {
    location: location
    tags: tags
    name: blobStorageAccountPrivateEndpointName
    vnetName: vnetName
    snetName: snetName
    workspaceName: storageAccountName
    privateDnsZoneName: blobPrivateDnsZoneName
    groupIds: i
    sharedResourceGroupName: sharedResourceGroupName
  }
}]


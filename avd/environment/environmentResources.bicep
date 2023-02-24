

// TODO: verify the required parameters

// Global Parameters

param location string
param tags object

// resourceGroupNames
param monitoringResourceGroupName string
param networkAvdResourceGroupName string
param sharedResourceGroupName string

// hostPoolResources Parameters
param tokenExpirationTime string
param hostPoolType string 
param hostPoolName string 
param hostPoolFriendlyName string
param deployHostPoolDiagnostics bool
param personalDesktopAssignmentType string 
param maxSessionLimit int



param customRdpProperty string = 'audiocapturemode:i:0;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectprinters:i:0;redirectsmartcards:i:0;screen mode id:i:2;'

param scalingPlanName string
param timeZone string
param schedules array
param scalingPlanEnabled bool
param exclusionTag string

// hostPoolResources private link parameters

param deployHostPoolPrivateLink bool
param hostPoolPrivateEndpointName string
param hostPoolPrivateDnsZoneName string
param hostPoolGroupId string
param hostPoolVnetName string
param hostPoolSubnetName string
param publicNetworkAccessHostPool string

// workspaceResources

param placeholderWorkspaceName string 
param deployPlaceholderWorkspace bool 
param deployPlaceholderWorkspacePrivateLink bool 
param placeholderWorkspacePrivateEndpointName string 
param placeholderWorkspacePrivateDnsZoneName string
param placeholderWorkspaceGroupId string 
param placeholderWorkspaceVnetName string 
param placeholderWorkspaceSubnetName string 
param deployPlaceholderWorkspaceDiagnostics bool 
param existingPlaceholderWorkspaceApplicationGroupIds array
param publicNetworkAccessPlaceholderWorkspace string 
param feedWorkspaceName string 
param deployFeedWorkspace bool 
param deployFeedWorkspacePrivateLink bool 
param feedWorkspacePrivateEndpointName string 
param feedWorkspacePrivateDnsZoneName string
param feedWorkspaceGroupId string 
param feedWorkspaceVnetName string 
param feedWorkspaceSubnetName string 
param deployFeedWorkspaceDiagnostics bool 
param existingFeedWorkspaceApplicationGroupIds array 
param publicNetworkAccessFeedWorkspace string

param deployDesktopApplicationGroupDiagnostics bool
param deployRemoteAppApplicationGroupDiagnostics bool
param desktopApplicationGroupName string
param remoteAppApplicationGroupName string
param appsListInfo array


// monitoringResources
param logWorkspaceName string


// Variables
var desktopApplicationGroupFriendlyName = '${hostPoolName}-dag'
var remoteAppApplicationGroupFriendlyName = '${hostPoolName}-rag'
var desktopApplicationGroupId = array(resourceId('Microsoft.DesktopVirtualization/applicationgroups/', desktopApplicationGroupName))
var remoteAppApplicationGroupId = hostPoolType != 'Pooled' ? [] : array(resourceId('Microsoft.DesktopVirtualization/applicationgroups/', remoteAppApplicationGroupName))
var unionFeedWorkspaceApplicationGroupIds = union(existingFeedWorkspaceApplicationGroupIds,desktopApplicationGroupId,remoteAppApplicationGroupId)
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
    deployDiagnostics: deployHostPoolDiagnostics
    maxSessionLimit: maxSessionLimit
    validationEnvironment: true
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    tokenExpirationTime: tokenExpirationTime
    publicNetworkAccess: publicNetworkAccessHostPool
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
    deployDiagnostics: deployDesktopApplicationGroupDiagnostics
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
    deployDiagnostics: deployRemoteAppApplicationGroupDiagnostics
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

module placeholderWorkspaceResources '../../modules/Microsoft.DesktopVirtualization/workspace.bicep' = if (deployPlaceholderWorkspace) {
  scope: resourceGroup(networkAvdResourceGroupName)
  name: 'placeholderWorkspaceRss_Deploy'
  params: {
    location: location
    tags: tags
    name: placeholderWorkspaceName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    deployDiagnostics: deployPlaceholderWorkspaceDiagnostics
    applicationGroupIds: existingPlaceholderWorkspaceApplicationGroupIds
    publicNetworkAccess: publicNetworkAccessPlaceholderWorkspace
  }
}

module feedWorkspaceResources '../../modules/Microsoft.DesktopVirtualization/workspace.bicep' = if (deployFeedWorkspace) {
  name: 'workspaceRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
    desktopApplicationGroupResources
    remoteAppApplicationGroupResources
  ]
  params: {
    location: location
    tags: tags
    name: feedWorkspaceName
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    deployDiagnostics: deployFeedWorkspaceDiagnostics
    applicationGroupIds: unionFeedWorkspaceApplicationGroupIds
    publicNetworkAccess: publicNetworkAccessFeedWorkspace
  }
}


module placeholderWorkspacePrivateEndpointResources '../../modules/Microsoft.Network/workspacePrivateEndpoint.bicep' = if (deployPlaceholderWorkspacePrivateLink) {
  name: 'placeholderWorkspacePrivateEndpointResources_Deploy'
  scope: resourceGroup(networkAvdResourceGroupName)
  dependsOn: [
    placeholderWorkspaceResources
  ]
  params: {
    location: location
    tags: tags
    name: placeholderWorkspacePrivateEndpointName
    vnetName: placeholderWorkspaceVnetName
    snetName: placeholderWorkspaceSubnetName
    workspaceName: placeholderWorkspaceName
    privateDnsZoneName: placeholderWorkspacePrivateDnsZoneName
    groupIds: placeholderWorkspaceGroupId
    centralDnsResourceGroupName: sharedResourceGroupName
    vnetResourceGroupName: networkAvdResourceGroupName
  }
}

module feedWorkspacePrivateEndpointResources '../../modules/Microsoft.Network/workspacePrivateEndpoint.bicep' = if (deployFeedWorkspacePrivateLink) {
  name: 'feedWorkspacePrivateEndpointResources_Deploy'
  dependsOn: [
    feedWorkspaceResources
  ]
  params: {
    location: location
    tags: tags
    name: feedWorkspacePrivateEndpointName
    vnetName: feedWorkspaceVnetName
    snetName: feedWorkspaceSubnetName
    workspaceName: feedWorkspaceName
    privateDnsZoneName: feedWorkspacePrivateDnsZoneName
    groupIds: feedWorkspaceGroupId
    centralDnsResourceGroupName: sharedResourceGroupName
    vnetResourceGroupName: networkAvdResourceGroupName
  }
}

module hostPoolPrivateEndpointResources '../../modules/Microsoft.Network/hostPoolPrivateEndpoint.bicep' = if (deployHostPoolPrivateLink) {
  name: 'hostPoolPrivateEndpointResources_Deploy'
  dependsOn: [
    hostPoolResources
  ]
  params: {
    location: location
    tags: tags
    name: hostPoolPrivateEndpointName
    vnetName: hostPoolVnetName
    snetName: hostPoolSubnetName
    hostPoolName: hostPoolName
    privateDnsZoneName: hostPoolPrivateDnsZoneName
    groupIds: hostPoolGroupId
    centralDnsResourceGroupName: sharedResourceGroupName
    vnetResourceGroupName: networkAvdResourceGroupName
  }
}

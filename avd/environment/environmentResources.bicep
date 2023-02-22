

// TODO: verify the required parameters

// Global Parameters

param location string
param tags object

// resourceGroupNames
param monitoringResourceGroupName string
param networkAvdResourceGroupName string

// avdResources Parameters
param avdWorkspaces object
param tokenExpirationTime string
param hostPoolType string 
param hostPoolName string 
param hostPoolFriendlyName string
param deployHostPoolDiagnostics bool = true
param personalDesktopAssignmentType string 
param maxSessionLimit int = 12

//param loadBalancerType string = 'BreadthFirst'


param customRdpProperty string = 'audiocapturemode:i:0;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectprinters:i:0;redirectsmartcards:i:0;screen mode id:i:2;'

param scalingPlanName string
param timeZone string
param schedules array
param scalingPlanEnabled bool
param exclusionTag string


param existingFeedWsApplicationGroupIds array = []
param deployDesktopApplicationGroupDiagnostics bool = true
param deployRemoteAppApplicationGroupDiagnostics bool = true
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
var feedWsApplicationGroupIds = union(existingFeedWsApplicationGroupIds,desktopApplicationGroupId,remoteAppApplicationGroupId)
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


module workspaceResources '../../modules/Microsoft.DesktopVirtualization/workspace.bicep' = [for ws in items(avdWorkspaces): if (ws.value.deployWorkspace) {
  scope: (ws.value.name == 'ws-placeholder') ? resourceGroup(networkAvdResourceGroupName) : resourceGroup()
  name: (ws.value.name == 'ws-placeholder') ? 'placeholderWorkspaceRss_Deploy' : 'workspaceRssFor${hostPoolType}_${uniqueString(hostPoolName)}_Deploy'
  dependsOn: [
    hostPoolResources
    desktopApplicationGroupResources
    remoteAppApplicationGroupResources
  ]
  params: {
    location: location
    tags: tags
    name: ws.value.name
    logWorkspaceName: logWorkspaceName
    monitoringResourceGroupName: monitoringResourceGroupName
    deployDiagnostics: ws.value.deployDiagnostics
    applicationGroupIds: (ws.value.name == 'ws-placeholder') ? ws.value.existingApplicationGroupIds : feedWsApplicationGroupIds
  }
}]

output avdresourcegroup string = resourceGroup().name
output avdnetworkresourcegroup string = networkAvdResourceGroupName

/*
module workspacePrivateEndpointResources '../../modules/Microsoft.Network/workspacePrivateEndpoint.bicep' = [for ws in items(avdWorkspaces): if (ws.value.deployWorkspace) {
  name: '${i}WorkspacePrivateEndpointResources_Deploy'
  dependsOn: [
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

*/

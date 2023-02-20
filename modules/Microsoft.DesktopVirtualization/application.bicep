

param name string
param applicationGroupName string 
param applicationType string
param description string
param filePath string
param friendlyName string
param iconIndex int
param iconPath string
param showInPortal bool

resource applicationGroups 'Microsoft.DesktopVirtualization/applicationgroups@2021-07-12' existing = {
  name: applicationGroupName
}

resource application 'Microsoft.DesktopVirtualization/applicationGroups/applications@2021-09-03-preview' = {
  name: name
  parent: applicationGroups
  properties: {
    applicationType: applicationType
    commandLineSetting: 'DoNotAllow'
    description: description
    filePath: filePath
    friendlyName: friendlyName
    iconIndex: iconIndex
    iconPath: iconPath
    //msixPackageApplicationId: 'string'
    //msixPackageFamilyName: 'string'
    showInPortal: showInPortal
  }
}


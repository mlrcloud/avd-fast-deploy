
param location string
param tags object 
param hostPoolName string
param scalingPlanName string
param timeZone string
param schedules array
param scalingPlanEnabled bool
param exclusionTag string


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existing = {
  name: hostPoolName
}

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2020-11-10-preview' = {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    friendlyName: 'Scaling Plan'
    description: format('Scaling plan for {0} hostpool', hostPoolName)
    hostPoolType: 'Pooled'
    timeZone: timeZone
    exclusionTag: exclusionTag
    schedules: schedules
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPool.id
        scalingPlanEnabled: scalingPlanEnabled
      }
    ]
  }
}


param location string = resourceGroup().location
param tags object
param name string 
param vmName string
param artifactsLocation string
param hostPoolName string



resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' existing = {
  name: vmName
}

resource hostpools 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existing = {
  name: hostPoolName
}

resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: name
  parent: vm
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: uri(artifactsLocation, 'Configuration.zip')
      //modulesUrl: uri(artifactsLocation, 'Configuration_8-16-2021.zip')
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        HostPoolName: hostPoolName
        registrationInfoToken: reference(resourceId('Microsoft.DesktopVirtualization/hostpools', hostPoolName), '2019-12-10-preview', 'Full').properties.registrationInfo.token
        //registrationInfoToken: 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkVCMTMxOTA0Q0Q5ODA5ODU3Nzc1NDM5QkYwRUYyNzhGNkIxNjdBODgiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjAwYzI3OTlhLTNiYWEtNDk5Zi04MGQ4LTI2MDFlZmZkZWI1MCIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy1ldS1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLWV1LXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiODY5MmJjZDAtYTc2ZC00M2YwLWJkODEtNGFiYTVlNTJiNTdiIiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJFVSIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL3JkYnJva2VyLnd2ZC5taWNyb3NvZnQuY29tLyIsIkJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL3JkYnJva2VyLWctZXUtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwiRGlhZ25vc3RpY3NSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly9yZGRpYWdub3N0aWNzLWctZXUtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwibmJmIjoxNjM1ODg5OTE2LCJleHAiOjE2MzgyNjI1NTAsImlzcyI6IlJESW5mcmFUb2tlbk1hbmFnZXIiLCJhdWQiOiJSRG1pIn0.QWWMD5wUw_TRUf1aG-5z7wAGwyj9yvDChCVygYEGBv1Eb_CXRNthv15Ke2PaB6hKLpu23T-SDe7PcFrKf8EqtK8ALurFIofZCVeBJDJc0UB5x-k5N_wYgwQOcHl9qYftl0Dun3lgUVZS8esPk61pmdkneaeKEfDCG3W8skoqXqoL75LoZnVOTpt39hDgLDkER8JZsZP4Yeq9R6UlKFwLAJtcL2je87kGngKT627esW4Q-6o_SK-0jeqq1nZiiM-4Nj7iK7Zf48jioVVh0I1Aym-JmZ7nnZktD8Ta5i54n2qwb9NEdfKMBVgxSPaV3lR461xnkiZZvZEortRv9ybQOQ'
        //aadJoin: false
        //sessionHostConfigurationLastUpdateTime: ''
      }
    }
  }
}


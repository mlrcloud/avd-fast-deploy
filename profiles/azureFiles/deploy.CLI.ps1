param (
  [string]
  $location = "westeurope",
  [string] 
  $templateFile = ".\main.bicep",
  [string]
  $parameterFile = "parameters.json",
  [string] 
  $deploymentPrefix='AVD-AzFilesProfiles-Deployment'
  )

$deploymentName = $deploymentPrefix

az deployment sub create -l westeurope -n $deploymentName --template-file $templateFile --parameters $parameterFile 

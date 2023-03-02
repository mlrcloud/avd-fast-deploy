param (
  [string]
  $location = "northeurope",
  [string] 
  $templateFile = ".\main.bicep",
  [string]
  $parameterFile = "parameters.json",
  [string] 
  $deploymentPrefix='AVD-ASR-Deployment'
  )

$deploymentName = $deploymentPrefix

az deployment sub create -l northeurope -n $deploymentName --template-file $templateFile --parameters $parameterFile 

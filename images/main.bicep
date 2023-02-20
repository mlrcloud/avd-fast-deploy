targetScope = 'subscription'

// Global Parameters

@description('Azure region where resource would be deployed')
param location string
@description('Tags associated with all resources')
param tags object

// Resource Group Names

@description('Resource Groups names')
param resourceGroupNames object

var avdImagesResourceGroupName = resourceGroupNames.images


/* 
  AVD Images Resource Group deployment 
*/
resource avdImagesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: avdImagesResourceGroupName
  location: location
  tags: tags
}

/* 
  Identity resources deployment 
*/

var imageBuilderIdentityName = 'imageBuilderIdentityAVD'
@description('Role definitions for Image Builder and Deployment Script entities')
param roleDefinitions object 
var deploymentScriptIdentityName = 'deploymentScriptAvdImage'
var imageBuilderRoleInfo = roleDefinitions.imageBuilderRole
var deploymentScriptRoleInfo = roleDefinitions.avdDeploymentScriptRole

module imageBuilderIdentityResources '../modules/Microsoft.Authorization/userAssignedIdentity.bicep' = {
  scope: avdImagesResourceGroup
  name: 'imageBuilderIdentityRss_Deploy'
  params: {
    name: imageBuilderIdentityName
    location: location
    tags: tags
  }
}

module deploymentScriptIdentityResources '../modules/Microsoft.Authorization/userAssignedIdentity.bicep' = {
  scope: avdImagesResourceGroup
  name: 'deploymentScriptIdentityRss_Deploy'
  params: {
    name: deploymentScriptIdentityName
    location: location
    tags: tags
  }
}

module imageBuilderRoleResources '../modules/Microsoft.Authorization/roleBeta.bicep' = {
  scope: avdImagesResourceGroup
  name: 'imageBuilderRoleRss_Deploy'
  params: {
    name: imageBuilderRoleInfo.name
    description: imageBuilderRoleInfo.description
    actions: imageBuilderRoleInfo.actions
    principalId: imageBuilderIdentityResources.outputs.principalId
  }
}

module deploymentScriptRoleResources '../modules/Microsoft.Authorization/roleBeta.bicep' = {
  scope: avdImagesResourceGroup
  name: 'deploymentScriptRoleRss_Deploy'
  params: {
    name: deploymentScriptRoleInfo.name
    description: deploymentScriptRoleInfo.description
    actions: deploymentScriptRoleInfo.actions
    principalId: deploymentScriptIdentityResources.outputs.principalId
  }
}

/* 
  Gallery resources deployment 
*/

param galleryProperties object
var galleryName = galleryProperties.name
//var gallerySoftDelete = galleryProperties.softDelete // It is in preview.

module galleryResources '../modules/Microsoft.Compute/gallery.bicep' = {
  scope: avdImagesResourceGroup
  name: 'galleryRss_Deploy'
  params: {
    name: galleryName
    location: location
    tags: tags
    //softDelete: gallerySoftDelete
  }
}

/* 
  Image resources deployment 
*/

param imagesInfo object

module imageResources '../modules/Microsoft.Compute/image.bicep' = [ for image in items(imagesInfo): {
  scope: avdImagesResourceGroup
  name: 'imageRssFor${image.value.imageDefinitionProperties.name}_${uniqueString(image.value.imageDefinitionProperties.name)}_Deploy'
  params: {
    name: image.value.imageDefinitionProperties.name
    location: location
    tags: tags
    galleryName: galleryName
    imageDefinitionProperties: image.value.imageDefinitionProperties
  }
  dependsOn: [
    galleryResources
  ]
}]

/*
Image Template resources deployment
*/

param updateImageTemplate bool

module imageTemplateResources '../modules/Microsoft.VirtualMachineImages/imageTemplate.bicep' = [ for image in items(imagesInfo): if (updateImageTemplate) {
  scope: avdImagesResourceGroup
  name: 'imageTemplateRssFor${image.value.imageTemplateProperties.name}_${uniqueString(image.value.imageTemplateProperties.name)}_Deploy'
  params: {
    name: image.value.imageTemplateProperties.name
    location: location
    tags: tags
    imageBuilderIdentityName: imageBuilderIdentityName
    galleryName: galleryName
    imageDefinitionName: image.value.imageDefinitionProperties.name
    source: image.value.imageTemplateProperties.source 
    customize: image.value.imageTemplateProperties.customize
    imageVersion: image.value.imageTemplateProperties.version
    runOutputName: image.value.imageTemplateProperties.runOutputName
    artifactsTags: image.value.imageTemplateProperties.artifactTags
    replicationRegions: image.value.imageTemplateProperties.replicationRegions    
  }
  dependsOn: [
    imageResources
  ]
}]


/*
Image Template creation deployment
*/

param forceUpdateTag string = newGuid()

module imageTemplateBuildResources '../modules/Microsoft.Resources/deploymentScript.bicep' = [ for image in items(imagesInfo): {
  scope: avdImagesResourceGroup
  name: 'imageTemplateBuildRssFor${image.value.imageTemplateProperties.name}_${uniqueString(image.value.imageTemplateProperties.name)}_Deploy'
  params: {
    name: '${image.value.imageTemplateProperties.name}-Build'
    location: location
    tags: tags
    deploymentScriptIdentityName: deploymentScriptIdentityName
    forceUpdateTag: forceUpdateTag
    imageTemplateName: image.value.imageTemplateProperties.name
  }
  dependsOn: [
    imageBuilderIdentityResources
    imageTemplateResources
  ]
}]

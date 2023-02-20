
param location string = resourceGroup().location
param tags object
param name string 
//param softDelete bool

resource imageGallery 'Microsoft.Compute/galleries@2021-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    description: 'Gallery for images'
    //softDeletePolicy: {
    //  isSoftDeleteEnabled: softDelete
    //} #REVIEW: It is preview. Subscription must be registered with the feature Microsoft.Compute/SIGSoftDelete
  }
}

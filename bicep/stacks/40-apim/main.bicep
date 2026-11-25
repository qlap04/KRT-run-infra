// APIM stack, deployed by its own pipeline (provision-apim.yml). Run last.
// Subscription scope: creates rg-<prefix>-<environment>-apim and the APIM in it.
// Independent of the other stacks: the CORS origins come in as a parameter.
targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string

@description('Environment name (dev) -> resource names, tag')
param environment string

param location string

param publisherEmail string

param publisherName string

@description('Browser origins allowed by the CORS policy (the frontend URLs)')
param allowedOrigins array

@secure()
@description('Shared secret APIM sends to the Web App (X-Gateway-Secret)')
param gatewaySecret string

var base = '${prefix}-${environment}'
var tags = {
  project: 'krtrun'
  env: environment
}

resource rgApim 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${base}-apim'
  location: location
  tags: tags
}

module apim '../../modules/compute/apim.bicep' = {
  name: 'apim'
  scope: rgApim
  params: {
    name: '${base}-apim'
    location: location
    tags: tags
    publisherEmail: publisherEmail
    publisherName: publisherName
    allowedOrigins: allowedOrigins
    gatewaySecret: gatewaySecret
  }
}

output gatewayUrl string = apim.outputs.gatewayUrl

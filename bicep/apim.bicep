// APIM stack, deployed by its own pipeline (provision-apim.yml).
// Subscription scope: creates rg-<prefix>-<resourceEnv>-apim and the APIM in it.
// Run after the app stack: CORS reads the frontend hostname from the existing SWA.
targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string = 'krtrun'

@description('Logical environment -> tag')
param environment string = 'dev'

@description('Resource name set used in resource names (prefix-resourceEnv-*)')
param resourceEnv string = 'dev'

param location string = 'australiaeast'

param publisherEmail string

param publisherName string = 'KRT-run'

var base = '${prefix}-${resourceEnv}'
var tags = {
  project: 'krtrun'
  env: environment
  resourceEnv: resourceEnv
}

resource rgApim 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${base}-apim'
  location: location
  tags: tags
}

// Created by the app stack (main.bicep) in the app RG.
resource swa 'Microsoft.Web/staticSites@2023-12-01' existing = {
  name: '${base}-swa'
  scope: resourceGroup('rg-${base}')
}

module apim 'modules/compute/apim.bicep' = {
  name: 'apim'
  scope: rgApim
  params: {
    name: '${base}-apim'
    location: location
    tags: tags
    publisherEmail: publisherEmail
    publisherName: publisherName
    allowedOrigins: [ 'https://${swa.properties.defaultHostname}' ]
  }
}

output apimResourceGroup string = rgApim.name
output apimName string = apim.outputs.name
output gatewayUrl string = apim.outputs.gatewayUrl

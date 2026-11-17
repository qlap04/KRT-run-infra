// Entry point. Subscription scope so Bicep creates the resource groups itself:
// - rg-<prefix>-<resourceEnv>       app stack (network, storage, web, function)
// - rg-<prefix>-<resourceEnv>-apim  APIM, kept apart (own lifecycle and access)
targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string = 'krtrun'

@description('Logical environment -> APP_ENV and tag')
param environment string = 'dev'

@description('Resource name set used in resource names (prefix-resourceEnv-*)')
param resourceEnv string = 'dev'

param location string = 'australiaeast'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('Create an APIM Consumption instance (in its own resource group)')
param deployApim bool = true

param publisherEmail string = 'admin@example.com'

param publisherName string = 'KRT-run'

@description('VNet address space')
param vnetAddressPrefix string

@description('Subnet for App Service VNet integration (web + function)')
param appSubnetPrefix string

@description('Subnet for the storage private endpoints')
param peSubnetPrefix string

var base = '${prefix}-${resourceEnv}'
var tags = {
  project: 'krtrun'
  env: environment
  resourceEnv: resourceEnv
}

resource rgApp 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${base}'
  location: location
  tags: tags
}

resource rgApim 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deployApim) {
  name: 'rg-${base}-apim'
  location: location
  tags: tags
}

module app 'app.bicep' = {
  name: 'app'
  scope: rgApp
  params: {
    prefix: prefix
    environment: environment
    resourceEnv: resourceEnv
    location: location
    appServicePlanSku: appServicePlanSku
    vnetAddressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module apim 'modules/compute/apim.bicep' = if (deployApim) {
  name: 'apim'
  scope: rgApim
  params: {
    name: '${base}-apim'
    location: location
    tags: tags
    publisherEmail: publisherEmail
    publisherName: publisherName
    allowedOrigins: [ 'https://${app.outputs.swaHostname}' ]
  }
}

output appResourceGroup string = rgApp.name
output apimResourceGroup string = deployApim ? rgApim.name : ''
output webAppName string = app.outputs.webAppName
output webAppUrl string = app.outputs.webAppUrl
output functionAppName string = app.outputs.functionAppName
output storageAccountName string = app.outputs.storageAccountName
output swaName string = app.outputs.swaName
output swaUrl string = 'https://${app.outputs.swaHostname}'
output apimName string = deployApim ? '${base}-apim' : ''

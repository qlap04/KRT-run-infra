// Entry point. Subscription scope so Bicep creates the resource groups itself:
// - rg-<prefix>-<resourceEnv>       network.bicep, then app.bicep
// APIM is a separate stack: bicep/apim.bicep with its own pipeline.
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

module network 'network.bicep' = {
  name: 'network'
  scope: rgApp
  params: {
    base: base
    location: location
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module app 'app.bicep' = {
  name: 'app'
  scope: rgApp
  params: {
    base: base
    environment: environment
    location: location
    tags: tags
    appServicePlanSku: appServicePlanSku
    appIntegrationSubnetId: network.outputs.appIntegrationSubnetId
    peSubnetId: network.outputs.peSubnetId
    dnsZoneIds: network.outputs.dnsZoneIds
  }
}

output appResourceGroup string = rgApp.name
output webAppName string = app.outputs.webAppName
output webAppUrl string = app.outputs.webAppUrl
output functionAppName string = app.outputs.functionAppName
output storageAccountName string = app.outputs.storageAccountName
output swaName string = app.outputs.swaName
output swaUrl string = 'https://${app.outputs.swaHostname}'

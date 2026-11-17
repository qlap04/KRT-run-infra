// App stack: everything that lives in the app resource group.
// Called by main.bicep with scope = the app RG. APIM lives in its own RG.
targetScope = 'resourceGroup'

@description('Resource name prefix')
@minLength(3)
param prefix string = 'krtrun'

@description('Logical environment -> APP_ENV and tag')
param environment string = 'dev'

@description('Resource name set used in resource names (prefix-resourceEnv-*)')
param resourceEnv string = 'dev'

param location string = 'australiaeast'

@description('Static Web Apps region (not offered in australiaeast; eastasia is the closest)')
param swaLocation string = 'eastasia'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('VNet address space ')
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
var storageName = take(toLower(replace('st${prefix}${resourceEnv}${uniqueString(resourceGroup().id)}', '-', '')), 24)
var webAppName = '${base}-web'
var functionAppName = '${base}-func'

module network 'modules/network/vnet.bicep' = {
  name: 'network'
  params: {
    name: '${base}-vnet'
    location: location
    tags: tags
    addressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module storage 'modules/storage/storage-account.bicep' = {
  name: 'storage'
  params: {
    name: storageName
    location: location
    tags: tags
  }
}

module storagePe 'modules/network/storage-private-endpoints.bicep' = {
  name: 'storage-pe'
  params: {
    location: location
    tags: tags
    storageAccountName: storage.outputs.name
    vnetId: network.outputs.vnetId
    peSubnetId: network.outputs.peSubnetId
  }
}

// Queue, container and table names are app config (defaults in the app code).
var sharedSettings = {
  APP_ENV: environment
}

// dependsOn storagePe: the private endpoints and DNS must exist before the apps start talking to storage
module web 'modules/compute/web.bicep' = {
  name: 'web'
  dependsOn: [ storagePe ]
  params: {
    planName: '${base}-plan'
    webAppName: webAppName
    location: location
    tags: tags
    skuName: appServicePlanSku
    integrationSubnetId: network.outputs.appIntegrationSubnetId
    storageAccountName: storage.outputs.name
    appSettings: sharedSettings
  }
}

module func 'modules/compute/function.bicep' = {
  name: 'function'
  dependsOn: [ storagePe ]
  params: {
    functionAppName: functionAppName
    location: location
    tags: tags
    // The function shares the web plan and joins the same VNet subnet
    planId: web.outputs.planId
    integrationSubnetId: network.outputs.appIntegrationSubnetId
    storageAccountName: storage.outputs.name
    appSettings: sharedSettings
  }
}

module swa 'modules/compute/static-web-app.bicep' = {
  name: 'swa'
  params: {
    name: '${base}-swa'
    location: swaLocation
    tags: tags
  }
}

module rolesWeb 'modules/storage/roles.bicep' = {
  name: 'roles-web'
  params: { storageAccountName: storage.outputs.name, siteName: webAppName, principalId: web.outputs.principalId }
}

module rolesFunc 'modules/storage/roles.bicep' = {
  name: 'roles-func'
  params: { storageAccountName: storage.outputs.name, siteName: functionAppName, principalId: func.outputs.principalId }
}

output webAppName string = web.outputs.name
output webAppUrl string = 'https://${web.outputs.defaultHostName}'
output functionAppName string = func.outputs.name
output storageAccountName string = storage.outputs.name
output swaName string = swa.outputs.name
output swaHostname string = swa.outputs.defaultHostname

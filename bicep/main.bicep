targetScope = 'resourceGroup'

@description('Resource name prefix (change it if the web/function app name is taken globally)')
@minLength(3)
@maxLength(10)
param prefix string = 'krtrun'

@description('Logical environment -> APP_ENV and tag')
@allowed([ 'dev', 'sit', 'uat', 'preprod', 'prod' ])
param environment string = 'dev'

@description('Resource name set used in resource names (prefix-resourceEnv-*). Only "dev" is in use now; "prod" is reserved for a later environment')
@allowed([ 'dev', 'prod' ])
param resourceEnv string = 'dev'

param location string = 'australiaeast'

@description('App Service Plan SKU: F1 (free) | B1 | ... F1 has no VNet integration; B1+ enables VNet integration and a locked-down storage firewall')
param appServicePlanSku string = 'F1'

@description('Create an APIM Consumption instance')
param deployApim bool = true
param publisherEmail string = 'admin@example.com'
param publisherName string = 'KRT-run'

@description('Run the SCM build (npm install) when deploying the web app')
param webBuildOnDeploy bool = true

@secure()
@description('Session signing key (read from an environment variable in .bicepparam)')
param sessionSecret string = ''
@secure()
@description('Employee code that becomes admin on registration')
param adminCode string = ''
@secure()
@description('API key APIM uses to call /api/*')
param apiKey string = ''

param queueName string = 'upload-jobs'
param incomingContainer string = 'incoming'
param proofsContainer string = 'proofs'

var base = '${prefix}-${resourceEnv}'
var tags = {
  project: 'krtrun'
  env: environment
  resourceEnv: resourceEnv
}
var storageName = take(toLower(replace('st${prefix}${resourceEnv}${uniqueString(resourceGroup().id)}', '-', '')), 24)
var webAppName = '${base}-web'
var functionAppName = '${base}-func'
var vnetIntegrationSupported = !(appServicePlanSku == 'F1' || appServicePlanSku == 'D1')

module network 'modules/network.bicep' = {
  name: 'network'
  params: { name: '${base}-vnet', location: location, tags: tags }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageName
    location: location
    tags: tags
    queueName: queueName
    incomingContainer: incomingContainer
    proofsContainer: proofsContainer
    allowedSubnetId: vnetIntegrationSupported ? network.outputs.appIntegrationSubnetId : ''
  }
}

var sharedSettings = {
  APP_ENV: environment
  QUEUE_NAME: queueName
  BLOB_CONTAINER_INCOMING: incomingContainer
  BLOB_CONTAINER_PROOFS: proofsContainer
  TABLE_USERS: 'Users'
  TABLE_RUNS: 'Runs'
  TABLE_AUDIT: 'AuditLog'
}

module web 'modules/web.bicep' = {
  name: 'web'
  params: {
    planName: '${base}-plan'
    webAppName: webAppName
    location: location
    tags: tags
    skuName: appServicePlanSku
    integrationSubnetId: vnetIntegrationSupported ? network.outputs.appIntegrationSubnetId : ''
    storageAccountName: storage.outputs.name
    buildOnDeploy: webBuildOnDeploy
    appSettings: union(sharedSettings, {
      SESSION_SECRET: sessionSecret
      ADMIN_CODE: adminCode
      API_KEY: apiKey
    })
  }
}

module func 'modules/function.bicep' = {
  name: 'function'
  params: {
    planName: '${base}-funcplan'
    functionAppName: functionAppName
    location: location
    tags: tags
    // B1+: the function shares the web plan and joins the VNet; F1: it keeps its own Consumption (Y1) plan
    planId: vnetIntegrationSupported ? web.outputs.planId : ''
    integrationSubnetId: vnetIntegrationSupported ? network.outputs.appIntegrationSubnetId : ''
    storageAccountName: storage.outputs.name
    appSettings: sharedSettings
  }
}

module rolesWeb 'modules/roles.bicep' = {
  name: 'roles-web'
  params: { storageAccountName: storage.outputs.name, siteName: webAppName, principalId: web.outputs.principalId }
}

module rolesFunc 'modules/roles.bicep' = {
  name: 'roles-func'
  params: { storageAccountName: storage.outputs.name, siteName: functionAppName, principalId: func.outputs.principalId }
}

module apim 'modules/apim.bicep' = if (deployApim) {
  name: 'apim'
  params: {
    name: '${base}-apim'
    location: location
    tags: tags
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output webAppName string = web.outputs.name
output webAppUrl string = 'https://${web.outputs.defaultHostName}'
output functionAppName string = func.outputs.name
output storageAccountName string = storage.outputs.name
output apimName string = deployApim ? '${base}-apim' : ''

// App stack (called by main.bicep): web, function, the frontend SWA and their roles on the storage
// account of the data stack.
import { AppNetwork } from '../../modules/naming.bicep'

targetScope = 'resourceGroup'

@description('Name base <prefix>-<env>, built once in main.bicep')
param base string

@description('Logical environment -> APP_ENV')
param environment string

param location string

param tags object

@description('Static Web Apps region (not offered in australiaeast; eastasia is the closest)')
param swaLocation string = 'eastasia'

@description('App Service Plan SKU')
param appServicePlanSku string

@description('Subnet and private DNS zone ids created by the network stack')
param appNetwork AppNetwork

@description('Storage account created by the data stack')
param storageAccountName string

@description('SWA custom domain; empty skips the customDomains resource (see the module)')
param customDomain string = ''

var webAppName = '${base}-web'
var functionAppName = '${base}-func'

// Queue, container and table names are app config (defaults in the app code).
var sharedSettings = {
  APP_ENV: environment
}

module web '../../modules/compute/web.bicep' = {
  name: 'web'
  params: {
    planName: '${base}-plan'
    webAppName: webAppName
    location: location
    tags: tags
    skuName: appServicePlanSku
    integrationSubnetId: appNetwork.appIntegrationSubnetId
    storageAccountName: storageAccountName
    appSettings: sharedSettings
  }
}

module func '../../modules/compute/function.bicep' = {
  name: 'function'
  params: {
    functionAppName: functionAppName
    location: location
    tags: tags
    // The function shares the web plan and joins the same VNet subnet
    planId: web.outputs.planId
    integrationSubnetId: appNetwork.appIntegrationSubnetId
    storageAccountName: storageAccountName
    appSettings: sharedSettings
  }
}

module swa '../../modules/compute/static-web-app.bicep' = {
  name: 'swa'
  params: {
    name: '${base}-swa'
    location: swaLocation
    tags: tags
    customDomain: customDomain
  }
}

// Roles live here, not in the data stack: the principal ids exist only once web and function exist.
module rolesWeb '../../modules/storage/roles.bicep' = {
  name: 'roles-web'
  params: { storageAccountName: storageAccountName, siteName: webAppName, principalId: web.outputs.principalId }
}

module rolesFunc '../../modules/storage/roles.bicep' = {
  name: 'roles-func'
  params: { storageAccountName: storageAccountName, siteName: functionAppName, principalId: func.outputs.principalId }
}

output webAppUrl string = 'https://${web.outputs.defaultHostName}'
output swaHostname string = swa.outputs.defaultHostname

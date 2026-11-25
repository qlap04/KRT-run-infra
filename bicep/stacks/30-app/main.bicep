// App stack, deployed by provision.yml after the network stack (provision-network.yml).
// Subscription scope: creates rg-<prefix>-<environment> (shared with the network stack) and app.bicep in it.
// The network ids come from naming.bicep, so the VNet and DNS zones are not looked up.
// APIM is a separate stack: bicep/stacks/40-apim with its own pipeline.
import { resourceGroupName, appNetworkIds } from '../../modules/naming.bicep'

targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string

@description('Environment name (dev) -> resource names, APP_ENV and tag')
param environment string

param location string

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

var base = '${prefix}-${environment}'
var network = appNetworkIds(subscription().subscriptionId, base)
var tags = {
  project: 'krtrun'
  env: environment
}

// Same group and tags as in the network stack; the deployment is idempotent.
resource rgApp 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName(base)
  location: location
  tags: tags
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
    appIntegrationSubnetId: network.appIntegrationSubnetId
    peSubnetId: network.peSubnetId
    dnsZoneIds: network.dnsZoneIds
  }
}

output webAppUrl string = app.outputs.webAppUrl
output storageAccountName string = app.outputs.storageAccountName
output swaUrl string = 'https://${app.outputs.swaHostname}'

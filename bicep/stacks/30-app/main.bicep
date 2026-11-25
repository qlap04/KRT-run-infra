// App stack, deployed by provision.yml after the network and data stacks
// (provision-network.yml, provision-data.yml).
// Subscription scope: creates rg-<prefix>-<environment> (shared with the network stack) and app.bicep in it.
// The network ids and the storage account name come from naming.bicep, so nothing is looked up.
// APIM is a separate stack: bicep/stacks/40-apim with its own pipeline.
import { resourceGroupName, appNetworkIds, storageAccountName } from '../../modules/naming.bicep'

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

@description('SWA custom domain; empty on the first provision (the CNAME is added after the default hostname is known)')
param customDomain string = ''

var base = '${prefix}-${environment}'
var tags = {
  project: 'krtrun'
  env: environment
}

// Same group and tags as in the network and data stacks; the deployment is idempotent.
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
    appNetwork: appNetworkIds(subscription().subscriptionId, base)
    storageAccountName: storageAccountName(base, rgApp.id)
    customDomain: customDomain
  }
}

output webAppUrl string = app.outputs.webAppUrl
output swaUrl string = 'https://${app.outputs.swaHostname}'
output swaHostname string = app.outputs.swaHostname

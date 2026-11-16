param planName string
param webAppName string
param location string
param tags object
@description('F1 (free), B1... Default F1')
param skuName string = 'F1'
@description('Subnet id for VNet integration (empty = off; F1 does not support it). When set, all outbound traffic is routed through the VNet')
param integrationSubnetId string = ''
param storageAccountName string
param appSettings object = {}
param buildOnDeploy bool = true

var isFree = skuName == 'F1' || skuName == 'D1'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: { name: skuName }
  properties: { reserved: true }
}

var baseSettings = {
  STORAGE_ACCOUNT_NAME: storageAccountName
  SCM_DO_BUILD_DURING_DEPLOYMENT: string(buildOnDeploy)
}

resource web 'Microsoft.Web/sites@2025-03-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    virtualNetworkSubnetId: empty(integrationSubnetId) ? null : integrationSubnetId
    outboundVnetRouting: empty(integrationSubnetId) ? null : { allTraffic: true }
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      appCommandLine: 'node server.js'
      alwaysOn: !isFree
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [for s in items(union(baseSettings, appSettings)): {
        name: s.key
        value: string(s.value)
      }]
    }
  }
}

output planId string = plan.id
output principalId string = web.identity.principalId
output defaultHostName string = web.properties.defaultHostName
output name string = web.name

param planName string
param functionAppName string
param location string
param tags object
param storageAccountName string
param appSettings object = {}
@description('Existing App Service plan id to host the function (empty = create a Consumption Y1 plan)')
param planId string = ''
@description('Subnet id for VNet integration (empty = off). Needs a dedicated plan; Consumption does not support it')
param integrationSubnetId string = ''

var dedicated = !empty(planId)

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Linux Consumption (Y1), only created when no dedicated plan is passed in
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = if (!dedicated) {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: { name: 'Y1', tier: 'Dynamic' }
  properties: { reserved: true }
}

// Host storage (AzureWebJobsStorage) uses a key so the role set stays Blob/Queue/Table Data Contributor only.
// The key only lives in the app setting and is NEVER output. Traffic reaches storage through the VNet service endpoint.
// A dedicated Linux plan needs no WEBSITE_CONTENTAZUREFILECONNECTIONSTRING / WEBSITE_CONTENTSHARE.
var hostConnection = 'DefaultEndpointsProtocol=https;AccountName=${sa.name};AccountKey=${sa.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

var baseSettings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'node'
  STORAGE_ACCOUNT_NAME: storageAccountName
}

var settingsList = [for s in items(union(baseSettings, appSettings)): {
  name: s.key
  value: string(s.value)
}]

resource func 'Microsoft.Web/sites@2025-03-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: dedicated ? planId : plan.id
    httpsOnly: true
    virtualNetworkSubnetId: empty(integrationSubnetId) ? null : integrationSubnetId
    outboundVnetRouting: empty(integrationSubnetId) ? null : { allTraffic: true }
    siteConfig: {
      linuxFxVersion: 'Node|22'
      alwaysOn: dedicated
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: concat([ { name: 'AzureWebJobsStorage', value: hostConnection } ], settingsList)
    }
  }
}

output principalId string = func.identity.principalId
output name string = func.name

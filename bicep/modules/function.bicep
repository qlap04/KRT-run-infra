param planName string
param functionAppName string
param location string
param tags object
param storageAccountName string
param appSettings object = {}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Linux Consumption (Y1)
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: { name: 'Y1', tier: 'Dynamic' }
  properties: { reserved: true }
}

// Host storage (AzureWebJobsStorage) uses a key: Linux Consumption does not support identity-based host storage well.
// The key only lives in the app setting and is NEVER output.
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

resource func 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Node|22'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: concat([ { name: 'AzureWebJobsStorage', value: hostConnection } ], settingsList)
    }
  }
}

output principalId string = func.identity.principalId
output name string = func.name

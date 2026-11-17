param functionAppName string

param location string

param tags object

param storageAccountName string

param appSettings object = {}

@description('Existing App Service plan id')
param planId string

@description('Subnet id for VNet integration')
param integrationSubnetId string

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// A Linux App Service plan needs no WEBSITE_CONTENTAZUREFILECONNECTIONSTRING / WEBSITE_CONTENTSHARE.
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
    serverFarmId: planId
    httpsOnly: true
    virtualNetworkSubnetId: integrationSubnetId
    outboundVnetRouting: { allTraffic: true }
    siteConfig: {
      linuxFxVersion: 'Node|22'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: concat([ { name: 'AzureWebJobsStorage', value: hostConnection } ], settingsList)
    }
  }
}

output principalId string = func.identity.principalId
output name string = func.name

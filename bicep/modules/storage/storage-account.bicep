@description('Storage account name (3-24 lowercase letters and digits)')
param name string

param location string

param tags object

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    // Private only: reachable through the private endpoints (storage-private-endpoints.bicep).
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Containers, queues and tables are created by the app at startup
// (storage.ensure() with ENSURE_STORAGE=true), not by infra.

output name string = sa.name

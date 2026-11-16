@description('Storage account name (3-24 lowercase letters and digits)')
param name string
param location string
param tags object
@description('Single blob container for proof images: uploads under incoming/, processed under processed/')
param blobContainer string = 'proofs'
param queueName string = 'upload-jobs'
param tableNames array = [ 'Users', 'Runs', 'AuditLog' ]

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
    // Data plane only; ARM (containers, queues, tables, role assignments) is not affected
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource images 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob
  name: blobContainer
  properties: { publicAccess: 'None' }
}

resource queueSvc 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  parent: queueSvc
  name: queueName
}

resource tableSvc 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = [for t in tableNames: {
  parent: tableSvc
  name: t
}]

output name string = sa.name
output id string = sa.id

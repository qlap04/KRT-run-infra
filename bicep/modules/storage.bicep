@description('Storage account name (3-24 lowercase letters and digits)')
param name string
param location string
param tags object
param incomingContainer string = 'incoming'
param proofsContainer string = 'proofs'
param queueName string = 'upload-jobs'
param tableNames array = [ 'Users', 'Runs', 'AuditLog' ]
@description('Subnet id allowed through the storage firewall (empty = firewall open). When set, everything else is denied')
param allowedSubnetId string = ''

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
    // Data plane only; ARM (containers, queues, tables, role assignments) is not affected by networkAcls
    networkAcls: empty(allowedSubnetId) ? {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    } : {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        { id: allowedSubnetId, action: 'Allow' }
      ]
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource incoming 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob
  name: incomingContainer
  properties: { publicAccess: 'None' }
}

resource proofs 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob
  name: proofsContainer
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

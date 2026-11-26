@description('Key Vault name (3-24 characters, globally unique), from keyVaultName() in naming.bicep')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// Standard SKU, access through Azure RBAC (no access policies).
// Soft delete is always on in Azure and keeps its default retention; purge protection stays off,
// so a deleted dev vault can still be purged.
// Public network access stays on: APIM Consumption cannot join a VNet, so it reads the vault over
// the public endpoint; access is still limited to the RBAC roles granted on the vault.
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
  }
}

output name string = kv.name

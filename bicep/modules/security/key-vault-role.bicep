@description('Name of an existing Key Vault in this resource group')
param vaultName string

@description('Object id of the user or managed identity that gets the role')
param principalId string

@description('User for a person, ServicePrincipal for a managed identity')
@allowed([ 'User', 'ServicePrincipal' ])
param principalType string

@description('SecretsOfficer: manage secret values. SecretsUser: read secret values only')
@allowed([ 'SecretsOfficer', 'SecretsUser' ])
param role string

var roleIds = {
  SecretsOfficer: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // Key Vault Secrets Officer
  SecretsUser: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: vaultName
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, principalId, roleIds[role])
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds[role])
    principalId: principalId
    principalType: principalType
  }
}

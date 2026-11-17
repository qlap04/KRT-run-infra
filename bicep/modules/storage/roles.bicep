param storageAccountName string

@description('Site name (used to build a stable role assignment name)')
param siteName string

param principalId string

var roleIds = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Storage Queue Data Contributor
  '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
]

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource assignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for r in roleIds: {
  name: guid(sa.id, siteName, r)
  scope: sa
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', r)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

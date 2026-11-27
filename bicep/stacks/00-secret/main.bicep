// Secret stack, deployed by provision.yml as the first step (Secret), before network, data and app.
// Subscription scope: creates the Key Vault in secretResourceGroupName() (rg-<prefix>-<environment>-sec,
// which destroy.yml keeps) and gives the person who sets the secret values the Secrets Officer role.
// The vault holds the values only; Bicep never reads or writes them. The app and APIM stacks build
// the vault name with keyVaultName() from naming.bicep, so nothing is looked up.
import { secretResourceGroupName, keyVaultName } from '../../modules/naming.bicep'

targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string

@description('Environment name (dev) -> resource names and tag')
param environment string

param location string

@description('Object id (Microsoft Entra ID) of the person who sets the secret values; gets Key Vault Secrets Officer')
param officerPrincipalId string

var base = '${prefix}-${environment}'
var tags = {
  project: 'krtrun'
  env: environment
}

// Same group and tags as in the network, data and app stacks; the deployment is idempotent.
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: secretResourceGroupName(base)
  location: location
  tags: tags
}

module kv '../../modules/security/key-vault.bicep' = {
  name: 'key-vault'
  scope: rg
  params: {
    name: keyVaultName(subscription().subscriptionId, base)
    location: location
    tags: tags
  }
}

module officer '../../modules/security/key-vault-role.bicep' = {
  name: 'kv-secrets-officer'
  scope: rg
  params: {
    vaultName: kv.outputs.name
    principalId: officerPrincipalId
    principalType: 'User'
    role: 'SecretsOfficer'
  }
}

output keyVaultName string = kv.outputs.name

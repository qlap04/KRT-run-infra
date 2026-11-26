param name string

param location string

param tags object

param publisherEmail string

param publisherName string

@description('Browser origins allowed to call the gateway (the frontend on Static Web Apps)')
param allowedOrigins array

@description('Key Vault (secret stack) that holds gateway-secret, the value APIM adds to every backend call')
param keyVaultName string

@description('Resource group of that Key Vault')
param keyVaultResourceGroup string

@description('Name of the gateway secret in the vault')
param gatewaySecretName string

// Consumption: cheapest (1 million free calls/month) but it CANNOT join a VNet.
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Consumption', capacity: 0 }
  // System-assigned identity: reads the gateway secret from Key Vault.
  identity: { type: 'SystemAssigned' }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// APIM may read secret values from the vault (Key Vault Secrets User).
module kvApim '../security/key-vault-role.bicep' = {
  name: 'kv-secrets-user-apim'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    vaultName: keyVaultName
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
    role: 'SecretsUser'
  }
}

// Named value (secret) linked to Key Vault: the policy reads it as {{gateway-secret}}, so the
// value never appears in the policy XML, and Bicep and the pipeline never see it.
// No version in the URI: APIM picks up a new secret version on its periodic refresh.
resource gatewaySecretNv 'Microsoft.ApiManagement/service/namedValues@2023-09-01-preview' = {
  parent: apim
  name: 'gateway-secret'
  dependsOn: [ kvApim ] // the identity needs the role before APIM reads the secret
  properties: {
    displayName: 'gateway-secret'
    secret: true
    keyVault: {
      secretIdentifier: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${gatewaySecretName}'
    }
  }
}

// Global (all APIs) policy: CORS for the SPA. The frontend and APIM are on
// different domains, so the browser sends a preflight that APIM must answer.
// set-header: proves to the Web App that the call came through APIM
// (override also replaces any value a client sends itself).
var originsXml = join(map(allowedOrigins, o => '<origin>${o}</origin>'), '')

resource globalPolicy 'Microsoft.ApiManagement/service/policies@2023-09-01-preview' = {
  parent: apim
  name: 'policy'
  dependsOn: [ gatewaySecretNv ] // referenced by name inside the XML, so Bicep cannot infer it
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><cors allow-credentials="false"><allowed-origins>${originsXml}</allowed-origins><allowed-methods><method>GET</method><method>POST</method><method>OPTIONS</method></allowed-methods><allowed-headers><header>Authorization</header><header>Content-Type</header></allowed-headers></cors><set-header name="X-Gateway-Secret" exists-action="override"><value>{{gateway-secret}}</value></set-header></inbound><backend><forward-request /></backend><outbound /><on-error /></policies>'
  }
}

output gatewayUrl string = apim.properties.gatewayUrl

// Names and resource ids shared by the stacks: the stack that creates a resource and the
// stacks that use it build the same name, so no stack looks another one up. Import library: other files pull from it
// with `import { ... } from`, it is not deployed as a module.

@description('Subnet and private DNS zone ids created by the network stack')
@export()
type AppNetwork = {
  @description('Subnet id for App Service VNet integration (web + function)')
  appIntegrationSubnetId: string

  @description('Subnet id for the storage private endpoints')
  peSubnetId: string

  @description('Private DNS zone ids, same order as storageServices')
  dnsZoneIds: string[]
}

@export()
var storageServices = [ 'blob', 'queue', 'table' ]

@export()
func resourceGroupName(base string) string => 'rg-${base}'

@export()
func vnetName(base string) string => '${base}-vnet'

@export()
func appSubnetName() string => 'snet-app-integration'

@export()
func peSubnetName() string => 'snet-pe'

@export()
func dnsZoneName(service string) string => 'privatelink.${service}.${environment().suffixes.storage}'

// Ids built from the names above, used by the data and app stacks.
// The VNet and zones live in the same resource group as data and app (resourceGroupName).
@export()
func appNetworkIds(subscriptionId string, base string) AppNetwork => {
  appIntegrationSubnetId: resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/virtualNetworks/subnets', vnetName(base), appSubnetName())
  peSubnetId: resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/virtualNetworks/subnets', vnetName(base), peSubnetName())
  dnsZoneIds: map(storageServices, s => resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/privateDnsZones', dnsZoneName(s)))
}

// Storage account name (3-24 lowercase letters and digits), unique per resource group.
// resourceGroupId: resourceGroup().id, or the id of resourceGroupName(base) at subscription scope.
@export()
func storageAccountName(base string, resourceGroupId string) string => take(toLower(replace('st${base}${uniqueString(resourceGroupId)}', '-', '')), 24)

// Key Vault of the secret stack (00-secret). Today it shares the resource group of the other
// stacks; change only this function to move it to a separate group (e.g. 'rg-${base}-sec').
@export()
func secretResourceGroupName(base string) string => resourceGroupName(base)

// Vault name (3-24 characters, globally unique), the same in every stack that builds it.
@export()
func keyVaultName(subscriptionId string, base string) string => take('kv${replace(base, '-', '')}${uniqueString(subscriptionId, secretResourceGroupName(base))}', 24)

// Secret names in the vault. The values are set once by hand (az keyvault secret set), never by Bicep.
@export()
var keyVaultSecretNames = {
  sessionSecret: 'session-secret'
  adminCode: 'admin-code'
  apiKey: 'api-key'
  gatewaySecret: 'gateway-secret'
}

// App setting value that App Service resolves with the app's managed identity.
@export()
func keyVaultReference(vaultName string, secretName string) string => '@Microsoft.KeyVault(VaultName=${vaultName};SecretName=${secretName})'

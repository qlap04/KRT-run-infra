// Names and resource ids of the network layer, shared by the network stack (creates the
// resources) and the app stack (consumes them). Import library: other files pull from it
// with `import { ... } from`, it is not deployed as a module.

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

// Ids built from the names above, so the app stack does not look the network up.
// The VNet and zones live in the same resource group as the app (resourceGroupName).
@export()
func appNetworkIds(subscriptionId string, base string) object => {
  appIntegrationSubnetId: resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/virtualNetworks/subnets', vnetName(base), appSubnetName())
  peSubnetId: resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/virtualNetworks/subnets', vnetName(base), peSubnetName())
  dnsZoneIds: map(storageServices, s => resourceId(subscriptionId, resourceGroupName(base), 'Microsoft.Network/privateDnsZones', dnsZoneName(s)))
}

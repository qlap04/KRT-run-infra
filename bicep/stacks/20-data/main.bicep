// Data stack, deployed by its own pipeline (provision-data.yml) after the network stack.
// Subscription scope: in rg-<prefix>-<environment> (shared with the network and app stacks),
// creates the storage account and its private endpoints in snet-pe, registered in the
// Private DNS zones of the network stack. The app stack assigns its roles on this account.
import { resourceGroupName, appNetworkIds, storageAccountName } from '../../modules/naming.bicep'

targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string

@description('Environment name (dev) -> resource names and tag')
param environment string

param location string

var base = '${prefix}-${environment}'
var tags = {
  project: 'krtrun'
  env: environment
}
var network = appNetworkIds(subscription().subscriptionId, base)

// Same group and tags as in the network and app stacks; the deployment is idempotent.
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName(base)
  location: location
  tags: tags
}

module storage '../../modules/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: storageAccountName(base, rg.id)
    location: location
    tags: tags
  }
}

module storagePe '../../modules/network/storage-private-endpoints.bicep' = {
  name: 'storage-pe'
  scope: rg
  params: {
    location: location
    tags: tags
    storageAccountName: storage.outputs.name
    peSubnetId: network.peSubnetId
    dnsZoneIds: network.dnsZoneIds
  }
}

output storageAccountName string = storage.outputs.name

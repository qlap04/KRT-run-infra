// Network stack, deployed by its own pipeline (provision-network.yml). Run first.
// Subscription scope: creates rg-<prefix>-<environment> (shared with the app stack) with the
// VNet, its subnets and the Private DNS zones. The app stack builds the ids from naming.bicep.
import { resourceGroupName, vnetName } from '../../modules/naming.bicep'

targetScope = 'subscription'

@description('Resource name prefix')
@minLength(3)
@maxLength(10)
param prefix string

@description('Environment name (dev) -> resource names and tag')
param environment string

param location string

@description('VNet address space')
param vnetAddressPrefix string = '10.20.0.0/16'

@description('Subnet for App Service VNet integration (web + function)')
param appSubnetPrefix string = '10.20.1.0/24'

@description('Subnet for the storage private endpoints')
param peSubnetPrefix string = '10.20.2.0/24'

var base = '${prefix}-${environment}'
var tags = {
  project: 'krtrun'
  env: environment
}

// Same group and tags as in the app stack; the deployment is idempotent.
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName(base)
  location: location
  tags: tags
}

module vnet '../../modules/network/vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    name: vnetName(base)
    location: location
    tags: tags
    addressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module dns '../../modules/network/private-dns.bicep' = {
  name: 'private-dns'
  scope: rg
  params: {
    tags: tags
    vnetId: vnet.outputs.vnetId
  }
}

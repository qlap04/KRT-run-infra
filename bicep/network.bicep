// Network stack: VNet, subnets and the Private DNS zones linked to it.
// Called by main.bicep with scope = the app RG, before app.bicep.
targetScope = 'resourceGroup'

@description('Resource name prefix')
param prefix string

@description('Resource name set used in resource names (prefix-resourceEnv-*)')
param resourceEnv string

param location string

param tags object

@description('VNet address space')
param vnetAddressPrefix string

@description('Subnet for App Service VNet integration (web + function)')
param appSubnetPrefix string

@description('Subnet for the storage private endpoints')
param peSubnetPrefix string

module vnet 'modules/network/vnet.bicep' = {
  name: 'vnet'
  params: {
    name: '${prefix}-${resourceEnv}-vnet'
    location: location
    tags: tags
    addressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module dns 'modules/network/private-dns.bicep' = {
  name: 'private-dns'
  params: {
    tags: tags
    vnetId: vnet.outputs.vnetId
  }
}

output appIntegrationSubnetId string = vnet.outputs.appIntegrationSubnetId
output peSubnetId string = vnet.outputs.peSubnetId
output dnsZoneIds array = dns.outputs.zoneIds

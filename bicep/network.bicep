// Network stack: VNet, subnets and the Private DNS zones linked to it.
// Called by main.bicep with scope = the app RG, before app.bicep.
targetScope = 'resourceGroup'

@description('Name base <prefix>-<env>, built once in main.bicep')
param base string

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
    name: '${base}-vnet'
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

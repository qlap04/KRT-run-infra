@description('VNet name')
param name string
param location string
param tags object
@description('VNet address space, e.g. 10.20.0.0/16')
param addressPrefix string
@description('App integration subnet (web + function), e.g. 10.20.1.0/24')
param appSubnetPrefix string
@description('Reserved subnet for later use, e.g. 10.20.2.0/24')
param reservedSubnetPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ addressPrefix ] }
    subnets: [
      {
        name: 'snet-app-integration'
        properties: {
          addressPrefix: appSubnetPrefix
          // Lets the storage firewall recognise traffic from this subnet
          serviceEndpoints: [
            { service: 'Microsoft.Storage', locations: [ '*' ] }
          ]
          delegations: [
            {
              name: 'webapp-delegation'
              properties: { serviceName: 'Microsoft.Web/serverFarms' }
            }
          ]
        }
      }
      {
        name: 'snet-reserved'
        properties: { addressPrefix: reservedSubnetPrefix }
      }
    ]
  }
}

output vnetId string = vnet.id
output appIntegrationSubnetId string = '${vnet.id}/subnets/snet-app-integration'

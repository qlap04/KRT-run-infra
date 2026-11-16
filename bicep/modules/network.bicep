@description('VNet name')
param name string
param location string
param tags object
@description('VNet address space')
param addressPrefix string = '10.20.0.0/16'

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
          addressPrefix: '10.20.1.0/24'
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
        properties: { addressPrefix: '10.20.2.0/24' }
      }
    ]
  }
}

output vnetId string = vnet.id
output appIntegrationSubnetId string = '${vnet.id}/subnets/snet-app-integration'

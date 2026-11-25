import { appSubnetName, peSubnetName } from '../naming.bicep'

@description('VNet name')
param name string

param location string

param tags object

@description('VNet address space')
param addressPrefix string

@description('App integration subnet (web + function)')
param appSubnetPrefix string

@description('Private endpoints subnet')
param peSubnetPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ addressPrefix ] }
    subnets: [
      {
        name: appSubnetName()
        properties: {
          addressPrefix: appSubnetPrefix
          delegations: [
            {
              name: 'webapp-delegation'
              properties: { serviceName: 'Microsoft.Web/serverFarms' }
            }
          ]
        }
      }
      {
        name: peSubnetName()
        properties: { addressPrefix: peSubnetPrefix }
      }
    ]
  }
}

output vnetId string = vnet.id

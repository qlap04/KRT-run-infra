import { storageServices } from '../naming.bicep'

param location string

param tags object

param storageAccountName string

@description('Private DNS zone ids, same order as storageServices (naming.bicep)')
param dnsZoneIds array

@description('Subnet id that hosts the private endpoints (snet-pe)')
param peSubnetId string

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource pes 'Microsoft.Network/privateEndpoints@2023-11-01' = [for s in storageServices: {
  name: 'pe-${storageAccountName}-${s}'
  location: location
  tags: tags
  properties: {
    subnet: { id: peSubnetId }
    privateLinkServiceConnections: [
      {
        name: s
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [ s ]
        }
      }
    ]
  }
}]

resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [for (s, i) in storageServices: {
  parent: pes[i]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: s
        properties: { privateDnsZoneId: dnsZoneIds[i] }
      }
    ]
  }
}]

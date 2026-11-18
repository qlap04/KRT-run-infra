param location string

param tags object

param storageAccountName string

@description('Private DNS zone ids, same order as services (from network.bicep)')
param dnsZoneIds array

@description('Subnet id that hosts the private endpoints (snet-pe)')
param peSubnetId string

var services = [ 'blob', 'queue', 'table' ]

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource pes 'Microsoft.Network/privateEndpoints@2023-11-01' = [for s in services: {
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

resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [for (s, i) in services: {
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

param location string

param tags object

param storageAccountName string

@description('VNet id the private DNS zones are linked to')
param vnetId string

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

// privatelink.<service>.core.windows.net: makes <account>.<service>.core.windows.net resolve to the private IP inside the VNet
resource zones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for s in services: {
  name: 'privatelink.${s}.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}]

resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (s, i) in services: {
  parent: zones[i]
  name: 'link-vnet'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: { id: vnetId }
  }
}]

resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [for (s, i) in services: {
  parent: pes[i]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: s
        properties: { privateDnsZoneId: zones[i].id }
      }
    ]
  }
}]

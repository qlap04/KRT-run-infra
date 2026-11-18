// Private DNS zones for the storage private endpoints, linked to the VNet.
// privatelink.<service>.core.windows.net: makes <account>.<service>.core.windows.net resolve to the private IP inside the VNet
param tags object

@description('VNet id the private DNS zones are linked to')
param vnetId string

@description('Storage services that get a zone (order matches the zoneIds output)')
param services array = [ 'blob', 'queue', 'table' ]

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
    // Required by the API (no default). false = no auto-registration of VM records.
    registrationEnabled: false
  }
}]

output zoneIds array = [for (s, i) in services: zones[i].id]

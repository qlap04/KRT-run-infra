// Private DNS zones for the storage private endpoints, linked to the VNet.
// privatelink.<service>.core.windows.net: makes <account>.<service>.core.windows.net resolve to the private IP inside the VNet
import { storageServices, dnsZoneName } from '../naming.bicep'

param tags object

@description('VNet id the private DNS zones are linked to')
param vnetId string

resource zones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for s in storageServices: {
  name: dnsZoneName(s)
  location: 'global'
  tags: tags
}]

resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (s, i) in storageServices: {
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

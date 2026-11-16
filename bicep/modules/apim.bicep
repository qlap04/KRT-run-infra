param name string

param location string

param tags object

param publisherEmail string

param publisherName string

// Consumption: cheapest (1 million free calls/month) but it CANNOT join a VNet.
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Consumption', capacity: 0 }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output name string = apim.name
output gatewayUrl string = apim.properties.gatewayUrl

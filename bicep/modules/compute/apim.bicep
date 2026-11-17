param name string

param location string

param tags object

param publisherEmail string

param publisherName string

@description('Browser origins allowed to call the gateway (the frontend on Static Web Apps)')
param allowedOrigins array = []

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

// Global (all APIs) policy: CORS for the SPA. The frontend and APIM are on
// different domains, so the browser sends a preflight that APIM must answer.
var originsXml = join(map(allowedOrigins, o => '<origin>${o}</origin>'), '')

resource globalPolicy 'Microsoft.ApiManagement/service/policies@2023-09-01-preview' = if (!empty(allowedOrigins)) {
  parent: apim
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><cors allow-credentials="false"><allowed-origins>${originsXml}</allowed-origins><allowed-methods><method>GET</method><method>POST</method><method>OPTIONS</method></allowed-methods><allowed-headers><header>Authorization</header><header>Content-Type</header></allowed-headers></cors></inbound><backend><forward-request /></backend><outbound /><on-error /></policies>'
  }
}

output name string = apim.name
output gatewayUrl string = apim.properties.gatewayUrl

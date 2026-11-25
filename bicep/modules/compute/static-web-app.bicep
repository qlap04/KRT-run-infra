// Static Web Apps (Free) hosting the React frontend.
// No repo link: the app pipeline deploys the build with the SWA deployment token.
param name string

@description('Static Web Apps is not offered in every region (no australiaeast)')
param location string

param tags object

@description('Custom domain. Empty skips the resource: Azure validates the CNAME when it is created, so the record must exist first.')
param customDomain string = ''

resource swa 'Microsoft.Web/staticSites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Free', tier: 'Free' }
  properties: {}
}

resource customDomainRes 'Microsoft.Web/staticSites/customDomains@2023-12-01' = if (!empty(customDomain)) {
  parent: swa
  name: customDomain
  properties: {
    validationMethod: 'cname-delegation'
  }
}

output name string = swa.name
output defaultHostname string = swa.properties.defaultHostname

using '../main.bicep'

// Environment: dev
param prefix = 'krtrun'

param environment = 'dev'

param resourceEnv = 'dev'

param location = 'australiaeast'

param appServicePlanSku = 'B1'

// IP plan (dev)
param vnetAddressPrefix = '10.20.0.0/16'

param appSubnetPrefix = '10.20.1.0/24' // snet-app-integration: web + function

param peSubnetPrefix = '10.20.2.0/24' // snet-pe: storage private endpoints

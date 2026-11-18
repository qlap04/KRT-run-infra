using '../main.bicep'

// Environment: dev
// prefix, environment and location come from the pipeline variables
// (common.yml + <env>.yml), which ADO exposes as environment variables.
param prefix = readEnvironmentVariable('PROJECTNAME')

param environment = readEnvironmentVariable('ENVIRONMENT')

param location = readEnvironmentVariable('LOCATION')

param appServicePlanSku = 'B1'

// IP plan (dev)
param vnetAddressPrefix = '10.20.0.0/16'

param appSubnetPrefix = '10.20.1.0/24' // snet-app-integration: web + function

param peSubnetPrefix = '10.20.2.0/24' // snet-pe: storage private endpoints

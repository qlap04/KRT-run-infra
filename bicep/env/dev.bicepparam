using '../main.bicep'

// Environment: dev
param prefix = 'krtrun'

param environment = 'dev'

param resourceEnv = 'dev'

param location = 'australiaeast'

param appServicePlanSku = 'B1'

param deployApim = true

param publisherEmail = 'quoclap030904@gmail.com'

param publisherName = 'KRT-run'

// IP plan (dev)
param vnetAddressPrefix = '10.20.0.0/16'

param appSubnetPrefix = '10.20.1.0/24' // snet-app-integration: web + function

param peSubnetPrefix = '10.20.2.0/24' // snet-pe: storage private endpoints

// Secrets: read from the pipeline's environment variables (variable group krtrun-dev). NEVER put the values in this file.
param sessionSecret = readEnvironmentVariable('SESSION_SECRET', '')

param adminCode = readEnvironmentVariable('ADMIN_CODE', '')

param apiKey = readEnvironmentVariable('API_KEY', '')

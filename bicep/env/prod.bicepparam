using '../main.bicep'

// Environment: prod
// prod: dedicated resource set (resourceEnv=prod), SKU B1 (supports VNet integration)
param prefix = 'krtrun'
param environment = 'prod'
param resourceEnv = 'prod'
param location = 'australiaeast'
param appServicePlanSku = 'B1'
param deployApim = true
param publisherEmail = 'admin@example.com' // change to a real email
param publisherName = 'KRT-run'
param enableInsights = false

// Secrets: read from the pipeline's environment variables (variable group krtrun-prod). NEVER put the values in this file.
param sessionSecret = readEnvironmentVariable('SESSION_SECRET', '')
param adminCode = readEnvironmentVariable('ADMIN_CODE', '')
param apiKey = readEnvironmentVariable('API_KEY', '')

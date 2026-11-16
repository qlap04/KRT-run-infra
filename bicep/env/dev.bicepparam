using '../main.bicep'

// Environment: dev (only active environment for now)
param prefix = 'krtrun'
param environment = 'dev'
param resourceEnv = 'dev'
param location = 'australiaeast'
param appServicePlanSku = 'B1'
param deployApim = true
param publisherEmail = 'admin@example.com' // change to a real email
param publisherName = 'KRT-run'

// Secrets: read from the pipeline's environment variables (variable group krtrun-dev). NEVER put the values in this file.
param sessionSecret = readEnvironmentVariable('SESSION_SECRET', '')
param adminCode = readEnvironmentVariable('ADMIN_CODE', '')
param apiKey = readEnvironmentVariable('API_KEY', '')

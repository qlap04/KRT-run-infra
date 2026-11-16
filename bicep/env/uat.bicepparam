using '../main.bicep'

// Environment: uat
// uat: shares the dev resource set (resourceEnv=dev); only APP_ENV differs
param prefix = 'krtrun'
param environment = 'uat'
param resourceEnv = 'dev'
param location = 'australiaeast'
param appServicePlanSku = 'F1'
param deployApim = true
param publisherEmail = 'admin@example.com' // change to a real email
param publisherName = 'KRT-run'
param enableInsights = false

// Secrets: read from the pipeline's environment variables (variable group krtrun-uat). NEVER put the values in this file.
param sessionSecret = readEnvironmentVariable('SESSION_SECRET', '')
param adminCode = readEnvironmentVariable('ADMIN_CODE', '')
param apiKey = readEnvironmentVariable('API_KEY', '')

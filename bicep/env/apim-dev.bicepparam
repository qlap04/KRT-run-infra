using '../apim.bicep'

// Environment: dev (APIM stack)
// prefix, environment and location come from the pipeline variables
// (common.yml + <env>.yml), which ADO exposes as environment variables.
param prefix = readEnvironmentVariable('PROJECTNAME')

param environment = readEnvironmentVariable('ENVIRONMENT')

param location = readEnvironmentVariable('LOCATION')

param publisherEmail = 'quoclap030904@gmail.com'

param publisherName = 'KRT-run'

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// ⚠️ INTENTIONALLY MISSING TAGS on some resources
var tagsComplete = {
  'azd-env-name': environmentName
  purpose: 'sre-agent-cost-demo'
  'cost-center': 'engineering'
  owner: 'platform-team'
}

// ⚠️ Tags missing cost-center and owner
var tagsIncomplete = {
  'azd-env-name': environmentName
  purpose: 'sre-agent-cost-demo'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tagsComplete
}

// Deploy cost demo resources
module costDemo 'resources.bicep' = {
  name: 'cost-demo-resources'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tagsComplete: tagsComplete
    tagsIncomplete: tagsIncomplete
  }
}

output RESOURCE_GROUP_NAME string = rg.name
output VM1_NAME string = costDemo.outputs.vm1Name
output VM2_NAME string = costDemo.outputs.vm2Name
output ORPHANED_DISK_NAME string = costDemo.outputs.orphanedDiskName
output UNTAGGED_STORAGE_NAME string = costDemo.outputs.untaggedStorageName
output WEB_APP_URL string = costDemo.outputs.webAppUrl
output AZURE_LOCATION string = location
output SERVICE_API_NAME string = costDemo.outputs.webAppName
output SERVICE_API_RESOURCE_GROUP string = rg.name

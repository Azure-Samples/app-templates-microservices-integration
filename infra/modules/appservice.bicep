param webAppName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
param dockerRegistryUrl string = 'https://mcr.microsoft.com'
param dockerRegistryUsername string
param dockerRegistryPassword string
var webSiteName = toLower('app-${webAppName}')

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  kind: 'linux'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: [
        {
            name: 'DOCKER_REGISTRY_SERVER_URL'
            value: dockerRegistryUrl
        }
        {
            name: 'DOCKER_REGISTRY_SERVER_USERNAME'
            value: dockerRegistryUsername
        }
        {
            name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
            value: dockerRegistryPassword
        }
        {
            name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
            value: 'false'
        }
      ]
      linuxFxVersion: linuxFxVersion
    }
  }
}

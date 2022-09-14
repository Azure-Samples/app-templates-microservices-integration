param functionName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/azure-functions/dotnet:3.0-appservice-quickstart'
param dockerRegistryUrl string = 'https://mcr.microsoft.com'
param dockerRegistryUsername string
param dockerRegistryPassword string
param storageAccountAddress string
var webSiteName = toLower('app-${functionName}')

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: [
        {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~3'
        }
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
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountAddress
        }
      ]
      cors: {
          allowedOrigins: [
              'https://portal.azure.com'
          ]
      }
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
    }
  }
}

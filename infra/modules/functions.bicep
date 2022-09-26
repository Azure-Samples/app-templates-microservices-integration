param functionName string
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param storageAccountAddress string
param appInsightsName string
param registryName string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: functionName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      cors: {
          allowedOrigins: [
              'https://portal.azure.com'
          ]
      }
      linuxFxVersion: 'DOCKER|${registry.properties.loginServer}/reddog/${functionName}:latest'
    }
  }
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    DOCKER_REGISTRY_SERVER_URL: registry.properties.loginServer
    DOCKER_REGISTRY_SERVER_USERNAME: registry.listCredentials().username
    DOCKER_REGISTRY_SERVER_PASSWORD: registry.listCredentials().passwords[0].value
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
    WEBSITE_CONTENTSHARE: toLower(functionName)
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  }
  dependsOn: [
    appInsights
  ]
}

resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'logs'
  dependsOn: [
    appServiceAppSettings
  ]
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

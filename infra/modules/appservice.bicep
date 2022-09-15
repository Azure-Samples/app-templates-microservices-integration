param webAppName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
param dockerRegistryUrl string = 'https://mcr.microsoft.com'
param dockerRegistryUsername string
@secure()
param dockerRegistryPassword string
param appInsightsName string

var webSiteName = toLower('app-${webAppName}')

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  kind: 'linux'
  properties: {
    serverFarmId: serverFarmId
    httpsOnly: true
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
      minTlsVersion: '1.2'
    }
  }
}

resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
  }
  dependsOn: [
    appInsights
  ]
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: appService
  name: 'logs'
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

param webAppName string
param location string = resourceGroup().location // Location for all resources
param serverFarmId string
param appInsightsName string
param registryName string
param imageName string
param apimName string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource apimResource 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  kind: 'linux,container'
  properties: {
    serverFarmId: serverFarmId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry.properties.loginServer}/reddog/${imageName}:latest'
      minTlsVersion: '1.2'
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
    DOCKER_REGISTRY_SERVER_URL: registry.properties.loginServer
    DOCKER_REGISTRY_SERVER_USERNAME: registry.listCredentials().username
    DOCKER_REGISTRY_SERVER_PASSWORD: registry.listCredentials().passwords[0].value
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    VUE_APP_MAKELINE_BASE_URL: '${apimResource.properties.gatewayUrl}/makeline/'
    VUE_APP_ACCOUNTING_BASE_URL: '${apimResource.properties.gatewayUrl}/accounting/'
  }
  dependsOn: [
    apimResource
  ]
}

resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
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

output defaultHostName string = appService.properties.defaultHostName

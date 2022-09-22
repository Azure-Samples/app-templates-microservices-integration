@description('The name of the API Management resource to be created.')
param apimName string

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string = 'apim@contoso.com'

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string = 'Contoso'

@description('The pricing tier of the APIM resource.')
param skuName string = 'Developer'

@description('The instance size of the APIM resource.')
param capacity int = 1

@description('Location for Azure resources.')
param location string = resourceGroup().location

param appInsightsName string

/*
 * Resources
*/
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource apimResource 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimName
  location: location
  sku: {
    capacity: capacity
    name: skuName
  }
  properties: {
    virtualNetworkType: 'External'
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource accountingApiResource 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  parent: apimResource
  name: 'accounting-service'
  properties: {
    displayName: 'AccountingService'
    subscriptionRequired: false
    path: 'accounting'
    protocols: [
      'https'
    ]
    isCurrent: true
  }
}

resource makelineApiResource 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  parent: apimResource
  name: 'makeline-service'
  properties: {
    displayName: 'MakeLineService'
    subscriptionRequired: false
    path: 'makeline'
    protocols: [
      'https'
    ]
    isCurrent: true
  }
}

resource accountingService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'accounting-service'
}

resource accountingBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_accounting-service'
  parent: apimResource
  properties: {
    description: 'accounting-service'
    url: accountingService.properties.configuration.ingress.fqdn
    protocol: 'http'
    resourceId: accountingService.id
  }
}

resource makeLineService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'make-line-service'
}

resource makelineBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_make-line-service'
  parent: apimResource
  properties: {
    description: 'make-line-service'
    url: makeLineService.properties.configuration.ingress.fqdn
    protocol: 'http'
    resourceId: makeLineService.id
  }
}

resource orderService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'order-service'
}

resource orderBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_order-service'
  parent: apimResource
  properties: {
    description: 'order-service'
    url: orderService.properties.configuration.ingress.fqdn
    protocol: 'http'
    resourceId: orderService.id
  }
}

resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apimResource
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsights.id
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

resource appInsightsDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2019-01-01' = {
  parent: apimResource
  name: 'applicationinsights'
  properties: {
    loggerId: appInsightsLogger.id
    alwaysLog: 'allErrors'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}

output gatewayUrl string = apimResource.properties.gatewayUrl
output portalUrl string = apimResource.properties.portalUrl

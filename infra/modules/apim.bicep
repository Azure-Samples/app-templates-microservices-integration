
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

resource apimName_resource 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimName
  location: location
  sku:{
    capacity: capacity
    name: skuName
  }
  properties:{
    virtualNetworkType: 'External'
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource apimName_appInsightsLogger_resource 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apimName_resource
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsights.id
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

resource apimName_applicationinsights 'Microsoft.ApiManagement/service/diagnostics@2019-01-01' = {
  parent: apimName_resource
  name: 'applicationinsights'
  properties: {
    loggerId: apimName_appInsightsLogger_resource.id
    alwaysLog: 'allErrors'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}

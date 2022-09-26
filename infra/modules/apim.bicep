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
resource apimPolicy 'Microsoft.ApiManagement/service/policies@2021-12-01-preview' = {
  name: '${apimName}policy'
  parent: apimResource
  properties: {
    format: 'rawxml'
    value: loadTextContent('apimPolicies/global.xml')
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

resource orderApiResource 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  parent: apimResource
  name: 'order-service'
  properties: {
    displayName: 'OrderService'
    subscriptionRequired: false
    path: 'order'
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
    description: accountingService.name
    url: 'https://${accountingService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${accountingService.name}'
  }
}

resource makeLineService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'make-line-service'
}

resource makelineBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_make-line-service'
  parent: apimResource
  properties: {
    description: makeLineService.name
    url: 'https://${makeLineService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${makeLineService.name}'
  }
}

resource orderService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'order-service'
}

resource orderBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_order-service'
  parent: apimResource
  properties: {
    description: orderService.name
    url: 'https://${orderService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${orderService.name}'
  }
}

resource getOrdersOperationResource 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-orders-storeid'
  parent: makelineApiResource
  properties: {
    displayName: '/orders/{storeId} - GET'
    method: 'GET'
    urlTemplate: '/orders/{storeId}'
    templateParameters: [
      {
        name: 'storeId'
        type: 'string'
        required: true
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}

resource orderMetricsOperationResource 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-ordermetrics'
  parent: accountingApiResource
  properties: {
    displayName: '/OrderMetrics - GET'
    method: 'GET'
    urlTemplate: '/OrderMetrics'
    request: {
      queryParameters: [
        {
          name: 'storeId'
          type: 'string'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Success'
        representations: [
          {
            contentType: 'text/plain'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: [
                  {
                    storeId: 'string'
                    orderDate: 'string'
                    orderHour: 0
                    orderCount: 0
                    avgFulfillmentSec: 0
                    orderItemCount: 0
                    totalCost: 0
                    totalPrice: 0
                  }
                ]
              }
            }
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: [
                  {
                    storeId: 'string'
                    orderDate: 'string'
                    orderHour: 0
                    orderCount: 0
                    avgFulfillmentSec: 0
                    orderItemCount: 0
                    totalCost: 0
                    totalPrice: 0
                  }
                ]
              }
            }
          }
        ]
      }
    ]
  }
}

resource getOrderMetricsPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getOrdersOperationResource
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/OrderMetrics" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
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

@description('The name of the API Management resource to be created.')
param apimName string

resource apimResource 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource accountingService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'accounting-service'
}

resource accountingBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_accounting-service'
  parent: apimResource
  dependsOn: [
    accountingService
  ]
  properties: {
    description: accountingService.name
    url: 'https://${accountingService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${accountingService.name}'
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

resource accountingApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: accountingApiResource
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service id="apim-generated-policy" backend-id="${accountingBackendResource.name}" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
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
  parent: orderMetricsOperationResource
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/OrderMetrics" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

resource getOrdersPeriodOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-orders-period-timespan'
  parent: accountingApiResource
  properties: {
    displayName: '/Orders/{period}/{timeSpan} - GET'
    method: 'GET'
    urlTemplate: '/Orders/{period}/{timeSpan}'
    templateParameters: [
      {
        name: 'period'
        type: 'string'
        required: true
      }
      {
        name: 'timeSpan'
        type: 'string'
        required: true
      }
    ]
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
          }
          {
            contentType: 'text/json'
          }
        ]
      }
    ]
  }
}

resource getOrdersPeriodPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getOrdersPeriodOperation
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/Orders/{period}/{timeSpan}" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

resource getSalesProfitPerStoreOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-corp-salesprofit-perstore'
  parent: accountingApiResource
  properties: {
    displayName: '/Corp/SalesProfit/PerStore - GET'
    method: 'GET'
    urlTemplate: '/Corp/SalesProfit/PerStore'
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
                    orderYear: 0
                    orderMonth: 0
                    orderDay: 0
                    orderHour: 0
                    totalOrders: 0
                    totalOrderItems: 0
                    totalSales: 0
                    totalProfit: 0
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
                    orderYear: 0
                    orderMonth: 0
                    orderDay: 0
                    orderHour: 0
                    totalOrders: 0
                    totalOrderItems: 0
                    totalSales: 0
                    totalProfit: 0
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

resource getSalesProfitPerStorePolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getSalesProfitPerStoreOperation
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/Corp/SalesProfit/PerStore" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

resource getSalesProfitTotalOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-corp-salesprofit-total'
  parent: accountingApiResource
  properties: {
    displayName: '/Corp/SalesProfit/Total - GET'
    method: 'GET'
    urlTemplate: '/Corp/SalesProfit/Total'
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
                    orderYear: 0
                    orderMonth: 0
                    orderDay: 0
                    orderHour: 0
                    totalOrders: 0
                    totalOrderItems: 0
                    totalSales: 0
                    totalProfit: 0
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
                    orderYear: 0
                    orderMonth: 0
                    orderDay: 0
                    orderHour: 0
                    totalOrders: 0
                    totalOrderItems: 0
                    totalSales: 0
                    totalProfit: 0
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

resource getSalesProfitTotalPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getSalesProfitTotalOperation
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/Corp/SalesProfit/Total" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

resource getCorpStoresOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-corp-stores'
  parent: accountingApiResource
  properties: {
    displayName: '/Corp/Stores - GET'
    method: 'GET'
    urlTemplate: '/Corp/Stores'
    templateParameters: []
    responses: [
      {
        statusCode: 200
        description: 'Success'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: [
                  'string'
                ]
              }
            }
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: [
                  'string'
                ]
              }
            }
          }
        ]
      }
    ]
  }
}

resource getCorpStoresPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getCorpStoresOperation
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/Corp/Stores" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}


@description('The name of the API Management resource to be created.')
param apimName string

resource apimResource 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource orderService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'order-service'
}

resource orderBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_order-service'
  parent: apimResource
  dependsOn: [
    orderService
  ]
  properties: {
    description: orderService.name
    url: 'https://${orderService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${orderService.id}'
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

resource orderApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: orderApiResource
  properties: {
    value: replace(loadTextContent('apimPolicies/api.xml'), '{backendName}', orderBackendResource.name)
    format: 'xml'
  }
}

resource getProductsOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-products'
  parent: orderApiResource
  properties: {
    displayName: '/product - GET'
    method: 'GET'
    urlTemplate: '/product'
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
                    productId: 0
                    productName: 'string'
                    description: 'string'
                    unitCost: 0
                    unitPrice: 0
                    imageUrl: 'string'
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
                    productId: 0
                    productName: 'string'
                    description: 'string'
                    unitCost: 0
                    unitPrice: 0
                    imageUrl: 'string'
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

resource getProductsPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getProductsOperation
  properties: {
    value: replace(replace(loadTextContent('apimPolicies/operation.xml'), '{method}', 'GET'), '{template}', '/product')
    format: 'xml'
  }
}

resource postOrderOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'post-order'
  parent: orderApiResource
  properties: {
    displayName: '/order - POST'
    method: 'POST'
    urlTemplate: '/order'
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                storeId: 0
                firstName: 'string'
                lastName: 'string'
                loyaltyId: 'string'
                orderItems: [
                  {
                    productId: 0
                    quantity: 0
                  }
                ]
              }
            }
          }
        }
        {
          contentType: 'text/json'
          examples: {
            default: {
              value: {
                storeId: 0
                firstName: 'string'
                lastName: 'string'
                loyaltyId: 'string'
                orderItems: [
                  {
                    productId: 0
                    quantity: 0
                  }
                ]
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}

resource postOrderPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: postOrderOperation
  properties: {
    value: replace(replace(loadTextContent('apimPolicies/operation.xml'), '{method}', 'POST'), '{template}', '/order')
    format: 'xml'
  }
}

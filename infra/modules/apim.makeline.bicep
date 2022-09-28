@description('The name of the API Management resource to be created.')
param apimName string

resource apimResource 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource makeLineService 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: 'make-line-service'
}

resource makelineBackendResource 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'ContainerApp_make-line-service'
  parent: apimResource
  dependsOn: [
    makeLineService
  ]
  properties: {
    description: makeLineService.name
    url: 'https://${makeLineService.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${makeLineService.id}'
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

resource makelineApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: makelineApiResource
  properties: {
    value: replace(loadTextContent('apimPolicies/api.xml'), '{backendName}', makelineBackendResource.name)
    format: 'xml'
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

resource getOrdersPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getOrdersOperationResource
  properties: {
    value: replace(replace(loadTextContent('apimPolicies/operation.xml'), '{method}', 'GET'), '{template}', '/orders/{storeId}')
    format: 'xml'
  }
}

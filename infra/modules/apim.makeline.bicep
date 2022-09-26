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
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${makeLineService.name}'
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
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service id="apim-generated-policy" backend-id="${makelineBackendResource.name}" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
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
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-method>GET</set-method>\r\n    <rewrite-uri id="apim-generated-policy" template="/orders/{storeId}" />\r\n    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

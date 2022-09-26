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
    resourceId: 'https://management.azure.com/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerApps/${orderService.name}'
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
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service id="apim-generated-policy" backend-id="${orderBackendResource.name}" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

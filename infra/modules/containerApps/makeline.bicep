param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param registryName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource makeLineService 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'make-line-service'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'make-line-service'
          image: '${registry.properties.loginServer}/reddog/make-line:latest'
          probes: [
            {
              type: 'startup'
              httpGet: {
                path: '/probes/healthz'
                port: 80
              }
              failureThreshold: 6
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                topicName: 'orders'
                subscriptionName: 'make-line-service'
                messageCount: '10'
              }
              auth: [
                {
                  secretRef: 'sb-root-connectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
          {
            name: 'http-rule'
            http: {
              metadata: {
                  concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'make-line-service'
        appPort: 80
        appProtocol: 'http'
      }
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
        }
        {
          name: 'registry'
          value: registry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: registry.properties.loginServer
          username: registry.listCredentials().username
          passwordSecretRef: 'registry'
        }
      ]
    }
  }
}

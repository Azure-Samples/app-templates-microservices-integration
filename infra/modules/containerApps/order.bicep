param containerAppsEnvName string
param location string
param registryName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource orderService 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'order-service'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'order-service'
          image: '${registry.properties.loginServer}/reddog/order-service:latest'
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
      }
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'order-service'
        appPort: 80
        appProtocol: 'http'
      }
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
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

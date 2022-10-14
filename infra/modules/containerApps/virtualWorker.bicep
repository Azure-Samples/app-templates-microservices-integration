param containerAppsEnvName string
param location string
param registryName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: registryName
}

resource virtualWorker 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'virtual-worker'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-worker'
          image: '${registry.properties.loginServer}/reddog/virtual-worker:latest'
          env: [
            {
              name: 'MIN_SECONDS_TO_COMPLETE_ITEM'
              value: '0'
            }
            {
              name: 'MAX_SECONDS_TO_COMPLETE_ITEM'
              value: '1'
            }
          ]
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
        appId: 'virtual-worker'
        appPort: 80
        appProtocol: 'http'
      }
      ingress: {
        external: false
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

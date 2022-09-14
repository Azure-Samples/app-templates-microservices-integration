@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param registryName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param sku string = 'Basic'

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

@description('Output the login server property for later use')
output loginServer string = registry.properties.loginServer
output username string = registry.listCredentials().username
output password string = registry.listCredentials().passwords[0].value

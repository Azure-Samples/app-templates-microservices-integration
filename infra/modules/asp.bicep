param appServicePlanName string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location // Location for all resources
param sku string = 'F1' // The SKU of App Service Plan

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

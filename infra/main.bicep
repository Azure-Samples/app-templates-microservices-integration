targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string
param location string
param uniqueSeed string = '${subscription().subscriptionId}-${name}'
param uniqueSuffix string = 'reddog-${uniqueString(uniqueSeed)}'
param containerAppsEnvName string = 'cae-${uniqueSuffix}'
param logAnalyticsWorkspaceName string = 'log-${uniqueSuffix}'
param appInsightsName string = 'appi-${uniqueSuffix}'
param serviceBusNamespaceName string = 'sb-${uniqueSuffix}'
param redisName string = 'redis-${uniqueSuffix}'
param cosmosAccountName string = 'cosmos-${uniqueSuffix}'
param cosmosDatabaseName string = 'reddog'
param cosmosCollectionName string = 'loyalty'
param storageAccountName string = 'st${replace(uniqueSuffix, '-', '')}'
param blobContainerName string = 'receipts'
param sqlServerName string = 'sql-${uniqueSuffix}'
param sqlDatabaseName string = 'reddog'
param sqlAdminLogin string = 'reddog'
@secure()
param sqlAdminLoginPassword string = take(newGuid(), 16)
param appServicePlanName string = 'asp-${uniqueSuffix}'
param registryName string = 'acr${replace(uniqueSuffix, '-', '')}'
param uiServiceName string = 'ui-${uniqueSuffix}'
param orderServiceName string = 'order-${uniqueSuffix}'
param virtualCustomerName string = 'vc-${uniqueSuffix}'
param apimName string = 'apim-${uniqueSuffix}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${name}'
  location: location
  tags: {
    'azd-env-name': name
  }
}

module insightsModule 'modules/insights.bicep' = {
  name: '${deployment().name}--appinsights'
  scope: resourceGroup
  params: {
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
  }
}

module apimModule 'modules/apim.bicep' = {
  name: '${deployment().name}--apim'
  scope: resourceGroup
  dependsOn: [
    insightsModule
  ]
  params: {
    apimName: apimName
    location: location
    appInsightsName: appInsightsName
  }
}

module containerAppsEnvModule 'modules/aca.bicep' = {
  name: '${deployment().name}--containerAppsEnv'
  scope: resourceGroup
  dependsOn: [
    insightsModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
  }
}

module serviceBusModule 'modules/servicebus.bicep' = {
  name: '${deployment().name}--servicebus'
  scope: resourceGroup
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    location: location
  }
}

module redisModule 'modules/redis.bicep' = {
  name: '${deployment().name}--redis'
  scope: resourceGroup
  params: {
    redisName: redisName
    location: location
  }
}

module cosmosModule 'modules/cosmos.bicep' = {
  name: '${deployment().name}--cosmos'
  scope: resourceGroup
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
    location: location
  }
}

module storageModule 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    location: location
  }
}

module sqlServerModule 'modules/mssql.bicep' = {
  name: '${deployment().name}--sqlserver'
  scope: resourceGroup
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
    location: location
  }
}

module appServicePlan 'modules/asp.bicep' = {
  name: '${deployment().name}--app-service-plan'
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module daprBindingReceipt 'modules/daprComponents/receipt.bicep' = {
  name: '${deployment().name}--dapr-binding-receipt'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    storageModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    storageAccountName: storageAccountName
  }
}

module daprBindingVirtualWorker 'modules/daprComponents/virtualworker.bicep' = {
  name: '${deployment().name}--dapr-binding-virtualworker'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
  }
}

module daprPubsub 'modules/daprComponents/pubsub.bicep' = {
  name: '${deployment().name}--dapr-pubsub'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module daprStateLoyalty 'modules/daprComponents/loyalty.bicep' = {
  name: '${deployment().name}--dapr-state-loyalty'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    cosmosModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
  }
}

module daprStateMakeline 'modules/daprComponents/makeline.bicep' = {
  name: '${deployment().name}--dapr-state-makeline'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    redisModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    redisName: redisName
  }
}

module registryModule 'modules/acr.bicep' = {
  name: '${deployment().name}--docker-registry'
  scope: resourceGroup
  params: {
    registryName: registryName
    location: location
  }
}

module orderServiceModule 'modules/appservice.bicep' = {
  name: '${deployment().name}--order-service'
  scope: resourceGroup
  dependsOn: [
    appServicePlan
    insightsModule
  ]
  params: {
    webAppName: orderServiceName
    location: location
    serverFarmId: appServicePlan.outputs.id
    dockerRegistryUrl: registryModule.outputs.loginServer
    dockerRegistryUsername: registryModule.outputs.username
    dockerRegistryPassword: registryModule.outputs.password
    appInsightsName: appInsightsName
  }
}

module makeLineServiceModule 'modules/containerApps/makeline.bicep' = {
  name: '${deployment().name}--make-line-service'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    redisModule
    daprPubsub
    daprStateMakeline
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module loyaltyServiceModule 'modules/containerApps/loyalty.bicep' = {
  name: '${deployment().name}--loyalty-service'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    daprPubsub
    daprStateLoyalty
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module receiptGenerationServiceModule 'modules/containerApps/receipt.bicep' = {
  name: '${deployment().name}--receipt-generation-service'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    daprBindingReceipt
    daprPubsub
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module virtualWorkerModule 'modules/containerApps/virtualWorker.bicep' = {
  name: '${deployment().name}--virtual-worker'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    makeLineServiceModule
    daprBindingVirtualWorker
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module bootstrapperModule 'modules/containerApps/bootstrapper.bicep' = {
  name: '${deployment().name}--bootstrapper'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    sqlServerModule
    orderServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
  }
}

module accountingServiceModule 'modules/containerApps/accounting.bicep' = {
  name: '${deployment().name}--accounting-service'
  scope: resourceGroup
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    sqlServerModule
    bootstrapperModule
    daprPubsub
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
  }
}

module virtualCustomerModule 'modules/functions.bicep' = {
  name: '${deployment().name}--virtual-customer'
  scope: resourceGroup
  dependsOn: [
    appServicePlan
    insightsModule
  ]
  params: {
    location: location
    functionName: virtualCustomerName
    serverFarmId: appServicePlan.outputs.id
    dockerRegistryUrl: registryModule.outputs.loginServer
    dockerRegistryUsername: registryModule.outputs.username
    dockerRegistryPassword: registryModule.outputs.password
    storageAccountAddress: storageModule.outputs.address
    appInsightsName: appInsightsName
  }
}

module uiModule 'modules/appservice.bicep' = {
  name: '${deployment().name}--ui'
  scope: resourceGroup
  dependsOn: [
    appServicePlan
    insightsModule
  ]
  params: {
    webAppName: uiServiceName
    location: location
    serverFarmId: appServicePlan.outputs.id
    dockerRegistryUrl: registryModule.outputs.loginServer
    dockerRegistryUsername: registryModule.outputs.username
    dockerRegistryPassword: registryModule.outputs.password
    appInsightsName: appInsightsName
  }
}

output urls array = [
  'UI: https://${uiModule.outputs.defaultHostName}'
  'Product: https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/product'
  'Makeline Orders (Redmond): https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/makeline/orders/Redmond'
  'Accounting Order Metrics (Redmond): https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/accounting/OrderMetrics?StoreId=Redmond'
]
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registryModule.outputs.loginServer
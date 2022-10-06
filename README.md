# Red Dog Demo: Azure Container Apps, Azure App Service, Azure Functions, and Azure API Management

This repository leverages the [Reddog codebase](https://github.com/Azure/reddog-code) and was created to help users deploy a comprehensive, microservice-based sample application to Azure Container Apps, Azure App Service, Azure Functions, and Azure API Management.

## Features

This project framework provides the following features:

* UI is hosted in [Azure App Service](https://azure.microsoft.com/en-us/products/app-service/)
* Virtual Customers are hosted in [Azure Functions](https://azure.microsoft.com/en-us/products/functions/)
* The rest of the micro services are hosted in [Azure Container Apps](https://azure.microsoft.com/en-us/services/container-apps/)
* Integration between the UI, Virtual Customers, and Container Apps is handled by [API Management](https://azure.microsoft.com/en-us/products/api-management/)

## Architecture

Below is the architecture  deployed in this demonstration.

![Integration Architecture](assets/paas-architecture.png)

### Additional Azure Services

* [Azure Service Bus](https://azure.microsoft.com/en-us/products/service-bus/)
* [Azure Cosmos Db](https://azure.microsoft.com/en-us/products/cosmos-db/)
* [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs/)
* [Azure SQL Database](https://azure.microsoft.com/en-us/products/azure-sql/database/)
* [Azure Cache for Redis](https://azure.microsoft.com/en-ca/products/cache/)
* [Azure Container Registry](https://azure.microsoft.com/en-ca/products/container-registry/)
* [Azure Monitor](https://azure.microsoft.com/en-ca/products/monitor/)

## Benefits of this Architecture Sample

### Benefits

1. Deploy microservices containers without needing to manage complex container orchestration infrastructure.
1. Running containerized workloads on a serverless and consumption based platform that supports scale to zero.
1. Deploying APIs and exposing APIs to internal and external clients.
1. API Management provides the publishing capability for HTTP APIs, to promote reuse and discoverability. It can manage other cross-cutting concerns such as authentication, throughput limits, and response caching.
1. Continuous build to produce container images and deployment orchestration to increase speed and reliability of deployments.

### Potential Extensions and Alternatives

1. [Deploy microservices with Azure Container Apps and Dapr](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/serverless/microservices-with-container-apps-dapr)
1. [Deploy microservices with Azure Container Apps](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/serverless/microservices-with-container-apps)

## Getting Started

The deployment involves the following:
1. Create the resource group and Azure Container Registry.
1. Build the microservices and create the corresponding container images.
1. Push the container images to the Azure Container Registry.
1. Provision the infrastructure and deploy the microservices and configurations.

There are two deployment options:
1. Deployment script method is to provide a quick start to facilitate developer scenarios. It is the quickest way to get the solution provisioned and functioning in Azure for exploration. 
1. The DevOps method is to provide GitHub actions pipelines to support continuous deployment scenarios. 

>**NOTE**: The APIM deployment can take over an hour to complete.

### Prerequisites

1. Local bash shell with Azure CLI or [Azure Cloud Shell](https://ms.portal.azure.com/#cloudshell/)
1. Azure Subscription. [Create one for free](https://azure.microsoft.com/en-us/free/).
1. Clone or fork of this repository.

### QuickStart Option

```
git clone https://github.com/Azure-Samples/app-templates-eshop-on-paas.git
cd app-templates-eshop-on-paas
chmod +x ./deploy.sh
az login
az account set --subscription <subscription id>
az account show
./deploy.sh -n demo -l eastus2 -c 4f6s1d
```

### GitHub Actions Option

GitHub workflows are included for deploying the solution to Azure.

To run the workflows, follow these steps:

1. Create three environments
  - `Production`
  - `Test`
  - `Features` 
2. Create the following secrets
  - `AZURE_CREDENTIALS`: Follow the instructions [here](github.com/marketplace/actions/azure-login#configure-a-service-principal-with-a-secret) to login using Azure Service Principal with a secret
  - `AZURE_LOCATION`: This is the Azure location where resources will be deployed
  - `AZURE_PROJECT_NAME`: This is the name that will be appended to Azure resources
  - `AZURE_UNIQUE_CODE`: This is a unique code that will be appended to Azure resources
3. Go to [Actions](https://github.com/Azure-Samples/app-templates-eshop-on-paas/actions/)
4. Click on `Deploy Solution`
5. Click on `Run workflow`

## Enhancements Opportunities

Below are opportunities for enhancements: 

1. Restrict direct traffic to Container Apps, Azure Function, and APIM (e.g. using a VNet)
2. Add WAF in front of the UI
3. Add throttling policies to APIM APIs
4. Add subscriptions, products, and authentication scenarios

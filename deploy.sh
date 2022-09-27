#! /bin/bash

while getopts n:l:c: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LOCATION=${OPTARG};;
        c) CODE=${OPTARG};;
    esac
done

if [ "$NAME" == "" ] || [ "$LOCATION" == "" ] || [ "$CODE" == "" ]; then
 echo "Syntax: $0 -n <name> -l <location> -c <unique code>"
 exit 1;
fi

SUFFIX=reddog-$CODE
REGISTRY=acrreddog$CODE

# provision infrastructure
az deployment sub create --location $LOCATION --template-file ./infra/main.bicep --parameters name=$NAME --parameters location=$LOCATION --parameters uniqueSuffix=$SUFFIX

REGISTRY_URL=https://${REGISTRY}.azurecr.io
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY --query username | xargs)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY --query passwords[0].value | xargs)

# build solution
cd ./src && dotnet restore && dotnet build && cd ../

# build accounting service
az acr build --image reddog/accounting-service:{{.Run.ID}} --image reddog/accounting-service:latest --registry $REGISTRY -f ./src/RedDog.AccountingService/Dockerfile ./src

# build bootstrapper
az acr build --image reddog/bootstrapper:{{.Run.ID}} --image reddog/bootstrapper:latest --registry $REGISTRY -f ./src/RedDog.Bootstrapper/Dockerfile ./src

# build corporate transfer service
az acr build --image reddog/corporate-transfer:{{.Run.ID}} --image reddog/corporate-transfer:latest --registry $REGISTRY ./src/RedDog.CorporateTransferService

# build loyalty service
az acr build --image reddog/loyalty-service:{{.Run.ID}} --image reddog/loyalty-service:latest --registry $REGISTRY -f ./src/RedDog.LoyaltyService/Dockerfile ./src

# build make line service
az acr build --image reddog/make-line:{{.Run.ID}} --image reddog/make-line:latest --registry $REGISTRY -f ./src/RedDog.MakeLineService/Dockerfile ./src

# build order service
az acr build --image reddog/order-service:{{.Run.ID}} --image reddog/order-service:latest --registry $REGISTRY -f ./src/RedDog.OrderService/Dockerfile ./src

# build receipt service
az acr build --image reddog/receipt-service:{{.Run.ID}} --image reddog/receipt-service:latest --registry $REGISTRY -f ./src/RedDog.ReceiptGenerationService/Dockerfile ./src

# build UI
az acr build --image reddog/ui:{{.Run.ID}} --image reddog/ui:latest --registry $REGISTRY ./src/RedDog.UI

# build virtual customer
az acr build --image reddog/virtual-customer:{{.Run.ID}} --image reddog/virtual-customer:latest --registry $REGISTRY ./src/RedDog.VirtualCustomer

# build virtual worker
az acr build --image reddog/virtual-worker:{{.Run.ID}} --image reddog/virtual-worker:latest --registry $REGISTRY -f ./src/RedDog.VirtualWorker/Dockerfile ./src

# deploy accounting service image
az containerapp up --name accounting-service --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/accounting-service:latest

# deploy bootstrapper image
az containerapp up --name bootstrapper --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/bootstrapper:latest

# deploy corporate transfer service image
az containerapp up --name corporate-transfer --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/corporate-transfer:latest

# deploy loyalty service image
az containerapp up --name loyalty-service --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/loyalty-service:latest

# deploy makeline service image
az containerapp up --name make-line-service --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/make-line:latest

# deploy order service image
az containerapp up --name order-service --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/order-service:latest

# deploy receipt service image
az containerapp up --name receipt-service --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/receipt-service:latest

# deploy UI image
az webapp config container set --name ui-${SUFFIX} --resource-group ${NAME}-${SUFFIX} --docker-custom-image-name ${REGISTRY}.azurecr.io/reddog/ui:latest --docker-registry-server-url $REGISTRY_URL --docker-registry-server-user $REGISTRY_USERNAME --docker-registry-server-password $REGISTRY_PASSWORD

# deploy Virtual Customer image
az functionapp config container set --name vc-${SUFFIX} --resource-group ${NAME}-${SUFFIX} --docker-custom-image-name ${REGISTRY}.azurecr.io/reddog/virtual-customer:latest --docker-registry-server-url $REGISTRY_URL --docker-registry-server-user $REGISTRY_USERNAME --docker-registry-server-password $REGISTRY_PASSWORD

# deploy virtual worker image
az containerapp up --name virtual-worker --resource-group ${NAME}-${SUFFIX} --image ${REGISTRY}.azurecr.io/reddog/virtual-worker:latest 

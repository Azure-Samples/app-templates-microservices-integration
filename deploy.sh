#! /bin/sh
$NAME=dev
$LOCATION=eastus2
$CODE=6a034c03
$SUFFIX=reddog-$CODE
$REGISTRY=acrreddog$CODE

# deploy infrastructure
az deployment sub create --location $LOCATION --template-file ./infra/main.bicep --parameters name=$NAME --parameters location=$LOCATION --parameters uniqueSuffix=$SUFFIX

# build solution
cd ./src && dotnet restore && dotnet build && cd ../

# build accounting service
az acr build --image reddog/accounting-service:{{.Run.ID}} --image reddog/accounting-service:latest --registry $REGISTRY -f ./src/RedDog.AccountingService/Dockerfile ./src

# build bootstrapper
az acr build --image reddog/bootstrapper:{{.Run.ID}} --image reddog/bootstrapper:latest --registry $REGISTRY -f ./src/RedDog.Bootstrapper/Dockerfile ./src

# build corporate transfer service
az acr build --image reddog/corporate-transfer:{{.Run.ID}} --image reddog/corporate-transfer:latest --registry $REGISTRY ./src/RedDog.CorporateTransferService

# build loyalty service
az acr build --image reddog/loyalty:{{.Run.ID}} --image reddog/loyalty:latest --registry $REGISTRY -f ./src/RedDog.LoyaltyService/Dockerfile ./src

# build make line service
az acr build --image reddog/makeline:{{.Run.ID}} --image reddog/makeline:latest --registry $REGISTRY -f ./src/RedDog.MakeLineService/Dockerfile ./src

# build order service
az acr build --image reddog/order:{{.Run.ID}} --image reddog/order:latest --registry $REGISTRY -f ./src/RedDog.OrderService/Dockerfile ./src

# build receipt service
az acr build --image reddog/order:{{.Run.ID}} --image reddog/order:latest --registry $REGISTRY -f ./src/RedDog.ReceiptGenerationService/Dockerfile ./src

# build UI
az acr build --image reddog/ui:{{.Run.ID}} --image reddog/ui:latest --registry $REGISTRY ./src/RedDog.UI

# build virtual customer
az acr build --image reddog/virtual-customer:{{.Run.ID}} --image reddog/virtual-customer:latest --registry $REGISTRY ./src/RedDog.VirtualCustomer

# build virtual worker
az acr build --image reddog/virtual-worker:{{.Run.ID}} --image reddog/virtual-worker:latest --registry $REGISTRY -f ./src/RedDog.ReceiptGenerationService/Dockerfile ./src

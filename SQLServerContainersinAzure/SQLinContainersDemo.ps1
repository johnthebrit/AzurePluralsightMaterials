docker pull ubuntu:latest

docker images

docker run ubuntu echo "hello world"

#See running containers
docker ps

#See all containers
docker ps -a

#Run interactively (could also -d for it to be detached)
docker run -it ubuntu bash

#Have a name
docker run --name UbuntuContainer -it ubuntu bash

#Remove containers
docker rm 8f3fedfa3bca c3b6ecb22b27

#Remove all not running on Linux
docker rm $(docker ps -a -q -f status=exited)
#On PowerShell
docker rm @(docker ps -a -q -f status=exited)

#Start existing
docker ps -a
$ContainerID = 0d4fa9716124
docker start $ContainerID
docker exec $ContainerID echo "hello john"
docker exec -it $ContainerID bash
docker stop $ContainerID



#Kubernetes on Docker Desktop Demo

kubectl get services
kubectl get nodes

kubectl create namespace k8s-demo
kubectl apply -f pod.yaml --namespace=k8s-demo

kubectl get pod --namespace=k8s-demo
kubectl describe pod <pod> --namespace=k8s-demo
docker ps -a
kubectl get pod container1 --output=yaml --namespace=k8s-demo
docker stop fd510b9df468
docker rm fd510b9df468
kubectl get pod --namespace=k8s-demo #its still there
docker ps -a #Note the age
docker exec <pod> uname -a
docker exec -it <pod> bash
kubectl delete pod container1 --namespace=k8s-demo
#stays gone since is just an object. if node died would also just be gone

#Whole deployment
kubectl apply -f deployment.yaml --namespace=k8s-demo
kubectl get pod --namespace=k8s-demo
kubectl get all --namespace=k8s-demo -o wide
kubectl get all --all-namespaces -o wide

#We don't want to focus on pods and instead abstract with a service
kubectl apply -f service.yaml --namespace=k8s-demo
kubectl get svc --namespace=k8s-demo
#As its NodePort can go to the port allocated for 127.0.0.1

#Test the resiliency
kubectl delete pod webapp1-deployment-559f75f58b-d4bpr --namespace=k8s-demo
kubectl get pod --namespace=k8s-demo  #deployment gets it running again!
docker ps -a

#Cleanup
kubectl delete service webapp1-service --namespace=k8s-demo
kubectl delete deployment webapp1-deployment --namespace=k8s-demo



#SQL Server
docker pull mcr.microsoft.com/mssql/server
docker images
docker history mcr.microsoft.com/mssql/server

#Run SQL Server locally
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=V3ryStr0ngPa55!" `
   -p 1433:1433 --name mySqlContainer `
   -d mcr.microsoft.com/mssql/server

docker ps

#Azure Data Studio can connect locally to 1433 which will map to the container as we map 1433 to 1433
SELECT @@SERVERNAME, @@VERSION

docker stop mySqlContainer
docker ps -a
docker rm mySqlContainer

#Map to a local volume to persist data past container lifetime
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=V3ryStr0ngPa55!" `
   -p 1433:1433 --name mySqlContainer `
   -v sqldata1:/var/opt/mssql `
   -d mcr.microsoft.com/mssql/server

#View our new volume
docker volume ls

#View the paths
SELECT
SERVERPROPERTY('InstanceDefaultDataPath') AS InstanceDefaultDataPath,
SERVERPROPERTY('InstanceDefaultLogPath') AS InstanceDefaultLogPath

docker stop mySqlContainer
docker rm mySqlContainer


#ACI Demo SQL deploy
#We are not using persistent storage. If we wanted we would hook into Azure Files
az group create --name RG-Containers --location southcentralus

#Deploying to vnet for easy integration
az network vnet show --resource-group RG-Infra-SCUS --name VNet-Infra-SCUS
#Subnet is delegated to Microsoft.ContainerInstance/containerGroups

az container create \
   --resource-group RG-Containers --name sqlcontainer \
   --image mcr.microsoft.com/mssql/server --cpu 2 --memory 4 \
   --vnet <RESID> \
   --subnet <RESID> \
   --ports 1433 \
   --e ACCEPT_EULA=Y SA_PASSWORD=V3ryStr0ngPa55!
#Note there are other environment variables, for example starting the SQL Server agent (MSSQL_AGENT_ENABLED=true) is common in addition to specifying a product version
#https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-environment-variables?view=sql-server-2017
#Note likely would want to map a file share for durable storage, i.e. Azure Files
#https://docs.microsoft.com/en-us/azure/container-instances/container-instances-volume-azure-files
#    --azure-file-volume-account-name $ACI_PERS_STORAGE_ACCOUNT_NAME \
#    --azure-file-volume-account-key $STORAGE_KEY \
#    --azure-file-volume-share-name $ACI_PERS_SHARE_NAME \
#    --azure-file-volume-mount-path /var/opt/mssql

az container show --resource-group RG-Containers --name sqlcontainer \
   --query "{FQDN:ipAddress.fqdn,IP:ipAddress.ip,ProvisioningState:provisioningState}" \
   --out table

#Should now be able to connect via the IP from something on vnet. as existing use full resource ID via az network vnet show
#https://docs.microsoft.com/en-us/azure/container-instances/container-instances-vnet
# Could give it public IP directly and connect but not common with SQL Server!
# --dns-name-label savsqlcontainer --ip-address public

az container logs --resource-group RG-Containers --name sqlcontainer

az container delete --resource-group RG-Containers --name sqlcontainer
az container list --resource-group RG-Containers --output table



#AKS SQL Deploy

#View the subnet IDs as deploying to existing network (advanced, Azure CNI)
#https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni
az network vnet subnet list \
    --resource-group RG-SCUSA \
    --vnet-name VNet-Infra-SCUS \
    --query [].id --output tsv

#Deploy the AKS Cluster
#https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster
#https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal
#Will use auto generated service principal but could be created manually first
#az ad sp AKSPrincipal --skip-assignment
#Used below with the --service-principal and --client-secret parameters from output of above
#Can see a principal created in AAD for the name of the cluster (show AAD - enterprise applications - AKS)
az aks create \
    --resource-group RG-AKS \
    --name AKSDemoCluster \
    --node-count 2 \
    --network-plugin azure \
    --vnet-subnet-id <RESID> \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 172.16.0.10 \
    --service-cidr 172.16.0.0/16 \
    --generate-ssh-keys
#Show the VNet and all the nodepool NICs created based on number of nodes and max pods (30 default) in Overview
#Show the users for the subnet and note the service principal given Network Contributor rights

#Get credentials for the AKS cluster
az aks get-credentials --resource-group RG-AKS --name AKSDemoCluster

#View the nodes
kubectl get nodes

#View the storage providers available
#https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv
kubectl get sc

#View the Kubernetes portal
#First get the permissions right by default very minimal so we'll increase them
kubectl describe role kubernetes-dashboard-minimal -n kube-system
kubectl create clusterrolebinding kubernetes-dashboard \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:kubernetes-dashboard

#Get a tunnel to the portal
az aks browse --resource-group RG-AKS --name AKSDemoCluster

#Deploy the SQL instance
#https://docs.microsoft.com/en-us/sql/linux/tutorial-sql-server-containers-kubernetes?view=sql-server-2017

#Create a secret for the SA password
kubectl create secret generic mssql --from-literal=SA_PASSWORD="V3ryStr0ngPa55!"

#Storage and PVC first
kubectl apply -f AKSStorageProviderandPVC.yaml

#View the PVC
kubectl describe pvc mssql-data
#View the PVs which is dynamically created from the PVC via the storage provider
kubectl describe pv

#Deploy the SQL instance
kubectl apply -f AKSSQLServerDeployment.yaml

#View the SQL assets
kubectl get pod
kubectl get services

#View all the components deployed
az aks browse --resource-group RG-AKS --name AKSDemoCluster

#If wanted to interact
kubectl exec -it mssql-deployment-? bash

#Can now connect using standard tools including Azure Data Studio and can use sqlcmd for ease
sqlcmd -S IPADDRESSHERE -U sa -P "V3ryStr0ngPa55!"

#create a database
CREATE DATABASE TestDB
SELECT Name from sys.Databases

#Test the AKS Kubernetes deployment is doing its job!!!
kubectl get pods
kubectl delete pod mssql-deployment-?
kubectl get pods #its back!
kubectl get services   #same IP!

#Database still there if check!
SELECT Name from sys.Databases

#Clean up
kubectl delete -f AKSSQLServerDeployment.yaml
kubectl delete -f AKSStorageProviderandPVC.yaml
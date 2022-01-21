#!/bin/bash

unset clustername
unset resourcegroup
unset nodecount
unset nodevmsize
unset tmcattachurl

helpFunction()
{
    printf "\nYou must provide required parameters:\n\n"
    echo "Usage: $0"
    echo -e "\t-n | --name name of cluster (required)"
    echo -e "\t-g | --group name of resource group (required)"
    echo -e "\t-c | --node-count node count number (optional, default: 3)"
    echo -e "\t-s | --node-vm-size node vm size (optional, default: Standard_DS2_v2)"
    echo -e "\t-l | --tmc-attach-url link url of tmc attach url (either --tmc-attach-url or --tmc-cluster-group is required)"
    echo -e "\t-t | --tmc-cluster-group tmc cluster group name (either --tmc-attach-url or --tmc-cluster-group is required)"
}

source ~/binaries/readparams.sh


if [[ -z $clustername || -z $resourcegroup ]]
then
    printf "\n\nError: One or more required parameter(s) missing!\n"
    helpFunction
    printf "\n\nExiting...\n"
    exit 1 # Exit script after printing help
else 
    if [[ -z $tmcattachurl && -z $tmcclustergroup ]]
    then
        printf "\n\nError: One or more required parameter(s) missing..\n"
        helpFunction
        printf "\n\nExiting...\n"
        exit 1 # Exit script after printing help
    else
        printf "\n\ncrearing using... clustername=$clustername | resourcegroup=$resourcegroup | nodecount=$nodecount | nodevmsize=$nodevmsize"
        if [[ ! -z $tmcattachurl ]]
        then
            printf " | tmcattachurl=$tmcattachurl\n"
        else
            printf " | tmcclustergroup=$tmcclustergroup\n"
        fi        
    fi    
fi

printf "\n\n"

while true; do
    read -p "Confirm to proceed further? [y/n] " yn
    case $yn in
        [Yy]* ) printf "\nYou confirmed yes.\n\nProceeding...\n"; break;;
        [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done

printf "\n\n"
printf "\n***************************************************"
printf "\n********** Creating... ****************************"
printf "\n***************************************************"

printf "\n\nCreating azure cluster using:\n"
if [ -z "$sshkeyvalue" ]
then
    printf " az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize\n"
    az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --generate-ssh-keys
else
    printf " az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize\n"
    az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --ssh-key-value $sshkeyvalue
fi
printf "\n\nDONE\n\n"

printf "\n\Getting cluster access using:\n az aks get-credentials --resource-group $resourcegroup --name $clustername\n"
az aks get-credentials --resource-group $resourcegroup --name $clustername
printf "\n\nDONE\n\n"

printf "\n\Switching context using:\n kubectl config use-context $clustername\n"
kubectl config use-context $clustername
printf "\n\nDONE\n\n"

ISTMCEXISTS=$(tmc --help)

if [[ ! -z $ISTMCEXISTS && ! -z $tmcclustergroup ]]
then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    source $SCRIPT_DIR/attach_to_tmc.sh -g $tmcclustergroup -n $clustername
else
    printf "\n\Attaching tmc using:\n kubectl apply -f $tmcattachurl\n"
    kubectl apply -f $tmcattachurl
    printf "\nAttached...\n"
    printf "\nWaiting 1 mins to complete cluster attach\n"
    sleep 1m
    printf "\n\nDONE.\n\n\n"
fi


printf "\n\n\nCOMPLETE\n\n\n"

# ISKUBECONFIGEXIST=$(ls ~/.kube/config | awk -v i=1 -v j=1 'FNR == i {print $j}')

# if [ -z "$ISKUBECONFIGEXIST" ]
# then
    
# else

# fi
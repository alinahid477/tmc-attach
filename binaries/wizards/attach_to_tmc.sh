#!/bin/bash

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/color-file.sh

export $(cat /root/.env | xargs)

helpFunction()
{
    printf "\n${redcolor}You must provide all parameters.${normalcolor}\n\n"
    echo "Usage: $0"
    echo -e "\t-n name of cluster"
    echo -e "\t-g name cluster group in tmc"
    returnOrexit || return 1 # Exit script after printing help
}

while getopts "g:n:" opt
do
    case $opt in
        g ) TMC_CLUSTER_GROUP="$OPTARG" ;;
        n ) CLUSTER_NAME="$OPTARG";;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

if [ -z "$TMC_CLUSTER_GROUP" ] 
then
    printf "\n\n${redcolor}Error: No cluster group given. Exit...${normalcolor}\n"
    returnOrexit || return 1
fi

if [ -z "$CLUSTER_NAME" ]
then
    printf "\n\n${redcolor}Error: No cluster name given. Exit...${normalcolor}\n"
    returnOrexit || return 1
fi

printf "\n\nChecking cluster...\n"
caniswitchcontext=$(kubectl config use-context $CLUSTER_NAME)
if [[ -z $caniswitchcontext ]]
then
    printf "\n\n${redcolor}Error: No k8s cluster exist. Exit...${normalcolor}\n\n"
    returnOrexit || return 1
    isclusterexist=$(kubectl get ns | grep kube-system | awk '{print $1}')
    if [ -z "$isclusterexist" ]
    then
        printf "\n\n${redcolor}Error: No k8s cluster exist. Exit...${normalcolor}\n\n"
        returnOrexit || return 1
    fi
fi


ISTMCEXISTS=$(tmc --help)
if [[ ! -z $ISTMCEXISTS && ! -z $TMC_CLUSTER_GROUP ]]
then
    printf "\nAttaching cluster to TMC\n"
    printf "\nChecking existing TMC context..."
    EXISTING_CONTEXT=$(tmc system context list | awk -v i=2 -v j=1 'FNR == i {print $j}')
    if [ -z "$EXISTING_CONTEXT" ]
    then
        if [ -z "$TMC_CONTEXT" ]
        then
            TMC_CONTEXT="$CLOUD-clusters"
        fi
        printf "\nNo existing context found. TMC Login using context \'$TMC_CONTEXT\'...\n"
        tmc login --name $TMC_CONTEXT --no-configure
    else
        printf "\nContext $EXISTING_CONTEXT found. Using the context...\n"
        tmc system context use $EXISTING_CONTEXT
    fi
    
    printf "\nTMC Attach..\n"
    epoc=$(date +%s) 
    tmc cluster attach --name $CLUSTER_NAME --cluster-group $TMC_CLUSTER_GROUP --output /tmp/attach-file-$epoc.yaml 
    kubectl config use-context $CLUSTER_NAME
    
    kubectl apply -f /tmp/attach-file-$epoc.yaml
    printf "\n${yellowcolor}Waiting 3 mins to complete cluster attach...${normalcolor}\n"
    sleep 3m
    printf "\nApplying patch to opening access for public cloud k8s..."
    kubectl patch credentialissuer cluster-auth-pinniped-config --type merge --patch-file binaries/templates/public-cloud-patch.yaml
    sleep 5
    printf "${greencolor}DONE.${normalcolor}"
    printf "\nDeleting cluster-auth-pinniped-impersonation-proxy-load-balancer for pinniped restart..."
    kubectl delete services -n vmware-system-tmc cluster-auth-pinniped-impersonation-proxy-load-balancer
    sleep 5
    printf "${greencolor}DONE.${normalcolor}"
    printf "\nGetting pinniped to endpoint...\n"
    kubectl get services -n vmware-system-tmc
    printf "\n\n${greencolor}DONE.${normalcolor}\n\n\n"
else
    printf "\n\ntmc command does not exist.\n\n"
    printf "\n\nChecking for binary presence...\n\n"
    IS_TMC_BINARY_EXISTS=$(ls ~/binaries/ | grep tmc)
    if [ -z "$IS_TMC_BINARY_EXISTS" ]
    then
        printf "\n\nBinary does not exist in ~/binaries directory.\nPlease download tmc binary and place in the ~/binaries directory.\n"
        printf "\nAfter you have placed the binary file you can, additionally, uncomment the tmc relevant in the Dockerfile.\n\n"
    else
        printf "\n\nTMC binary found...\n"
        printf "\n\nAdjusting Dockerfile\n"
        sed -i '/COPY binaries\/tmc \/usr\/local\/bin\//s/^# //' ~/Dockerfile
        sed -i '/RUN chmod +x \/usr\/local\/bin\/tmc/s/^# //' ~/Dockerfile
        printf "\nDONE..\n"
        printf "\n\nPlease build this docker container again and run.\n"
    fi

    printf "\n\nOnce you have completed the necessary steps above you can run the below command to attach cluster:\n"
    printf "~/binaries/attach_to_tmc.sh -g $TMC_CLUSTER_GROUP -n $CLUSTER_NAME"
    printf "\n\n"
fi
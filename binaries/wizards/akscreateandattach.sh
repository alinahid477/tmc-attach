#!/bin/bash

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/color-file.sh


function helpFunction()
{
    printf "\n${yellowcolor}You must provide required parameters:${normalcolor}\n\n"
    echo "Usage: $0"
    echo -e "\t-n | --name name of cluster (required)"
    echo -e "\t-g | --group name of resource group (required)"
    echo -e "\t-c | --node-count node count number (optional, default: 3)"
    echo -e "\t-s | --node-vm-size node vm size (optional)"
    echo -e "\t-d | --node-osdisk-size node vm size (optional)"
    echo -e "\t-l | --tmc-attach-url link url of tmc attach url (either --tmc-attach-url or --tmc-cluster-group is required)"
    echo -e "\t-t | --tmc-cluster-group tmc cluster group name (either --tmc-attach-url or --tmc-cluster-group is required)"
}


unset clustername
unset resourcegroup
unset nodecount
unset nodevmsize
unset nodeosdisksize
unset tmcattachurl

source $HOME/binaries/wizards/readparams.sh


function doCreateAndAttachProcess () {
    if [[ -z $clustername || -z $resourcegroup ]]
    then
        printf "\n\n${redcolor}Error: One or more required parameter(s) missing!${normalcolor}\n"
        helpFunction
        printf "\n\nExiting...\n"
        returnOrexit || return 1 # Exit script after printing help
    else 
        if [[ -z $tmcattachurl && -z $tmcclustergroup ]]
        then
            printf "\n\n${redcolor}Error: One or more required parameter(s) missing..${normalcolor}\n"
            helpFunction
            printf "\n\nExiting...\n"
            returnOrexit || return 1 # Exit script after printing help
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
            [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; returnOrexit || return 1;;
            * ) printf "${redcolor}Please answer yes or no.${normalcolor}\n";;
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
        if [[ -n $nodeosdisksize ]]
        then
            az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --node-osdisk-size $nodeosdisksize --generate-ssh-keys
        else
            az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --generate-ssh-keys
        fi
        
    else
        printf " az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize\n"
        if [[ -n $nodeosdisksize ]]
        then
            az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --node-osdisk-size $nodeosdisksize --ssh-key-value $sshkeyvalue
        else
            az aks create --resource-group $resourcegroup --name $clustername --node-count $nodecount --node-vm-size $nodevmsize --ssh-key-value $sshkeyvalue
        fi
        
    fi
    printf "\n\n${greencolor}DONE${normalcolor}\n\n"

    printf "\n${yellowcolor}Getting cluster access using:\n az aks get-credentials --resource-group $resourcegroup --name $clustername${normalcolor}\n"
    az aks get-credentials --resource-group $resourcegroup --name $clustername
    printf "\n\n${greencolor}DONE${normalcolor}\n\n"

    printf "\n${yellowcolor}Switching context using:\n kubectl config use-context $clustername ${normalcolor}\n"
    kubectl config use-context $clustername
    printf "\n\n${greencolor}DONE${normalcolor}\n\n"


    if [[ -n $tmcclustergroup && $tmcclustergroup == 'notmc' ]]
    then
        printf "\n${yellocolor}No attach to tmc needed as instructed via notmc${normalcolor}\n"
    else
        ISTMCEXISTS=$(tmc --help)

        if [[ ! -z $ISTMCEXISTS && ! -z $tmcclustergroup ]]
        then
            SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
            source $SCRIPT_DIR/attach_to_tmc.sh -g $tmcclustergroup -n $clustername
        else
            printf "\n\Attaching tmc using:\n kubectl apply -f $tmcattachurl\n"
            kubectl apply -f $tmcattachurl
            printf "\n${greencolor}Attached...${normalcolor}\n"
            printf "\nWaiting 1 mins to complete cluster attach\n"
            sleep 1m
            printf "\n\n${greencolor}DONE.${normalcolor}\n\n\n"
        fi
    fi


    printf "\n\n\n${greencolor}COMPLETE${normalcolor}\n\n\n"

    # ISKUBECONFIGEXIST=$(ls ~/.kube/config | awk -v i=1 -v j=1 'FNR == i {print $j}')

    # if [ -z "$ISKUBECONFIGEXIST" ]
    # then
        
    # else

    # fi


}


doCreateAndAttachProcess
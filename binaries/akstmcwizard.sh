#!/bin/bash

export $(cat /root/.env | xargs)

printf "\n\n"
printf "\n***************************************************"
printf "\n********** Starting *******************************"
printf "\n***************************************************"

printf "\n\nCheccking if logged in\n\n"


ISAZLOGGEDIN=$(az account show | grep name)

if [ -z "$ISAZLOGGEDIN" ]
then
    printf "\n\nlogin to az\n\n"
    if [ -z "$AZ_TENANT_ID" ] || [ -z "$AZ_TKG_APP_ID" ] || [ -z "$AZ_TKG_APP_ID" ]
    then
        printf "\n\naz login\n\n"
        az login
    else
        printf "\n\naz login --service-principal --username $AZ_TKG_APP_ID --password $AZ_TKG_APP_CLIENT_SECRET --tenant $AZ_TENANT_ID\n\n"
        az login --service-principal --username $AZ_TKG_APP_ID --password $AZ_TKG_APP_CLIENT_SECRET --tenant $AZ_TENANT_ID
    fi
    printf "\n\nLogged with below details\n"
    az account show
    printf "\nProceeding with wizard...\n"
else
    printf "\n\nAlready logged with below details\n"
    az account show
    printf "\nProceeding with wizard...\n"
fi

source ~/binaries/readparams.sh

if [[ -z $clustername || -z $resourcegroup ]]
then
    printf "\n\nPlease provide input for aks and tmc attach\n\n"


    while [ -z "$inp" ]; do
        read -p "Name: " inp
        if [ -z "$inp" ]
        then
            printf "\nthis is a required field. you must provide a name.\n"
        else 
            clustername=$inp
        fi
    done

    printf "\n\n"
    unset inp;


    while [ -z "$inp" ]; do
        read -p "Resource group name: " inp
        if [ -z "$inp" ]
        then
            printf "\nthis is a required field. you must provide a resource group name.\n"
        else 
            resourcegroup=$inp
        fi
    done

    printf "\n\n"
    unset inp;

    while [ -z "$inp" ]; do
        read -p "node count:(press enter to keep default value '3') " inp
        if [ -z "$inp" ]
        then
            nodecount=3
            inp=$nodecount
        else 
            nodecount=$inp
        fi
    done

    printf "\n\n"
    unset inp;

    while [ -z "$inp" ]; do
        read -p "node vm size:(press enter to keep default value 'Standard_DS2_v2') " inp
        if [ -z "$inp" ]
        then
            nodevmsize=Standard_DS2_v2
            inp=$nodevmsize
        else 
            nodevmsize=$inp
        fi
    done

    printf "\n\n"
    unset inp;

    read -p "ssh pub file path:(press enter to generate a new one on the fly) " inp
    if [[ ! -z $inp ]]
    then
        sshkeyvalue=$inp           
        echo "here....."
    fi

    printf "\n\n"
    unset inp;
fi

if [[ -z $tmcattachurl && -z $tmcclustergroup ]]
then
    while [ -z "$inp" ]; do
        read -p "tmc attach url OR cluster group name (either of one is required): " inp
        if [ -z "$inp" ]
        then
            printf "\nthis is a required field. you must provide a attach url.\n"
        else 
            if [[ ! -z "$inp" ]]
            then
                if [[ $inp == *"https:"* ]]
                then
                    tmcattachurl=$inp
                else
                    tmcclustergroup=$inp
                fi
            fi
        fi
    done

    printf "\n\n"
    unset inp;
fi

if [[ ! -z $tmcattachurl ]]
then
    source ~/binaries/akscreateandattach.sh -g $resourcegroup -n $clustername  -c $nodecount -s $nodevmsize --tmc-attach-url $tmcattachurl
else
    source ~/binaries/akscreateandattach.sh -g $resourcegroup -n $clustername  -c $nodecount -s $nodevmsize --tmc-cluster-group $tmcclustergroup
fi
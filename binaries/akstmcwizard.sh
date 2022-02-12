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

    # when present is .env file take the value from there else set a default value here
    if [[ -z $DEFAULT_VM_SIZE ]]
    then
        DEFAULT_VM_SIZE=Standard_DS2_v2
    fi

    printf "\n\n"
    unset inp;

    while [ -z "$inp" ]; do
        read -p "node vm size:(press enter to keep default value '$DEFAULT_VM_SIZE') " inp
        if [ -z "$inp" ]
        then
            nodevmsize=$DEFAULT_VM_SIZE
            inp=$nodevmsize
        else 
            nodevmsize=$inp
        fi
    done


    printf "\n\n"
    unset inp;
    while true; do
        read -p "node osdisk size:(press enter) " inp
        if [[ -n $inp ]]
        then
            nodeosdisksize=$inp
        fi
    done

    printf "\n\n"
    unset inp;

    unset idrsapublickeyfile
    isidrsaexists=$(ls -l /root/.ssh/id_rsa.pub)
    if [[ -n $isidrsaexists ]]
    then
        idrsapublickeyfile='/root/.ssh/id_rsa.pub'
        dialog=$(echo "OR accept default: $idrsapublickeyfile")
    fi
    read -p "ssh pub file path:(press enter to generate a new one $dialog ) " inp
    if [[ -z $inp ]]
    then
        if [[ -n $idrsapublickeyfile ]]
        then
            echo "Default file selected: $idrsapublickeyfile"
            sshkeyvalue=$idrsapublickeyfile
        fi
    else
        sshkeyvalue=$inp
        echo "User input selected: $inp"
    fi

    printf "\n\n"
    unset inp;
fi

if [[ -z $tmcattachurl && -z $tmcclustergroup ]]
then
    while [ -z "$inp" ]; do
        read -p "tmc attach url OR cluster group name (required. Alternatively mention 'notmc' to avoid attach): " inp
        if [ -z "$inp" ]
        then
            printf "\nthis is a required field. you must provide a value.\n"
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
    source ~/binaries/akscreateandattach.sh -g $resourcegroup -n $clustername  -c $nodecount -s $nodevmsize -d $nodeosdisksize --tmc-attach-url $tmcattachurl
else
    source ~/binaries/akscreateandattach.sh -g $resourcegroup -n $clustername  -c $nodecount -s $nodevmsize -d $nodeosdisksize --tmc-cluster-group $tmcclustergroup
fi
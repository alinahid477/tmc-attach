#!/bin/bash

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/color-file.sh

function helpFunction()
{
    printf "\n"
    echo "Usage:"
    echo -e "\t-a | --aks no value needed. Signals the wizard to start the process for creating aks and attaching it to tmc."
    echo -e "\t-e | --eks no value needed. Signals the wizard to start the process for creating eks and attaching it to tmc"
    echo -e "\t-h | --help"
    printf "\n"
}


unset akstmc
unset ekstmc

# read the options
TEMP=`getopt -o aeh --long aks,eks,help -n $0 -- "$@"`
eval set -- "$TEMP"
# echo $TEMP;
while true ; do
    # echo "here -- $1"
    case "$1" in
        -a | --aks )
            case "$2" in
                "" ) akstmc='y';  shift 2 ;;
                * ) akstmc='y' ;  shift 1 ;;
            esac ;;
        -e | --eks )
            case "$2" in
                "" ) ekstmc='y'; shift 2 ;;
                * ) ekstmc='y' ; shift 1 ;;
            esac ;;
        -h | --help ) helpFunction; break;; 
        -- ) shift; break;; 
        * ) break;;
    esac
done

if [[ $akstmc == 'y' ]]
then
    source $HOME/binaries/wizards/akstmcwizard.sh
fi

if [[ $ekstmc == 'y' ]]
then
    printf "\n\nWIP\n\n"
    # source $HOME/binaries/wizards/ekstmcwizard.sh
fi


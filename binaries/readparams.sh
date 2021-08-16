#!/bin/bash

# read the options
TEMP=`getopt -o n:g:c:s:l:t: --long name:,resource-group:,node-count:,node-vm-size:,tmc-attach-url:,tmc-cluster-group: -n $0 -- "$@"`
eval set -- "$TEMP"
# echo $TEMP;
while true ; do
    case "$1" in
        -n | --name )
            case "$2" in
                "" ) clustername='' ; shift 2 ;;
                * ) clustername=$2 ; shift 2 ;;
            esac ;;
        -g | --resource-group )
            case "$2" in
                "" ) resourcegroup='' ; shift 2 ;;
                * ) resourcegroup=$2 ; shift 2 ;;
            esac ;;
        -c | --node-count )
            case "$2" in
                "" ) nodecount=3; shift 2 ;;
                * ) nodecount=$2 ; shift 2 ;;
            esac ;;
        -s | --node-vm-size )
            case "$2" in
                "" ) nodevmsize='Standard_DS2_v2'; shift 2 ;;
                * ) nodevmsize=$2 ; shift 2 ;;
            esac ;;
        -l | --tmc-attach-url )
            case "$2" in
                "" ) tmcattachurl=''; shift 2 ;;
                * ) tmcattachurl=$2 ; shift 2 ;;
            esac ;;
        -t | --tmc-cluster-group )
            case "$2" in
                "" ) tmcclustergroup=''; shift 2 ;;
                * ) tmcclustergroup=$2 ; shift 2 ;;
            esac ;;
        -- ) shift ; break ;;
        # * ) helpFunction ; exit 1 ;;
    esac
done
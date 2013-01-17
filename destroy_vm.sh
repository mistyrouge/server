#!/bin/bash

usage(){
cat << EOF
usage : $0 NAME

Destroy the virtual machine and remove all related data.
EOF
}

NAME="$1"
CONFIG_PATH="/home/dorian/vm_config"
VG="optiplex"
CUR_STATE=1
TOT_STATE=3

if [ $NAME ]
then
    # nothing
else
    usage
    exit 1
fi

function next(){
    let CUR_STATE=$CUR_STATE+1
    if [ $1 != 0 ]; then exit 1; fi
}

echo "$CUR_STATE/$TOT_STATE - Shuting down the VM"
xm shutdown $NAME
[ 1 ] # set the return code to 0
next $?

echo "$CUR_STATE/$TOT_STATE - Destroying the VM's data"
lvremove -f /dev/$VG/$NAME
next $?

echo "$CUR_STATE/$TOT_STATE - Destroy VM definition"
rm $CONFIG_PATH/$NAME.cfg
next $?

echo "--- The END ---"
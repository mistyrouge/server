#!/bin/bash

usage(){
cat << EOF
usage : $0 -n NAME -s SIZE

OPTIONS:
	-n	name of the new virtual machine
	-s	size of the / partition on the new virtual machine (>=2G)
	-h	print this help
EOF
}

NAME="undefined"
SIZE="undefined"
CONFIG_PATH="/home/dorian/vm_config"
TOTAL_STATE="8"
while getopts “hn:s:” OPTION
do
	case $OPTION in
         h)
             usage
             exit 1
             ;;
         n)
             NAME=$OPTARG
             ;;
         s)
             SIZE=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

case "undefined" in
	$NAME)
		echo "You need a name for the new VM"
		exit 1;
		;;
	$SIZE)
		echo "You need a size for the new VM"
		exit 1;
		;;
esac;


# creating new VM disks
echo "1/$TOTAL_STATE - Creating new logical volumes for the VM"
lvcreatme -L $SIZE -n $NAME optiplex
if [ $? != 0 ]; then exit $?; fi
lvcreate -L 4G -n $NAME-virt optiplex

# copying operating system data form template
echo "2/$TOTAL_STATE - Copying operating system files. This may take some times."
dd bs=4M if="/dev/optiplex/template-virt" of="/dev/optiplex/$NAME-virt"
dd bs=4M if="/dev/optiplex/template" of="/dev/optiplex/$NAME"

# resizing the / partition to fit hte disk
echo "3/$TOTAL_STATE - Fixing partition size"
e2fsck -f /dev/optiplex/$NAME
resize2fs /dev/optiplex/$NAME

# mount the new filesystem to apply some changes
echo "4/$TOTAL_STATE - Opening new VM's filesystem"
TEMP=`mktemp -d`
mount /dev/optiplex/$NAME $TEMP

# Update the new VM's hostname
echo "5/$TOTAL_STATE - Updating hostname information"
sed -i 's/template/$NAME/' $TEMP/etc/hostname
sed -i 's/template/$NAME/' $TEMP/etc/hosts

# unmount the filesystem and remove temp directory
echo "6/$TOTAL_STATE - Unmounting new filesystem"
umount $TEMP
rm -r $TEMP

# creating configuration file
echo "7/$TOTAL_STATE - Creating new configuration file"
cp -a $CONFIG_PATH/template.cfg.example $CONFIG_PATH/$NAME.cfg
sed -i 's/template/$NAME/' $CONFIG_PATH/$NAME.cfg

#starting the new VM
echo "8/$TOTAL_STATE - Starting new VM"
xm create $CONFIG_PATH/$NAME.cfg

echo "--- THE END ---"
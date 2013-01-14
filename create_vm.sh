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
TOT_STATE=14
CUR_STATE=1
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


echo "$CUR_STATE/$TOT_STATE - Creating a new logical volume for the VM"
lvcreate -L $SIZE -n $NAME optiplex
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Creating a partition table on the new LV"
parted /dev/optiplex/$NAME mktable msdos
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Creating a swap partition"
parted /dev/optiplex/$NAME mkpartfs primary linux-swap 1 4G
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Creating a ext4 partition for /"
parted /dev/optiplex/$NAME mkpartfs primary ext2 4G 100%
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Open LV"
kpartx -a /dev/optiplex/template
kpartx -a /dev/optiplex/$NAME
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Import template / into the new /"
dd bs=4M if=/dev/mapper/optiplex-template2 of="/dev/mapper/optiplex-"$NAME"2"
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Fixing new / filesystem"
e2fsck -fy "/dev/mapper/optiplex-"$NAME"2"
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Growing new / filesystem"
resize2fs "/dev/mapper/optiplex-"$NAME"2"
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Mounting new filesystem"
TEMP=`mktemp -d`
mount "/dev/mapper/optiplex-"$NAME"2" $TEMP
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Updating hostname information"
sed -i 's/template/'$NAME'/' $TEMP/etc/hostname
sed -i 's/template/'$NAME'/' $TEMP/etc/hosts
sed -i 's/template/'$NAME'/' $TEMP/etc/hosts
# did it twice because template appear twice on a single line
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Unmounting new filesystem"
umount $TEMP
rm -r $TEMP
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Close LV"
kpartx -d /dev/optiplex/template
kpartx -d /dev/optiplex/$NAME
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Creating new configuration file"
echo "" > $CONFIG_PATH/$NAME.cfg
cat >> $CONFIG_PATH/$NAME.cfg << EOF
name = "$NAME"
memory = 256
disk = ["phy:/dev/optiplex/$NAME,xvda,w"]
vif = [" "]
bootloader = "pygrub"
EOF
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "$CUR_STATE/$TOT_STATE - Starting the new VM"
xm create $CONFIG_PATH/$NAME.cfg
                                                                                let CUR_STATE=$CUR_STATE+1
                                                                                if [ $? != 0 ]; then exit 1; fi

echo "--- The END ---"
#!/bin/bash

usage(){
cat << EOF
usage : $0 -n NAME -s SIZE [-h] [-v VOLUME_GROUP]

OPTIONS:
	-n	name of the new virtual machine
	-s	size of the / partition on the new virtual machine (>=2G)
	-h	print this help
    -v  LVM Volume group to use
EOF
}

NAME="undefined"
SIZE="undefined"
CONFIG_PATH="/home/dorian/vm_config"
VG="optiplex"
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
         v)
             VG=$OPTARG
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

next(STATUS){
    let CUR_STATE=$CUR_STATE+1
    if [ $STATUS != 0 ]; then exit 1; fi
}

echo "$CUR_STATE/$TOT_STATE - Creating a new logical volume for the VM"
lvcreate -L $SIZE -n $NAME $VG
next($?)

echo "$CUR_STATE/$TOT_STATE - Creating a partition table on the new LV"
parted /dev/$VG/$NAME mktable msdos
next($?)

echo "$CUR_STATE/$TOT_STATE - Creating a swap partition"
parted /dev/$VG/$NAME mkpartfs primary linux-swap 1 4G
next($?)

echo "$CUR_STATE/$TOT_STATE - Creating a ext4 partition for /"
parted /dev/$VG/$NAME mkpartfs primary ext2 4G 100%
next($?)

echo "$CUR_STATE/$TOT_STATE - Open LV"
kpartx -a /dev/$VG/template
kpartx -a /dev/$VG/$NAME
next($?)

echo "$CUR_STATE/$TOT_STATE - Import template / into the new /"
dd bs=4M if="/dev/mapper/"$VG"-template2" of="/dev/mapper/"$VG"-"$NAME"2"
next($?)

echo "$CUR_STATE/$TOT_STATE - Fixing new / filesystem"
e2fsck -fy "/dev/mapper/"$VG"-"$NAME"2"
next($?)

echo "$CUR_STATE/$TOT_STATE - Growing new / filesystem"
resize2fs "/dev/mapper/"$VG"-"$NAME"2"
next($?)

echo "$CUR_STATE/$TOT_STATE - Mounting new filesystem"
TEMP=`mktemp -d`
mount "/dev/mapper/"$VG"-"$NAME"2" $TEMP
next($?)

echo "$CUR_STATE/$TOT_STATE - Updating hostname information"
sed -i 's/template/'$NAME'/' $TEMP/etc/hostname
sed -i 's/template/'$NAME'/' $TEMP/etc/hosts
sed -i 's/template/'$NAME'/' $TEMP/etc/hosts
# did it twice because template appear twice on a single line
next($?)

echo "$CUR_STATE/$TOT_STATE - Unmounting new filesystem"
umount $TEMP
rm -r $TEMP
next($?)

echo "$CUR_STATE/$TOT_STATE - Close LV"
kpartx -d /dev/$VG/template
kpartx -d /dev/$VG/$NAME
next($?)

echo "$CUR_STATE/$TOT_STATE - Creating new configuration file"
echo "" > $CONFIG_PATH/$NAME.cfg
cat >> $CONFIG_PATH/$NAME.cfg << EOF
name = "$NAME"
memory = 256
disk = ["phy:/dev/$VG/$NAME,xvda,w"]
vif = [" "]
bootloader = "pygrub"
EOF
next($?)

echo "$CUR_STATE/$TOT_STATE - Starting the new VM"
xm create $CONFIG_PATH/$NAME.cfg
next($?)

echo "--- The END ---"
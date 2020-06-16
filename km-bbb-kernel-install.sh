#!/bin/sh

##############################################
############     READ This  ##################
# Run the below command, output of this script file is copied in to "km-bbb-kernel-build.log" file it is useful for further analysis.
# $ ./km-bbb-kernel-install.sh | tee km-bbb-kernel-install.log
##############################################

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
NC='\033[0m'              # No Color
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

BRedU='\033[4;31m'         # Underline

temp=$USER
echo "User Name:$temp"

check_mmc () {
        FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "Disk ${media}:" | awk '{print $2}')

        if [ "x${FDISK}" = "x${media}:" ] ; then
                echo ""
                echo "I see..."
                echo ""
                echo "lsblk:"
                lsblk | grep -v sr0
                echo ""
                unset response
                echo -n "Are you 100% sure, on selecting [${media}] (y/n)? "
                read response
                if [ "x${response}" != "xy" ] ; then
                        exit
                fi
                echo ""
        else
                echo ""
                echo "Are you sure? I Don't see [${media}], here is what I do see..."
                echo ""
                echo "lsblk:"
                lsblk | grep -v sr0
                echo ""
                echo "Permission Denied. Run with sudo"
                exit
        fi

}

unmount_all_drive_partitions () {
        echo ""
        echo "Unmounting Partitions"
        echo "-----------------------------"

        NUM_MOUNTS=$(mount | grep -v none | grep "${media}" | wc -l)

        for ((i=1;i<=${NUM_MOUNTS};i++))
        do
                DRIVE=$(mount | grep -v none | grep "${media}" | tail -1 | awk '{print $1}')
                umount ${DRIVE} >/dev/null 2>&1 || true
        done
}


if [ -z "$1" ]; then
	echo "usage: sudo $(basename $0) --mmc /dev/sdX --board "
fi


# parse commandline options
while [ ! -z "$1" ] ; do
        case $1 in
        -h|--help)
		echo "usage: sudo $(basename $0) --mmc /dev/sdX --board "
                ;;
	--mmc)
		media=$2
		check_mmc
		sudo mkdir -p /mnt/rootfs
	        sudo mount ${media}1 /mnt/rootfs

		echo "${Purple}cp out/${KERNEL_UTS}-zImage /mnt/rootfs/boot/vmlinuz-${KERNEL_UTS}${NC}"
		cp out/${KERNEL_UTS}-zImage /mnt/rootfs/boot/vmlinuz-${KERNEL_UTS}
		cp out/config-${KERNEL_UTS} /mnt/rootfs/boot/
		
		mkdir -p /mnt/rootfs/boot/dtbs/${KENREL_UTS}
		echo "${Purple}cp arch/arm/boot/dts/am335x-boneblack.dtb /mnt/roots/dtbs/${KERNEL_UTS} ${NC}"
		cp arch/arm/boot/dts/am335x-boneblack.dtb /mnt/roots/dtbs/${KERNEL_UTS}
		
		echo "${Purple} echo uname_r=${KERNEL_UTS} > /mnt/rootfs/boot/uEnv.txt ${NC}"
		echo uname_r=${KERNEL_UTS} > /mnt/rootfs/boot/uEnv.txt
                
		echo "${Purple} tar -xvf out/${KERNEL_UTS}-modules.tar.gz  -C /mnt/rootfs/ ${NC}"
                tar -xvf out/${KERNEL_UTS}-modules.tar.gz  -C /mnt/rootfs/
        
		sync
        	unmount_all_drive_partitions
		;;
        --board)
		echo "${Purple}cp out/${KERNEL_UTS}-zImage /media/board$2/vmlinuz-${KERNEL_UTS}${NC}"
		cp out/${KERNEL_UTS}-zImage /media/board$2/vmlinuz-${KERNEL_UTS}
		echo "${Purple}cp arch/arm/boot/dts/am335x-boneblack.dtb /meida/board$2/${NC}"
		cp arch/arm/boot/dts/am335x-boneblack.dtb /media/board$2/
		echo "${Purple} echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt ${NC}"
		echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt
		echo "${Purple} echo board_no=$2 >> /media/board$2/uEnv.txti${NC}"
		echo board_no=$2 >> /media/board$2/uEnv.txt
		#echo "${Purple}scp /home/$USER/out/vmlinuz-${KERNEL_UTS}  /home/$USER/out/${KERNEL_UTS}-modules.tar.gz /home/$USER/out/${KERNEL_UTS}-dtbs.tar.gz km@192.168.1.1$2:~/$NC"
                #scp /home/$USER/out/vmlinuz-${KERNEL_UTS}  /home/$USER/out/${KERNEL_UTS}-modules.tar.gz /home/$USER/out/${KERNEL_UTS}-dtbs.tar.gz km@192.168.1.1$2:~/
                ;;
        esac
        shift
done

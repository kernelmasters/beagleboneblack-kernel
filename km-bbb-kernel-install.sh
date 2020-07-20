#!/bin/bash  -e

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
clear
temp=$USER
echo "User Name:$temp"
 KERNEL_UTS=$(cat "include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g' )
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
                echo -ne "${Green}Are you 100% sure, on selecting [${media}] (y/n)? ${NC}"
                read response
                if [ "x${response}" != "xy" ] ; then
                        exit
                fi
                echo ""
        else
                echo ""
                echo -e "${Red}Are you sure? I Don't see [${media}], here is what I do see...${NC}"
                echo ""
                echo "lsblk:"
                lsblk | grep -v sr0
                echo ""
                echo -e "${Green}Permission Denied. Run with sudo"
                exit
        fi

}

unmount_all_drive_partitions () {

	     echo ""
        echo "Unmounting Partitions"
        echo "-----------------------------"

        NUM_MOUNTS=$(mount | grep -v none | grep "${media}" | wc -l)

##      for (i=1;i<=${NUM_MOUNTS};i++)
        for ((i=1;i<=${NUM_MOUNTS};i++))
        do
                DRIVE=$(mount | grep -v none | grep "${media}" | tail -1 | awk '{print $1}')
                umount ${DRIVE} >/dev/null 2>&1 || true
        done
}


if [ -z "$1" ]; then
	echo -e "${Green}usage: sudo $(basename $0) [--mmc /dev/sdX]  [--board ex:1 ] [--scp]${NC}"
fi

if [ -d out ] ; then
        echo -e "${Purple}out folder is found${NC}"
else
        echo -e "${Red}out folder is not found.${NC}"
        echo "pls run ./km-bbb-kernel-build.sh"
fi

# parse commandline options
while [ ! -z "$1" ] ; do
        case $1 in
        -h|--help)
		echo "usage: sudo $(basename $0) --mmc /dev/sdX --tftpshare <board_no> --scp <user_name <ipaddr>"
                ;;
	--mmc)
		media=$2
		check_mmc
		unmount_all_drive_partitions
		sudo mkdir -p /mnt/rootfs
	        sudo mount ${media}1 /mnt/rootfs

		echo -e "${Purple}cp out/${KERNEL_UTS}.zImage /mnt/rootfs/boot/vmlinuz-${KERNEL_UTS}${NC}"
		sudo cp ./out/${KERNEL_UTS}.zImage  /mnt/rootfs/boot/vmlinuz-${KERNEL_UTS}
	        sudo cp out/config-${KERNEL_UTS} /mnt/rootfs/boot/

		sudo mkdir -p  /mnt/rootfs/boot/dtbs/${KERNEL_UTS}
		echo -e "${Purple}cp arch/arm/boot/dts/km-bbb-am335x.dtb /mnt/rootfs/boot/dtbs/${KERNEL_UTS} ${NC}"
		sudo cp arch/arm/boot/dts/km-bbb-am335x.dtb  /mnt/rootfs/boot/dtbs/${KERNEL_UTS}/
		
		echo -e "${Purple} echo uname_r=${KERNEL_UTS} > /mnt/rootfs/boot/uEnv.txt ${NC}"
		echo uname_r=${KERNEL_UTS} > /mnt/rootfs/boot/uEnv.txt
                
		echo -e "${Purple} tar -xvf out/${KERNEL_UTS}-modules.tar.gz  -C /mnt/rootfs/ ${NC}"
                sudo tar -xvf ./out/${KERNEL_UTS}-modules.tar.gz  -C /mnt/rootfs/
        
		sync
        	unmount_all_drive_partitions
		;;
        --tftpshare)
		if [ ! -z "$2" ];then
			echo -e "${Purple}cp out/${KERNEL_UTS}.zImage /media/board$2/vmlinuz-${KERNEL_UTS}${NC}"
			sudo cp out/${KERNEL_UTS}.zImage /media/board$2/vmlinuz-${KERNEL_UTS}

			echo -e "${Purple}cp arch/arm/boot/dts/km-bbb-am335x.dtb /meida/board$2/${NC}"
			sudo cp arch/arm/boot/dts/km-bbb-am335x.dtb /media/board$2/

			echo -e "${Purple} echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt ${NC}"
			sudo echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt

			echo -e "${Purple} echo board_no=$2 >> /media/board$2/uEnv.txti${NC}"
			sudo echo board_no=$2 >> /media/board$2/uEnv.txt
		else
			echo "board number missing"
		fi
		;;
	--scp)
		if [ $# -le 2 ] ; then
			echo "pls enter user-name of board"
			read username
			echo "pls enter ipaddress of board"
			read ipaddress
			echo -e "${Purple} scp out/${KERNEL_UTS}.zImage cp out/config-${KERNEL_UTS} ./out/${KERNEL_UTS}-modules.tar.gz  arch/arm/boot/dts/km-bbb-am335x.dtb username@$ipaddress:~/install ${NC}"
			scp out/${KERNEL_UTS}.zImage out/config-${KERNEL_UTS} ./out/${KERNEL_UTS}-modules.tar.gz  arch/arm/boot/dts/km-bbb-am335x.dtb out/uEnv.txt ${username}@${ipaddress}:~/install
		else
			echo -e "${Purple} scp out/${KERNEL_UTS}.zImage cp out/config-${KERNEL_UTS} ./out/${KERNEL_UTS}-modules.tar.gz  arch/arm/boot/dts/km-bbb-am335x.dtb $2@$3:~/install ${NC}"
			scp out/${KERNEL_UTS}.zImage out/config-${KERNEL_UTS} ./out/${KERNEL_UTS}-modules.tar.gz  arch/arm/boot/dts/km-bbb-am335x.dtb out/uEnv.txt $2@$3:~/install
		fi
		;;
        esac
        shift
done

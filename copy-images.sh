#!/bin/sh

# copy images to shared folder


KERNEL_UTS="4.19.94-Kernel-Masters"
USER=km
# parse commandline options
while [ ! -z "$1" ] ; do
        case $1 in
        -h|--help)
                echo "${Red}./km_build_uboot.sh [--board <value>]${NC}"
                ;;
        --board)
                echo "${Purple}cp /home/$USER/out/${KERNEL_UTS}.zImage /media/board$2/vmlinuz-${KERNEL_UTS}${NC}"
                cp /home/$USER/out/${KERNEL_UTS}.zImage /media/board$2/vmlinuz-${KERNEL_UTS}
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

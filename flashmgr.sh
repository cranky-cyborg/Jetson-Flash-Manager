#!/bin/bash

#if [ "$EUID" -ne 0 ]; then
#  zenity --error --title="Not run as root" --text="Please run the script as root, example usage provided below.
#  
#  <b>Usage:</b>
#  	       'sudo ./01-flash.sh'" --ellipsize;
#  exit 0
#fi

sudo apt install pv -y

conf=$(zenity --forms --title="NVIDIA Jetson Orin Nano - Boot from NVMe"\
 --text="NVIDIA Jetson Orin Nano - Configuration" --separator=","\
 --add-combo="Do you want the script to download SD-card image :" --combo-values="Yes|No"\
 --add-combo="Select what drive you want to flash: " --combo-values="/dev/mmcblk1|/dev/nvme0n1"\
 --add-combo="Do you want to install DeepStream 6.3 :" --combo-values="Yes|No"\
 --add-combo="Do you wish to install NVIDIA-JetPack (latest) :" --combo-values="Yes|No"\
 --add-combo="Do you wish to increase ZRAM from 2Gb to 14GB :" --combo-values="Yes|No"\
 --add-combo="Do you wish to remove sudo from asking passwd :" --combo-values="Yes|No"\
 --add-combo="Do you wish to fix Docker permission issue :" --combo-values="Yes|No"\
 )

if(($? != 0)); then
  echo "Exiting, no changes were made!"
  exit 0
fi

sdimg=$(awk -F, '{print $1}' <<<$conf)
drive=$(awk -F, '{print $2}' <<<$conf)
deepstream=$(awk -F, '{print $3}' <<<$conf)
nvjetpack=$(awk -F, '{print $4}'<<<$conf)
zramswap=$(awk -F, '{print $5}' <<<$conf)
sudopass=$(awk -F, '{print $6}' <<<$conf)
dockerio=$(awk -F, '{print $7}' <<<$conf)

if [ $drive = "/dev/mmcblk1" ]; then
  sudo umount /dev/mmcblk1p1;
elif [ $drive = "/dev/nvme0n1" ]; then
  sudo umount /dev/nvme0n1p1;
fi

if [ $sdimg = "No" ] || [ $deepstream = "Yes" ]; then

  zenity --info --title="Files needed" \
  --text="
You have either selected <b><u>No</u></b> to download the SD Card image, or <b><u>Yes</u></b> to installing DeepStream SDK.
Selecting these requires you to manually download and place it in Folder '~/jetson-files'

<b>SD card image:</b> Download the SD-card image from URL (provided below), and place it in folder '~/jetson-files'.
If you have already extracted the zip, please the <b><i>sd-blob.img</i></b> file in the folder '~/jetson-files'.

<b><i>https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v4.1/jp512-orin-nano-sd-card-image.zip</i></b>

<b>DeepStream SDK 6.2</b> Down the DeepStream SDK from URL provided below, and place it in Folder '~/jetson-files'.
You will need NVIDIA login to download deepstream sdk.

<b><i>https://api.ngc.nvidia.com/v2/resources/org/nvidia/deepstream/6.3/files?redirect=true&amp;path=deepstream-6.3_6.3.0-1_arm64.deb</i></b>

<b> Only hit OK button, once you have placed these files in Folder '~/jetson-files' </b>
" --ellipsize;
fi

if [ $deepstream = "Yes" ]; then
  if [ ! -f ~/jetson-files/deepstream-6.3_6.3.0-1_arm64.deb ]; then
    zenity --error --title="Deepstream 6.2 (deb) installer file doesn't exists" \
    --text="Deepstream 6.3 installer file doesn't exists in folder '~/jetson-files'.
   
Please ensure you have the file copied, or the set DeepStream install option to 'No'. " --ellipsize;
    exit 0
  fi
fi

if [ ! -d ~/jetson-files ]; then
  mkdir ~/jetson-files;
fi

if [[ $sdimg = "Yes" ]]; then
  wget --quiet --show-progress https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v4.1/jp512-orin-nano-sd-card-image.zip 2>&1 | while IFS= read -r line; do echo $(awk -F'%' '{print $1}' <<<$(awk '{print $7}' <<<$line)); done | zenity --progress --auto-close --auto-kill --percentage=0 --time-remaining --width=600 --text="Downloading from developer.nvidia.com" --title="Jetson Orin Nano Developer Kit SD Card image";

  mv ./jp512-orin-nano-sd-card-image.zip ~/jetson-files

  unzip -p ~/jetson-files/jp512-orin-nano-sd-card-image.zip  | pv -n -s 21g > ~/jetson-files/sd-blob.img 2> >(zenity --progress --auto-close --auto-kill --percentage=0 --time-remaining --width=600 --text="Extracting sd-card image from .zip file " --title="Jetson Orin Nano Developer Kit SD Card image (Unzipping)");

else
  #c00623b88952ebf49a19007a95eec90c  jp512-orin-nano-sd-card-image.zip
  #c2fb40895ad851befa1a9c1ce50792a1  sd-blob.img

  #Check if zip file has case issue
  #todo
  if [ -f ~/jetson-files/sd-blob.img  ]; then
    echo "Validating file sd-blob.img, this will take some time";
    md5sd=$(awk '{print $1}' <<< $(md5sum ~/jetson-files/sd-blob.img));
    if [ $md5sd = "c2fb40895ad851befa1a9c1ce50792a1" ]; then
      echo "File sd-blob.img is valid";
    elif [ -f ~/jetson-files/jp512-orin-nano-sd-card-image.zip ]; then
      echo "Validating file jp512-orin-nano-sd-card-image.zip, this will take some time";
      mdzip=$(awk '{print $1}' <<< $(md5sum ~/jetson-files/jp512-orin-nano-sd-card-image.zip));
      if [ $mdzip = "c00623b88952ebf49a19007a95eec90c" ]; then
        echo "File jp512-orin-nano-sd-card-image.zip is valid";
        unzip -p ~/jetson-files/jp512-orin-nano-sd-card-image.zip | pv -n -s 21g > ~/jetson-files/sd-blob.img 2> >(zenity --progress --auto-close --auto-kill --percentage=0 --time-remaining --width=600 --text="Extracting sd-card image from .zip file " --title="Jetson Orin Nano Developer Kit SD Card image (Unzipping)");
      else
        echo "File jp512-orin-nano-sd-card-image.zip is invalid; Exiting script";
        exit 1;
      fi;
    fi;
  elif [ -f ~/jetson-files/jp512-orin-nano-sd-card-image.zip ]; then
    echo "Validating file jp512-orin-nano-sd-card-image.zip, this will take some time";
    mdzip=$(awk '{print $1}' <<< $(md5sum ~/jetson-files/jp512-orin-nano-sd-card-image.zip));
    if [ $mdzip = "c00623b88952ebf49a19007a95eec90c" ]; then
      echo "File jp512-orin-nano-sd-card-image.zip is valid";
      unzip -p ~/jetson-files/jp512-orin-nano-sd-card-image.zip | pv -n -s 21g > ~/jetson-files/sd-blob.img 2> >(zenity --progress --auto-close --auto-kill --percentage=0 --time-remaining --width=600 --text="Extracting sd-card image from .zip file " --title="Jetson Orin Nano Developer Kit SD Card image (Unzipping)");
    else
      echo "File jp512-orin-nano-sd-card-image.zip is invalid; Exiting script";
      exit 1;
    fi;
  else
    echo "Files done exist! Exiting script";
    exit 1;
  fi;
fi

#lets flash
(pv -n ~/jetson-files/sd-blob.img | sudo dd of=$drive bs=128M conv=notrunc,noerror) 2>&1 | zenity --progress --auto-close --auto-kill --percentage=0 --time-remaining --width=600 --text="Flashing SD-Card Image to $drive" --title="Jetson Orin Nano Developer Kit (flashing)";

#create the folders for mount point
if [ ! -d "/media/jetpack" ]; then
  # folder doesn't exist, create one
  sudo mkdir /media/jetpack;
fi
if [ ! -d "/media/jetpack/flash" ]; then
  # folder doesn't exist, create one
  sudo mkdir /media/jetpack/flash;
fi

#mount the right partition onto the mount point /media/jetpack/flash
if [ $drive = "/dev/mmcblk1" ]; then
  sudo mount /dev/mmcblk1p1 /media/jetpack/flash;
elif [ $drive = "/dev/nvme0n1" ]; then
  sudo mount /dev/nvme0n1p1 /media/jetpack/flash;
fi

#create home directory for jetpack
sudo mkdir /media/jetpack/flash/home/jetpack;

#Copy scripts and install files to the home directory
sudo cp ./install-jetpack.sh /media/jetpack/flash/home/jetpack;
sudo cp ~/jetson-files/deepstream-6.3_6.3.0-1_arm64.deb /media/jetpack/flash/home/jetpack;
#Copy desktop icon to /etc/skel/Desktop, this will be made available for all users. 
sudo cp ./install-jetpack.desktop /media/jetpack/flash/etc/skel/Desktop;

#Increases ZRAM/swap to twice of memory, default is half of memory
if [ $zramswap = "Yes" ]; then
  sudo sed -i 's|totalmem}" / 2|totalmem}" * 2|g' /media/jetpack/flash/etc/systemd/nvzramconfig.sh
fi

#Changes file persmission on /var/run/docker.sock file to fix persmission error
if [ $dockerio = "Yes" ]; then
  sudo sed -i 's|#{docker-sock}|  |g' /media/jetpack/flash/home/jetpack/install-jetpack.sh
fi

#Removes password requirement from sudo command, i.e. sudo command will not ask for password
if [ $sudopass = "Yes" ]; then
  sudo sed -i 's|#{remove-sudo-password}|  |g' /media/jetpack/flash/home/jetpack/install-jetpack.sh
fi

#Make changes to extlinux.conf and unmount drive
if [ $drive = "/dev/mmcblk1" ]; then
  sudo umount /dev/mmcblk1p1;
elif [ $drive = "/dev/nvme0n1" ]; then
  now=$(date +"%Y-%m-%d-%H-%M-%S-%N");
  sudo cp /media/jetpack/flash/boot/extlinux/extlinux.conf /media/jetpack/flash/boot/extlinux/extlinux.conf.bkup.$now;
  #changing the root from /dev/mmcblk1p1 to /dev/nvme0n1p1 in the extlinux.conf file
  sudo sed -i 's/root=\/dev\/mmcblk1p1/root=\/dev\/nvme0n1p1/g' /media/jetpack/flash/boot/extlinux/extlinux.conf;

  sudo umount /dev/nvme0n1p1;
fi

zenity --info --title="All done!" \
--text="We are done here, if you flashed NVMe, reboot your Jetson Orin Nano board and remove the SDcard prior to booting" --ellipsize

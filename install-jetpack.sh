#!/bin/bash

sudo apt update

sudo apt install --yes --assume-yes \
 cmake nano libssl1.1 nvidia-jetpack \
 libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev libpng-dev libtiff-dev \
 libavcodec-dev libavformat-dev libswscale-dev libglew-dev \
 libxvidcore-dev libx264-dev libgtk-3-dev \
 libtbb-dev libdc1394-22-dev libxine2-dev \
 libv4l-dev v4l-utils qv4l2 \
 libavresample-dev libvorbis-dev libxine2-dev libtesseract-dev \
 libfaac-dev libmp3lame-dev libtheora-dev libpostproc-dev \
 libopencore-amrnb-dev libopencore-amrwb-dev \
 libopenblas-dev libopenblas-base libopenmpi-dev libatlas-base-dev libblas-dev \
 liblapack-dev liblapacke-dev libeigen3-dev gfortran \
 libhdf5-dev protobuf-compiler \
 libgtk-3-dev libcanberra-gtk-module libcanberra-gtk3* \
 libprotobuf-dev libgoogle-glog-dev libgflags-dev \
 gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
 gstreamer1.0-plugins-ugly gstreamer1.0-libav libgstreamer-plugins-base1.0-dev \
 libgstrtspserver-1.0-0 libjansson4 libyaml-cpp-dev libgstreamer1.0-0 \
 python3-dev python3-pip python3-venv \
 libfreetype6-dev libssl-dev liblz4-dev libsasl2-dev;

#Below is a placeholder if the user opts to remove sudo from asking password (only in terminal)
#{remove-sudo-password}echo " 
#{remove-sudo-password}${USER} ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo;

#Below is a placeholder for Docker.sock permission issue
#{docker-sock}sudo chmod 666 /var/run/docker.sock;

#librdkafka installation is for DeepStream 6.3 installation.
#ref: https://docs.nvidia.com/metropolis/deepstream/dev-guide/text/DS_Quickstart.html#install-librdkafka-to-enable-kafka-protocol-adaptor-for-message-broker
#Kafka installation begins
mkdir /home/jetpack/kafka;
cd /home/jetpack/kafka;

#Clone the librdkafka repository from GitHub:
git clone https://github.com/edenhill/librdkafka.git;

#Configure and build the library:
cd librdkafka;
git reset --hard 7101c2310341ab3f4675fc565f64f0967e135a6a;
./configure;
make;
sudo make install;

#Copy the generated libraries to the deepstream directory:
sudo mkdir -p /opt/nvidia/deepstream/deepstream-6.3/lib;
sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-6.3/lib;
#Kafka installation ends

#reinstall NVIDIA BSP Packages
sudo apt install --reinstall --yes --assume-yes \
  nvidia-l4t-3d-core nvidia-l4t-apt-source nvidia-l4t-bootloader nvidia-l4t-camera nvidia-l4t-configs \
  nvidia-l4t-core nvidia-l4t-cuda nvidia-l4t-display-kernel nvidia-l4t-firmware nvidia-l4t-gbm \
  nvidia-l4t-graphics-demos nvidia-l4t-gstreamer nvidia-l4t-init nvidia-l4t-initrd nvidia-l4t-jetson-io \
  nvidia-l4t-jetson-multimedia-api nvidia-l4t-jetsonpower-gui-tools nvidia-l4t-kernel-dtbs nvidia-l4t-kernel-headers \
  nvidia-l4t-kernel nvidia-l4t-libvulkan nvidia-l4t-multimedia-utils nvidia-l4t-multimedia nvidia-l4t-nvfancontrol \
  nvidia-l4t-nvpmodel-gui-tools nvidia-l4t-nvpmodel nvidia-l4t-nvsci nvidia-l4t-oem-config nvidia-l4t-openwfd \
  nvidia-l4t-optee nvidia-l4t-pva nvidia-l4t-tools nvidia-l4t-vulkan-sc-dev nvidia-l4t-vulkan-sc-samples \
  nvidia-l4t-vulkan-sc-sdk nvidia-l4t-vulkan-sc nvidia-l4t-wayland nvidia-l4t-weston nvidia-l4t-x11 \
  nvidia-l4t-xusb-firmware nvidia-jetpack;

if [ -f /home/jetpack/deepstream-6.3_6.3.0-1_arm64.deb ]; then
 sudo apt-get install /home/jetpack/deepstream-6.3_6.3.0-1_arm64.deb;
fi

sudo rm -rf /home/jetpack;
sudo rm -f /etc/skel/Desktop/install-jetpack.desktop;
sudo rm -f /home/${USER}/Desktop/install-jetpack.desktop;

sudo apt full-upgrade --yes --assume-yes;

sudo reboot;

exit 0;

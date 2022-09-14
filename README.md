# Bash setup script for Ubuntu servers

#Install Kitty 

# Installation
sudo apt-get update
sudo apt-get install git
cd ~
git clone https://github.com/alfxp/s.git
cd s
sudo bash start.sh


# update directory)
git pull https://github.com/alfxp/s.git 

# sshd_config
vi /etc/ssh/sshd_config

# Best Tutorial
https://ranchergovernment.com/simple-rke2-longhorn-and-rancher-install

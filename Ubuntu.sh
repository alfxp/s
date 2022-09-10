#!/bin/bash

#**********************************************************************************************************************************************************
# Clone this repository into your home directory:
# cd ~
# git clone https://github.com/alfxp/s.git
# cd ubuntu-server-setup
# bash Ubuntu.sh
# git pull https://github.com/alfxp/s.git  (update directory)
#sudo -s
#**********************************************************************************************************************************************************
set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"    
    if [[ ! -d "${current_dir}" ]]; then 
        current_dir="$PWD"; 
    fi
    echo "current_dir: ${current_dir}"
}

function includeDependencies() {        
    source ."${current_dir}/setupLibrary.sh"
    source ."${current_dir}/library.sh"
}

getCurrentDir
current_dir=${current_dir}
includeDependencies
output_file="output.log"

read -rp "Do you update system? [Y/N] " r1
if [[ $r1 == [yY] ]]; then
    UpdateSystem
fi

read -rp "Do you update config SSH? [Y/N] " r2
if [[ $r2 == [yY] ]]; then
    ConfigSSH
fi

read -rp "Do you Install NFS? [Y/N] " r3
if [[ $r3 == [yY] ]]; then
    InstallNFS
fi

read -rp "Do you Install Docker? [Y/N] " r3
if [[ $r3 == [yY] ]]; then
    InstallDocker
fi

read -rp "Do you Install InstallRKE2? [Y/N] " r4
if [[ $r4 == [yY] ]]; then
    InstallRKE2
fi


#InstallRKE2Agent #IP do rancher e o token. (# change the Token to the one from rancher1 /var/lib/rancher/rke2/server/node-token)
#InstallRancher
#InstallPortainer
#SetupFirewallDocker
#SetupFail2Ban



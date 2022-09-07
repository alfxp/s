#!/bin/bash
#**********************************************************************************************************************************************************
# Clone this repository into your home directory:
# cd ~
# git clone https://github.com/alfxp/ubuntu-server-setup.git
# cd ubuntu-server-setup
# bash Ubuntu.sh
# git pull https://github.com/alfxp/ubuntu-server-setup.git  (update directory)
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
    # shellcheck source=./setupLibrary.sh
    source ."${current_dir}/function.sh" 
    source ."${current_dir}/setupLibrary.sh"    

    source ./setupLibrary.sh
    source ./function.sh

    echo ."${current_dir}/setupLibrary.sh"    
    echo ."${current_dir}/function.sh" 

    for file in * ; do
        if [ -f "$file" ] ; then
            . "$file"
        fi
    done
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


#InstallNFS
#InstallDocker
#InstallRKE2
#InstallRKE2Agent #IP do rancher e o token. (# change the Token to the one from rancher1 /var/lib/rancher/rke2/server/node-token)
#InstallRancher
#InstallPortainer
#SetupFirewallDocker
#SetupFail2Ban



#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"    
    if [[ ! -d "${current_dir}" ]]; then 
        current_dir="$PWD"; 
    fi
    echo "current_dir: ${current_dir}"
}

function includeDependencies() {        
    source ."${current_dir}/librarySetup.sh"
    source ."${current_dir}/libraryScript.sh"        
}

getCurrentDir
current_dir=${current_dir}
includeDependencies
output_file="output.log"

sudo -s

removeFloppy

read -rp "Do you add new user? [Y/N] " c0
if [[ $c0 == [yY] ]]; then
    AddUser
fi

read -rp "Do you install Vim? [Y/N] " r0
if [[ $r0 == [yY] ]]; then
    installVim
fi

read -rp "Do you update system? [Y/n] " r1
if [[ $r1 == [yY] ]]; then
    UpdateSystem
fi

read -rp "Do you Setup config SSH? [Y/n] " r2
if [[ $r2 == [yY] ]]; then
    SetupSSH
fi

read -rp "Do you Install NFS? [Y/n] " r3
if [[ $r3 == [yY] ]]; then
    InstallNFS
fi

read -rp "Do you Install Docker? [Y/N] " r4
if [[ $r4 == [yY] ]]; then
    InstallDocker
fi

read -rp "Do you Install RKE2? [Y/N] " r5
if [[ $r5 == [yY] ]]; then
    InstallRKE2
fi

read -rp "Do you Install RKE2 Agent? [Y/N] " r5
if [[ $r5 == [yY] ]]; then
    InstallRKE2Agent #IP do rancher e o token. (# change the Token to the one from rancher1 /var/lib/rancher/rke2/server/node-token)
fi

read -rp "Do you Install Rancher? [Y/N] " r6
if [[ $r6 == [yY] ]]; then
    InstallRancher
fi

read -rp "Do you Install Portainer? [Y/N] " r7
if [[ $r7 == [yY] ]]; then
    InstallPortainer
fi


#
#
#SetupFirewallDocker
#SetupFail2Ban




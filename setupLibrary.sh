#!/bin/bash

# Update the user account
# Arguments:
#   Account Username
function updateUserAccount() {
    local username=${1}
    
    sudo passwd -d "${username}"
    sudo usermod -aG sudo "${username}"
}

# Add the new user account
# Arguments:
#   Account Username
#   Flag to determine if user account is added silently. (With / Without GECOS prompt)
function addUserAccount() {
    local username=${1}
    local silent_mode=${2}

    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --gecos '' "${username}"
    else
        sudo adduser --disabled-password "${username}"
    fi

    sudo usermod -aG sudo "${username}"
    sudo passwd -d "${username}"
}

# Add the local machine public SSH Key for the new user account
# Arguments:
#   Account Username
#   Public SSH Key
function addSSHKey() {
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

# Execute a command as a certain user
# Arguments:
#   Account Username
#   Command to be executed
function execAsUser() {
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

# Modify the sshd_config file
# shellcheck disable=2116
function changeSSHConfig() {
    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
}

# Setup the Uncomplicated Firewall
function setupUfw() {
    sudo apt-get install ufw
    sudo ufw allow OpenSSH
    yes y | sudo ufw enable
}

# Create the swap file based on amount of physical memory on machine (Maximum size of swap is 4GB)
function createSwap() {
   local swapmem=$(($(getPhysicalMemory) * 2))

   # Anything over 4GB in swap is probably unnecessary as a RAM fallback
   if [ ${swapmem} -gt 4 ]; then
        swapmem=4
   fi

   sudo fallocate -l "${swapmem}G" /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
}

# Mount the swapfile
function mountSwap() {
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

# Modify the swapfile settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function tweakSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    sudo sysctl vm.swappiness="${swappiness}"
    sudo sysctl vm.vfs_cache_pressure="${vfs_cache_pressure}"
}

# Save the modified swap settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function saveSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    echo "vm.swappiness=${swappiness}" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=${vfs_cache_pressure}" | sudo tee -a /etc/sysctl.conf
}

# Set the machine's timezone
# Arguments:
#   tz data timezone
function setTimezone() {
    local timezone=${1}
    echo "${1}" | sudo tee /etc/timezone
    sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime # https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
    sudo dpkg-reconfigure -f noninteractive tzdata
}

# Configure Network Time Protocol
function configureNTP() {
    ubuntu_version="$(lsb_release -sr)"

    if [[ $(bc -l <<< "${ubuntu_version} >= 20.04") -eq 1 ]]; then
        sudo systemctl restart systemd-timesyncd
    else
        sudo apt-get update
        sudo apt-get --assume-yes install ntp
        
        # force NTP to sync
        sudo service ntp stop
        sudo ntpd -gq
        sudo service ntp start
    fi
}

# Gets the amount of physical memory in GB (rounded up) installed on the machine
function getPhysicalMemory() {
    local phymem
    phymem="$(free -g|awk '/^Mem:/{print $2}')"
    
    if [[ ${phymem} == '0' ]]; then
        echo 1
    else
        echo "${phymem}"
    fi
}

# Disables the sudo password prompt for a user account by editing /etc/sudoers
# Arguments:
#   Account username
function disableSudoPassword() {
    local username="${1}"

    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

# Reverts the original /etc/sudoers file before this script is ran
function revertSudoers() {
    sudo cp /etc/sudoers.bak /etc/sudoers
    sudo rm -rf /etc/sudoers.bak
}

################################################################################################################

function InstallRKE2Agent(){
    
    echo "InstallRKE2Agent - Rancher Kubernetes Engine"

    #####################################################################################################################
    ### RKE2 RKE2 Agent Install
    #####################################################################################################################

    # we add INSTALL_RKE2_TYPE=agent
    curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -

    # create config file
    mkdir -p /etc/rancher/rke2/

    # change the ip to reflect your rancher1 ip
    echo "server: https://192.168.50.85:9345" > /etc/rancher/rke2/config.yaml

    # change the Token to the one from rancher1 /var/lib/rancher/rke2/server/node-token
    echo "token: $TOKEN" >> /etc/rancher/rke2/config.yaml

    # enable and start
    systemctl enable rke2-agent.service
    systemctl start rke2-agent.service

}

function InstallRKE2()
{

    echo "InstallRKE2 - Rancher Kubernetes Engine"
    #####################################################################################################################
    ### RKE2 Install
    #####################################################################################################################
    sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -

    # start and enable for restarts -
    systemctl enable rke2-server.service
    systemctl start rke2-server.service

    # simlink all the things - kubectl
    ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
    
    # add kubectl conf
    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

    # check node status
    kubectl  get node

}

function InstallNFS()
{

    echo 'InstallNFS'

    # Ubuntu instructions
    # stop the software firewall
    # systemctl stop ufw
    # systemctl disable ufw

    # get updates, install nfs, and apply
    sudo apt install nfs-common -y

    # clean up
    sudo apt autoremove -y

}

function UpdateSystem()
{
    echo 'UpdateSystem'

	#Atualizar o Ubuntu
    sudo apt update
    sudo apt upgrade -y
}

function InstallDocker() {

	echo 'InstallDocker'

	#Uninstall or delete older versions of Docker
	sudo apt remove -y docker docker-engine docker.io containerd runc
	
	#install Docker
	sudo apt install -y docker.io 

	#In addition, add the currently logged-in user to the Docker group to enable them to run Docker commands without sudo privileges.
	sudo usermod -aG docker $USER

	#Then activate the changes to groups.
	newgrp docker

	#start and enable the Docker daemon.
	sudo systemctl start docker
	
	#Service starts every time during system startup.
	sudo systemctl enable docker
}

function InstallRancher()
{
	echo 'InstallRancher'	
	#sudo docker run -d --name=rancher-server --restart=unless-stopped -p 80:8080 -p 443:8081 --privileged rancher/rancher:v2.6.5

    #####################################################################################################################
    ### Rancher Install
    #####################################################################################################################

    # on the server rancher1
    # add helm
    curl -#L https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # add needed helm charts
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo add jetstack https://charts.jetstack.io

    # still on  rancher1
    # add the cert-manager CRD
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

    # helm install jetstack
    helm upgrade -i cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace

    # helm install rancher
    helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=rancher.dockr.life --set bootstrapPassword=bootStrapAllTheThings --set replicas=1

}

function InstallPortainer()
{
	echo 'InstallPortainer'
	sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.9.3

	echo 'Restart portainer'
	sudo docker restart portainer
}

function ConfigSSH()
{
    echo 'ConfigSSH--'
    addUserAccount "acv"
    disableSudoPassword "acv"
    addSSHKey "acv" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8XKMCa9s1gryPgnIirnUeYUtb5RVrc+s9usVWwZLQm3bmeKdT6w3OvYc03HrPprHJbiHzonfIEdk+r4RlqpKHTusu5sA8av250B2hgSNXFx9LKO+dow1LJsMslH5Jfd8ILfC082TBYF02JLo/la7QushMfrisMxOy0GFkEan3ujoF0wtdaitTtEXFMATkRCWKLvjIAL5qKperD2C2rG5kiy5OhUEImcrbMZfJfcqSS94f/s6Le46nQh9AbtncWCfTmnBKH2tIC6+mzgPw6qAVn8Uo6QHlvaX0DrcxbglKWVX+RA4VjWHhSQ4xD0qH8iJz4ukVoy1BY9zhx/MRTCcyo/dB4DVT3xsLgc5jx/NrxhaHmUkGnHdpgDZIY9RCMv+y/2yUl0yK4s41Bum+AqFpXLbUu36CxgOhH/WrwYDQIU/t5IKJPEjZg5quvwynn07Q3jbeArEMsMMpeIkVsXAqCVgz6g3/ID1I+3ixwFBv5b3EDwvbnaiN2Vy1lrng9OMl4epAOmz+3WteQMDbbu6aJ/TSzqE/T3EaAIDmn2RStwtjyb0s7Agn1aabSQMidnQ74BxX7k0K5omPd0r0HNRYQgw2JLJ3Xlhtxo2A41vRoXH+FXlUJsxfKe5Y1prNGS8Nr2yUcwEVAd8/MmAaQxX+aSWySFsTPSI37jcNxBLSeQ== rsa-key-20220814"

}

function SetupFirewallDocker()
{
    #Firewall do docker.
    sudo docker run --name firewall 
    --env OPEN_PORTS="22,80,443" 
    --env ACCEPT_ALL_FROM="ip1,ip2" 
    --env CHAIN="DOCKER-FIREWALL" -itd --restart=always 
    --cap-add=NET_ADMIN 
    --net=host vitobotta/docker-firewall:0.1.0

}

function SetupFail2Ban()
{

    #Fail2ban
    sudo docker run -it -d --name fail2ban --restart always \
    --network host \
    --cap-add NET_ADMIN \
    --cap-add NET_RAW \
    -v $(pwd)/fail2ban:/data \
    -v /var/log:/var/log:ro \
    -e F2B_LOG_LEVEL=DEBUG \
    -e F2B_IPTABLES_CHAIN=INPUT \
    -e F2B_ACTION="%(action_mwl)s" \
    -e TZ=EEST \
    -e F2B_DEST_EMAIL=... \
    -e F2B_SENDER=... \
    -e SSMTP_HOST=... \
    -e SSMTP_PORT=... \
    -e SSMTP_USER=... \
    -e SSMTP_PASSWORD=... \
    -e SSMTP_TLS=YES \
    crazymax/fail2ban:latest
}





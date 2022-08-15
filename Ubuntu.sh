#!/bin/bash

set -e

function UpdateSystem()
{
	sudo apt update && sudo apt dist-upgrade
}

function Docker() {

	echo 'Docker'

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

function Rancher()
{
	echo 'Rancher'	
	docker run -d --name=rancher-server --restart=unless-stopped -p 80:8080 -p 443:8081 --privileged rancher/rancher:v2.6.5
}

function Portainer()
{
	echo 'Portainer'
	docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
	docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

	echo '#Reiniciando o portainer'
	sudo docker restart portainer
}

UpdateSystem
Docker
Rancher
Portainer

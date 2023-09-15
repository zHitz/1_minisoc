#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges!"
  exit 1
fi

if [ "$1" = "Ubuntu" ]; then
  echo "Starting the Docker installation process on Ubuntu..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "Docker has been installed on Ubuntu!"

elif [ "$1" = "CentOS" ]; then
  echo "Starting the Docker installation process on CentOS..."
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "Docker has been installed on CentOS!"

else
  echo "Unsupported or incorrect operating system!"
  echo "Usage: sudo bash install_docker.sh Ubuntu or sudo bash install_docker.sh CentOS"
  exit 1
fi

read -p "Do you want to install Portainer? (y/n): " choice
if [ "$choice" = "y" ]; then
  docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
  echo "Portainer has been installed and started!"
else
  echo "Portainer will not be installed."
fi

exit 0

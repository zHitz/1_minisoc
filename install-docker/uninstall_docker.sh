#!/bin/bash

# Check if the script is executed with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with root privileges (sudo)."
    exit 1
fi

# Check if the OS argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 [Ubuntu|CentOS]"
    exit 1
fi

OS="$1"

case "$OS" in
    Ubuntu)
        # Uninstall Docker on Ubuntu
        echo "Uninstalling Docker on Ubuntu..."
        apt-get -y purge docker-ce docker-ce-cli containerd.io
        ;;
    CentOS)
        # Uninstall Docker on CentOS
        echo "Uninstalling Docker on CentOS..."
        yum -y remove docker-ce docker-ce-cli containerd.io
        ;;
    *)
        echo "Unsupported OS. Please specify 'Ubuntu' or 'CentOS'."
        exit 1
        ;;
esac

# Remove Docker installation files and directories
echo "Removing Docker installation files and directories..."
rm -rf /var/lib/docker
rm -rf /etc/docker
rm -rf /etc/systemd/system/docker.service.d
rm -rf /usr/local/bin/docker-compose

# Remove Docker GPG key and APT/YUM sources
echo "Removing Docker GPG key and package repository..."
if [ "$OS" == "Ubuntu" ]; then
    rm /etc/apt/sources.list.d/docker.list
    rm /etc/apt/sources.list.d/docker.list.save
    rm /etc/apt/trusted.gpg.d/docker.gpg
elif [ "$OS" == "CentOS" ]; then
    rm /etc/yum.repos.d/docker-ce.repo
fi

# Update package lists and clean the cache
echo "Updating package lists and cleaning the cache..."
if [ "$OS" == "Ubuntu" ]; then
    apt-get update
    apt-get -y autoremove
    apt-get -y clean
elif [ "$OS" == "CentOS" ]; then
    yum -y clean all
fi

echo "Docker uninstallation and cleanup completed for $OS."
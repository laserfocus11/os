#!/bin/bash

# Script to set up a Nebula node
# WARNING: This script is not meant to be run as root. It is meant to be run as the main user.

set -e
set -o pipefail

###############################################################################
# Get Dotfiles                                                                
###############################################################################

echo -e "Getting dotfiles..."

# Clone dotfiles from Github
echo -e "Cloning dotfiles from Github..."
git clone https://github.com/aguilarcarboni/dotfiles.git ~/dotfiles

# Copy .gnupg to home directory
echo -e "Copying basic dotfiles to home directory..."
cp -r ~/dotfiles/.gnupg ~/

# Set permissions for .gnupg
chown -R $(whoami) ~/.gnupg/
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg

# Copy .gitconfig to home directory
cp -r ~/dotfiles/.gitconfig ~/

###############################################################################
# Decrypt Dotfiles                                                            
###############################################################################

# Decrypt .git-credentials
echo -e "Decrypting heavier files..."
read -sp "Enter your passphrase to decrypt your files: " passphrase
echo -e "\n"
gpg --batch --passphrase ${passphrase} --decrypt ~/dotfiles/.git-credentials.gpg > ~/.git-credentials

# Remove dotfiles folder
rm -rf ~/dotfiles
echo -e "Done\n"

###############################################################################
# Set up Nebula Node                                                           
###############################################################################

# Create Nebula folder structure
read -p "Do you want to set up a Nebula node in this machine? (Y/n): " nebula
if [[ -z "${nebula}" || "${nebula}" =~ ^[Yy]$ ]]; then
    echo -e "\nCreating Nebula..."
    cd ~/
    mkdir Nebula
    cd Nebula

    # Clone Nebula's infrastructure
    echo -e "\nCloning Nebula's infrastructure..."
    git clone https://github.com/aguilarcarboni/nebula.git
    echo -e "Done\n"

    # Create Portainer
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9443:9443 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.21.4

    echo -e "\nBuilding Cortex using Nebula's infrastructure..."
    mkdir cortex
    cd infrastructure
    docker compose -f cortex.yaml up -d
    cd ..
    echo -e "Done\n"

    read -p "Do you want to set up Apollo in this machine? (Y/n): " apollo
    if [[ -z "${apollo}" || "${apollo}" =~ ^[Yy]$ ]]; then
        echo -e "\nBuilding Apollo using Nebula's infrastructure..."
        mkdir apollo
        cd infrastructure
        docker compose -f apollo.yaml build
        docker compose -f apollo.yaml up -d
        cd ..
        echo -e "Done\n"
    fi

    read -p "Do you want to set up Laserfocus in this machine? (Y/n): " laserfocus
    if [[ -z "${laserfocus}" || "${laserfocus}" =~ ^[Yy]$ ]]; then
        echo -e "\nCloning laserfocus from source..."
        mkdir laserfocus
        cd laserfocus
        git clone https://github.com/aguilarcarboni/oasis.git
        git clone https://github.com/aguilarcarboni/oasis-socket.git
        git clone https://github.com/aguilarcarboni/laserfocus-api.git
        echo -e "Building laserfocus using Nebula's infrastructure..."
        cd ..

        echo -e "\nBuilding laserfocus using Nebula's infrastructure..."
        cd infrastructure
        docker compose -f laserfocus.yaml build
        docker compose -f laserfocus.yaml up -d
        cd ..
        echo -e "Done\n"
    fi

    read -p "Do you want to set up Athena in this machine? (Y/n): " athena
    if [[ -z "${athena}" || "${athena}" =~ ^[Yy]$ ]]; then
        echo -e "\nCloning Athena from source..."
        mkdir athena
        cd athena
        git clone https://github.com/aguilarcarboni/athena-webui.git
        git clone https://github.com/aguilarcarboni/athena-api.git
        git clone https://github.com/aguilarcarboni/athena-speech.git
        echo -e "Building Athena using Nebula's infrastructure..."
        cd ..

        echo -e "\nBuilding Athena using Nebula's infrastructure..."
        cd infrastructure
        docker compose -f athena.yaml build
        docker compose -f athena.yaml up -d
        cd ..
        echo -e "Done\n"
    fi

    echo -e "Done building Nebula node.\n"

fi

fastfetch
echo -e "Nebula node successfully set up."

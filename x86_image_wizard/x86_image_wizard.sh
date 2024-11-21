#!/bin/sh

if [ -w /var/run/docker.sock ]
then
    true
else 
    echo "You aren't in the docker group, please run usermod -a -G docker $USER && newgrp docker"
    exit 2
fi

build_alpine() {
    cd alpine
    sh build-alpine-bin.sh
    cd ..
}
build_ubuntu_bionic(){
    cd ubuntu-bionic
    sh build-ubuntu-bionic-bin.sh
}

display_menu() {
    echo "Choose a rootfs image to build:"
    echo "1. Alpine"
    echo "2. Ubuntu Bionic(18.04)"
    echo "0. Exit"
}

process_choice() {
    case "$1" in
        2)
            build_ubuntu_bionic
            ;;
        1)
            build_alpine
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
}

while true; do
    display_menu
    read -p "Enter your choice: " choice
    process_choice "$choice"
    echo ""
done

#!/bin/bash

function check {
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    echo "Warning: This script will completely remove all installed Python versions from your system."
    echo "This operation cannot be undone and may affect system stability if Python is used by system utilities."
    echo ""
    while true; do
        read -p "Do you wish to continue with the cleanup? (yes/no) " yn
        case $yn in
            [Yy]* ) cleanup; break;;
            [Nn]* ) echo "Cleanup canceled."; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    install
else
    echo "Python is not installed on this system. No cleanup required."
    install
fi
}

function cleanup {
    echo "Removing all installed Python versions..."
    non_essential_packages=$(dpkg-query -W -f='${Package} ${Essential}\n' | grep python3 | grep -v 'yes' | awk '{print $1}')
    sudo apt-get remove --purge $non_essential_packages -y
    sudo apt install -y lsb-release
}

function install {
    PIPX_VERSION="1.3.3"

    UBUNTU_VERSION=$(lsb_release -r | awk '{print $2}')
    PYTHON_VERSION="python3.8"
    
    if [[ "$(printf '%s\n' "20.04" "$UBUNTU_VERSION" | sort -V | head -n1)" == "20.04" && "$UBUNTU_VERSION" != "20.04" ]]; then
        PYTHON_VERSION="python3.10"
    fi

    echo "Ubuntu version: $UBUNTU_VERSION"
    echo "Selected Python version: $PYTHON_VERSION"

    echo "Updating package list..."
    sudo apt update

    echo "Installing build dependencies..."
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget lsb-release make

    echo "Installing Python..."
    sudo apt install -y python3-lib2to3 python3-distutils python3-pkg-resources python3-setuptools python3-wheel $PYTHON_VERSION $PYTHON_VERSION-venv $PYTHON_VERSION-dev python3-pip

    echo "Checking Python version..."
    $PYTHON_VERSION --version

    echo "Upgrading pip..."
    $PYTHON_VERSION -m pip install --upgrade pip

    echo "Installing pipx..."
    $PYTHON_VERSION -m pip install --user pipx

    echo "Installing specific version of pipx..."
    $PYTHON_VERSION -m pip install --user pipx==${PIPX_VERSION}

    echo "Adding pipx to PATH if not already present..."
    PIPX_PATH="$HOME/.local/bin"
    if ! grep -qxF "export PATH=\"$PIPX_PATH:\$PATH\"" ~/.bashrc ; then
        echo "Exporting pipx path to .bashrc"
        echo "export PATH=\"$PIPX_PATH:\$PATH\"" >> ~/.bashrc
    fi

    if [[ ":$PATH:" != *":$PIPX_PATH:"* ]]; then
        export PATH="$PIPX_PATH:$PATH"
    fi

    echo "Reloading .bashrc to update environment variables..."
    source $HOME/.bashrc

    echo "Installation completed."
}


check

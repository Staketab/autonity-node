#!/bin/bash

function check {
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    echo "Warning: This script will completely remove all installed Python versions from your system."
    echo "This operation cannot be undone and may affect system stability if Python is used by system utilities."
    echo ""
    while true; do
        read -p "Do you wish to continue with the cleanup? (yes/no) " yn
        case $yn in
            [Yy]* ) cleanup; break;; # Вызываем cleanup только если пользователь согласен
            [Nn]* ) echo "Cleanup canceled."; break;; # Выходим из цикла, но продолжаем скрипт
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
    sudo apt-get remove --purge python3.* -y
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
}

function install {
    PIPX_VERSION="1.3.3"

    echo "Updating package list..."
    sudo apt update

    echo "Installing build dependencies..."
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget

    echo "Installing Python..."
    sudo apt install -y python3.8 python3.8-venv python3.8-dev python3-pip

    echo "Checking Python version..."
    python3.8 --version

    echo "Upgrading pip..."
    python3.8 -m pip install --upgrade pip

    echo "Installing pipx..."
    python3.8 -m pip install --user pipx

    echo "Installing specific version of pipx..."
    python3.8 -m pip install --user pipx==${PIPX_VERSION}

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

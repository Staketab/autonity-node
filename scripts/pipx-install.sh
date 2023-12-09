#!/bin/bash

echo "Removing all installed Python versions..."

# Removing Python 3 versions
sudo apt-get remove --purge python3.*

# Auto-remove any remaining dependencies
sudo apt-get autoremove

# Cleaning up
sudo apt-get autoclean

# Setting required version variables
PYTHON_VERSION="3.8.12"
PIPX_VERSION="1.3.3"

# Updating package list
echo "Updating package list..."
sudo apt update

# Installing dependencies for building Python
echo "Installing dependencies for building Python..."
sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget

# Checking if Python 3.10.12 is already installed
if ! python3 --version | grep -q "$PYTHON_VERSION"; then
    echo "Installing Python $PYTHON_VERSION..."
    cd /tmp
    wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz
    tar -xf Python-$PYTHON_VERSION.tar.xz
    cd Python-$PYTHON_VERSION
    ./configure --enable-optimizations
    make -j `nproc`
    sudo make altinstall
else
    echo "Python $PYTHON_VERSION is already installed."
fi

# Installing pipx
if ! pipx --version | grep -q "$PIPX_VERSION"; then
    echo "Installing pipx $PIPX_VERSION..."
    python3.8 -m pip install --user pipx==$PIPX_VERSION
    python3.8 -m pipx ensurepath
else
    echo "pipx $PIPX_VERSION is already installed."
fi

echo "PIPX Installation completed."

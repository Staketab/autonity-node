#!/bin/bash

echo "Installing Pipx..."
sudo apt update

if ! dpkg -s python3-pip >/dev/null 2>&1; then
  sudo apt install python3-pip
fi

if ! dpkg -s python3.10-venv >/dev/null 2>&1; then
  sudo apt install python3.10-venv
fi

if ! command -v pipx >/dev/null 2>&1; then
  python3 -m pip install --user pipx
fi

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

source $HOME/.bashrc

echo "Pipx installed!"

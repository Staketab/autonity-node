#!/bin/bash

function check_python_compatibility {
    # Check which Python versions are already installed
    echo "Checking existing Python installations..."
    
    REQUIRED_PYTHON=""
    UBUNTU_VERSION=$(lsb_release -r 2>/dev/null | awk '{print $2}' || echo "unknown")
    
    # Determine required Python version based on Ubuntu
    if [[ "$(printf '%s\n' "20.04" "$UBUNTU_VERSION" | sort -V | head -n1)" == "20.04" && "$UBUNTU_VERSION" != "20.04" ]]; then
        REQUIRED_PYTHON="python3.10"
        FALLBACK_PYTHON="python3.8"
    else
        REQUIRED_PYTHON="python3.8"
        FALLBACK_PYTHON="python3.10"
    fi
    
    echo "Ubuntu version: $UBUNTU_VERSION"
    echo "Required Python version: $REQUIRED_PYTHON"
    
    # Check availability of required Python version
    if command -v "$REQUIRED_PYTHON" >/dev/null 2>&1; then
        PYTHON_VERSION="$REQUIRED_PYTHON"
        echo "✓ $REQUIRED_PYTHON is available"
    elif command -v "$FALLBACK_PYTHON" >/dev/null 2>&1; then
        PYTHON_VERSION="$FALLBACK_PYTHON"
        echo "✓ Using fallback $FALLBACK_PYTHON"
    elif command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION="python3"
        PYTHON_VER=$(python3 --version 2>&1 | awk '{print $2}')
        echo "✓ Using system python3 (version $PYTHON_VER)"
        
        # Check version compatibility
        if [[ "$PYTHON_VER" < "3.8" ]]; then
            echo "⚠ Warning: Python version $PYTHON_VER may not be compatible with pipx 1.3.3"
            echo "pipx requires Python 3.8 or higher"
            selective_cleanup
        fi
    else
        echo "❌ No suitable Python version found"
        selective_cleanup
    fi
}

function check_pip_available {
    echo "Checking if pip is available for $PYTHON_VERSION..."
    
    if $PYTHON_VERSION -m pip --version >/dev/null 2>&1; then
        echo "✓ pip is available for $PYTHON_VERSION"
        return 0
    else
        echo "❌ pip is not available for $PYTHON_VERSION"
        return 1
    fi
}

function install_pip {
    echo "Installing pip for $PYTHON_VERSION..."
    
    # Try multiple methods to install pip
    # Method 1: Using get-pip.py
    if command -v wget >/dev/null 2>&1; then
        echo "Downloading get-pip.py..."
        wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
        if [[ -f /tmp/get-pip.py ]]; then
            echo "Installing pip using get-pip.py..."
            $PYTHON_VERSION /tmp/get-pip.py --user
            rm -f /tmp/get-pip.py
            return 0
        fi
    elif command -v curl >/dev/null 2>&1; then
        echo "Downloading get-pip.py..."
        curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
        if [[ -f /tmp/get-pip.py ]]; then
            echo "Installing pip using get-pip.py..."
            $PYTHON_VERSION /tmp/get-pip.py --user
            rm -f /tmp/get-pip.py
            return 0
        fi
    fi
    
    # Method 2: Using ensurepip module
    echo "Trying to install pip using ensurepip..."
    if $PYTHON_VERSION -m ensurepip --user >/dev/null 2>&1; then
        echo "✓ pip installed using ensurepip"
        return 0
    fi
    
    # Method 3: Install python3-pip package
    echo "Installing python3-pip package..."
    sudo apt update
    sudo apt install -y python3-pip
    
    # Method 4: Install pip for specific Python version
    if [[ "$PYTHON_VERSION" == "python3.10" ]]; then
        sudo apt install -y python3.10-pip || true
    elif [[ "$PYTHON_VERSION" == "python3.8" ]]; then
        sudo apt install -y python3.8-pip || true
    fi
    
    return 0
}

function selective_cleanup {
    echo "Installing required Python version..."
    echo "This will only install missing Python packages, not remove existing ones."
    echo ""
    
    # Show what will be installed
    echo "The following packages will be installed:"
    echo "- $REQUIRED_PYTHON"
    echo "- $REQUIRED_PYTHON-venv"
    echo "- $REQUIRED_PYTHON-dev"
    echo "- python3-pip (if not present)"
    echo "- Build dependencies for Python packages"
    echo ""
    
    while true; do
        read -p "Do you want to proceed with installation? (yes/no) " yn
        case $yn in
            [Yy]* ) install_python; break;;
            [Nn]* ) echo "Installation canceled."; exit 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

function install_python {
    echo "Installing Python $REQUIRED_PYTHON and dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install build dependencies
    echo "Installing build dependencies..."
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
                        libnss3-dev libssl-dev libreadline-dev libffi-dev \
                        libsqlite3-dev wget curl lsb-release make
    
    # Install Python and necessary packages
    echo "Installing Python packages..."
    sudo apt install -y python3-lib2to3 python3-distutils python3-pkg-resources \
                        python3-setuptools python3-wheel python3-pip \
                        "$REQUIRED_PYTHON" "$REQUIRED_PYTHON-venv" "$REQUIRED_PYTHON-dev"
    
    # Install pip for specific Python version
    if [[ "$REQUIRED_PYTHON" == "python3.10" ]]; then
        sudo apt install -y python3.10-pip || true
    elif [[ "$REQUIRED_PYTHON" == "python3.8" ]]; then
        sudo apt install -y python3.8-pip || true
    fi
    
    # Check installation
    if command -v "$REQUIRED_PYTHON" >/dev/null 2>&1; then
        PYTHON_VERSION="$REQUIRED_PYTHON"
        echo "✓ $REQUIRED_PYTHON installed successfully"
    else
        echo "❌ Failed to install $REQUIRED_PYTHON"
        exit 1
    fi
}

function install_pipx {
    PIPX_VERSION="1.3.3"
    
    echo "Selected Python version: $PYTHON_VERSION"
    
    # Check Python version
    echo "Checking Python version..."
    $PYTHON_VERSION --version
    
    # Check if pip is available, install if needed
    if ! check_pip_available; then
        echo "pip is not available for $PYTHON_VERSION. Installing pip..."
        install_pip
        
        # Verify pip installation
        if ! check_pip_available; then
            echo "❌ Failed to install pip for $PYTHON_VERSION"
            exit 1
        fi
    fi
    
    # Upgrade pip
    echo "Upgrading pip..."
    $PYTHON_VERSION -m pip install --upgrade pip --user
    
    # Install pipx
    echo "Installing pipx version $PIPX_VERSION..."
    $PYTHON_VERSION -m pip install --user pipx==$PIPX_VERSION
    
    # Set up PATH
    echo "Setting up pipx PATH..."
    PIPX_PATH="$HOME/.local/bin"
    
    # Add to .bashrc if not already added
    if ! grep -qxF "export PATH=\"$PIPX_PATH:\$PATH\"" ~/.bashrc 2>/dev/null; then
        echo "Adding pipx to .bashrc"
        echo "export PATH=\"$PIPX_PATH:\$PATH\"" >> ~/.bashrc
    fi
    
    # Add to current session
    if [[ ":$PATH:" != *":$PIPX_PATH:"* ]]; then
        export PATH="$PIPX_PATH:$PATH"
    fi
    
    # Add to .zshrc if using zsh
    if [[ "$SHELL" == *"zsh"* ]] && [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -qxF "export PATH=\"$PIPX_PATH:\$PATH\"" ~/.zshrc 2>/dev/null; then
            echo "Adding pipx to .zshrc"
            echo "export PATH=\"$PIPX_PATH:\$PATH\"" >> ~/.zshrc
        fi
    fi
    
    # Verify pipx installation
    echo "Verifying pipx installation..."
    if command -v pipx >/dev/null 2>&1; then
        echo "✓ pipx installed successfully"
        pipx --version
    else
        echo "⚠ pipx not found in PATH. Please restart your terminal or run:"
        echo "   export PATH=\"$PIPX_PATH:\$PATH\""
        echo "Then try: pipx --version"
    fi
    
    echo "Installation completed successfully!"
}

function main {
    echo "=== pipx Installation Script ==="
    echo "This script will install pipx version 1.3.3 with a compatible Python version."
    echo ""
    
    # Check Python compatibility
    check_python_compatibility
    
    # Install pipx
    install_pipx
}

# Run main function
main

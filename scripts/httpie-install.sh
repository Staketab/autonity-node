#!/bin/bash

function check_httpie_installed {
    if command -v http >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check_architecture {
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64|arm64|armhf)
            echo "✓ Supported architecture: $ARCH"
            return 0
            ;;
        *)
            echo "⚠ Unsupported architecture: $ARCH"
            echo "This script is designed for amd64, arm64, or armhf systems"
            return 1
            ;;
    esac
}

function install_httpie_official {
    echo "Installing httpie from official repository..."
    
    # Check architecture
    if ! check_architecture; then
        echo "Falling back to pip installation..."
        install_httpie_pip
        return $?
    fi
    
    ARCH=$(dpkg --print-architecture)
    
    # Step 1: Download and add GPG key
    echo "Adding httpie GPG key..."
    if ! curl -SsL https://packages.httpie.io/deb/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/httpie.gpg; then
        echo "❌ Failed to add GPG key"
        return 1
    fi
    
    # Step 2: Add repository
    echo "Adding httpie repository..."
    if ! echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/httpie.gpg] https://packages.httpie.io/deb ./" | sudo tee /etc/apt/sources.list.d/httpie.list > /dev/null; then
        echo "❌ Failed to add repository"
        return 1
    fi
    
    # Step 3: Update package list
    echo "Updating package list..."
    if ! sudo apt update; then
        echo "❌ Failed to update package list"
        return 1
    fi
    
    # Step 4: Install httpie
    echo "Installing httpie..."
    if ! sudo apt install httpie -y; then
        echo "❌ Failed to install httpie from official repository"
        return 1
    fi
    
    return 0
}

function install_httpie_pip {
    echo "Installing httpie using pip..."
    
    # Check if pip3 is available
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user httpie
    elif command -v pip >/dev/null 2>&1; then
        pip install --user httpie
    else
        echo "❌ pip is not available. Please install pip first."
        return 1
    fi
    
    return 0
}

function install_httpie_apt {
    echo "Installing httpie from Ubuntu repository..."
    sudo apt update
    sudo apt install -y httpie
    return $?
}

function main {
    echo "=== HTTPie Installation Script ==="
    echo "This script will install HTTPie HTTP client."
    echo ""
    
    # Check if httpie is already installed
    if check_httpie_installed; then
        HTTPIE_VERSION=$(http --version 2>/dev/null || echo "unknown")
        echo "✓ HTTPie is already installed: $HTTPIE_VERSION"
        echo "If you want to upgrade, you can run:"
        echo "  sudo apt update && sudo apt upgrade httpie"
        echo "  or"
        echo "  pip3 install --user --upgrade httpie"
        return 0
    fi
    
    echo "HTTPie is not installed. Installing..."
    
    # Try official repository first
    if install_httpie_official; then
        echo "✓ HTTPie installed successfully from official repository"
    else
        echo "Official repository installation failed. Trying alternative methods..."
        
        # Try Ubuntu repository
        if install_httpie_apt; then
            echo "✓ HTTPie installed successfully from Ubuntu repository"
        else
            echo "Ubuntu repository installation failed. Trying pip..."
            
            # Try pip installation
            if install_httpie_pip; then
                echo "✓ HTTPie installed successfully using pip"
            else
                echo "❌ All installation methods failed"
                echo "Please install HTTPie manually:"
                echo "  sudo apt install httpie"
                echo "  or"
                echo "  pip3 install --user httpie"
                exit 1
            fi
        fi
    fi
    
    # Verify installation
    echo "Verifying HTTPie installation..."
    if check_httpie_installed; then
        HTTPIE_VERSION=$(http --version 2>/dev/null || echo "unknown")
        echo "✓ HTTPie installation completed successfully: $HTTPIE_VERSION"
        echo "Usage: http --help"
    else
        echo "❌ HTTPie installation verification failed"
        echo "Please check your installation manually with: http --version"
        exit 1
    fi
}

# Run main function
main

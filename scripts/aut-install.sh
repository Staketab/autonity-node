#!/bin/bash

function check_aut_installed {
    if command -v aut >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check_aut_version_compatibility {
    echo "Checking aut version compatibility..."
    
    # Try to run a simple aut command to check for ImportError
    if aut --version >/dev/null 2>&1; then
        echo "✓ aut is working correctly"
        return 0
    else
        echo "⚠ aut may have compatibility issues"
        return 1
    fi
}

function setup_aut_path {
    echo "Setting up aut PATH..."
    PIPX_PATH="$HOME/.local/bin"
    
    # Add to current session if not already in PATH
    if [[ ":$PATH:" != *":$PIPX_PATH:"* ]]; then
        export PATH="$PIPX_PATH:$PATH"
        echo "✓ Added $PIPX_PATH to current session PATH"
    fi
    
    # Verify aut is now accessible
    if command -v aut >/dev/null 2>&1; then
        echo "✓ aut is now accessible in PATH"
        return 0
    else
        echo "❌ aut is still not accessible in PATH"
        echo "Checking if aut binary exists..."
        if [[ -f "$PIPX_PATH/aut" ]]; then
            echo "✓ aut binary exists at $PIPX_PATH/aut"
            echo "Try running: export PATH=\"$PIPX_PATH:\$PATH\""
        else
            echo "❌ aut binary not found at $PIPX_PATH/aut"
        fi
        return 1
    fi
}

function install_aut {
    echo "Installing autonity-cli..."
    export PATH="$HOME/.local/bin:$PATH"
    
    if pipx install autonity-cli; then
        echo "✓ autonity-cli installed successfully"
        return 0
    else
        echo "❌ Failed to install autonity-cli"
        return 1
    fi
}

function upgrade_aut {
    echo "Upgrading autonity-cli to latest version..."
    export PATH="$HOME/.local/bin:$PATH"
    
    if pipx upgrade autonity-cli; then
        echo "✓ autonity-cli upgraded successfully"
        return 0
    else
        echo "❌ Failed to upgrade autonity-cli"
        return 1
    fi
}

function main {
    echo "=== Autonity CLI Installation Script ==="
    echo "This script will install or upgrade autonity-cli using pipx."
    echo ""
    
    # Ensure PATH includes pipx installation directory
    export PATH="$HOME/.local/bin:$PATH"
    
    # Check if pipx is available
    if ! command -v pipx >/dev/null 2>&1; then
        echo "❌ pipx is not installed or not in PATH"
        echo "Please install pipx first by running: make pipx"
        exit 1
    fi
    
    if check_aut_installed; then
        echo "aut is already installed"
        
        # Check if current version has compatibility issues
        if check_aut_version_compatibility; then
            echo "Current aut version is working correctly"
            echo "If you want to upgrade to the latest version, you can run:"
            echo "  pipx upgrade autonity-cli"
            echo "  or"
            echo "  make aut-upgrade"
        else
            echo "Detected compatibility issues with current aut version"
            echo "This may be due to ImportError: cannot import name 'NodeAddress' from 'autonity.validator'"
            echo "Upgrading to the latest version..."
            
            if upgrade_aut; then
                echo "Verifying upgraded installation..."
                setup_aut_path
                if check_aut_version_compatibility; then
                    echo "✓ aut upgrade completed successfully and is working correctly"
                else
                    echo "⚠ aut was upgraded but still has compatibility issues"
                    echo "Please check your Python environment and try reinstalling pipx"
                fi
            else
                echo "❌ Failed to upgrade aut"
                exit 1
            fi
        fi
    else
        echo "aut is not installed. Installing..."
        
        if install_aut; then
            echo "Verifying installation..."
            
            # Setup PATH for current session
            setup_aut_path
            
            if check_aut_installed && check_aut_version_compatibility; then
                echo "✓ aut installation completed successfully"
                echo "You can now use the 'aut' command"
                
                # Show version info
                echo "Installed aut version:"
                aut --version 2>/dev/null || echo "Unable to display version"
            else
                echo "⚠ aut was installed but may have compatibility issues"
                echo "Try upgrading to the latest version:"
                echo "  pipx upgrade autonity-cli"
                echo "  or"
                echo "  make aut-upgrade"
                echo ""
                echo "If aut command is not found, try:"
                echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
                echo "  source ~/.bashrc"
            fi
        else
            echo "❌ Failed to install aut"
            exit 1
        fi
    fi
    
    echo ""
    echo "Usage: aut --help"
    echo "Note: If you experience ImportError issues, upgrade with: pipx upgrade autonity-cli"
    echo ""
    echo "If 'aut' command is not found, restart your terminal or run:"
    echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
}

# Run main function
main

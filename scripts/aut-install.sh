#!/bin/bash

function check_aut_installed {
    if command -v aut >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

echo "Installing Aut..."
export PATH="$HOME/.local/bin:$PATH"
pipx install --force "https://github.com/autonity/aut/releases/download/v${AUT_BINARY_VERSION}/aut-${AUT_BINARY_VERSION}-py3-none-any.whl"

if check_aut_installed; then
    echo "The aut installation was completed successfully."
else
    echo "Error when installing aut."
fi

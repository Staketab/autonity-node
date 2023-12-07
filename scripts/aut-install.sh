#!/bin/bash

function check_aut_installed {
    if command -v aut >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

echo "Installing Aut..."
pipx install git+https://github.com/autonity/aut --force

if check_aut_installed; then
    echo "The aut installation was completed successfully."
else
    echo "Error when installing aut."
fi

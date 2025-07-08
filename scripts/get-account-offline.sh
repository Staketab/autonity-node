#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    echo "Please copy example.env to .env and configure it"
    exit 1
fi

function get_account_from_keyfile {
    local keyfile="$1"
    
    if [ -z "$keyfile" ]; then
        echo "❌ Usage: $0 <keyfile>"
        echo "Example: $0 \$DATADIR/keystore/autonity.key"
        exit 1
    fi
    
    if [ ! -f "$keyfile" ]; then
        echo "❌ Keyfile not found: $keyfile"
        exit 1
    fi
    
    # Extract address from keyfile and add 0x prefix
    ADDRESS=$(jq -r '"0x" + .address' "$keyfile" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ "$ADDRESS" = "null" ] || [ "$ADDRESS" = "0x" ]; then
        echo "❌ Failed to extract address from keyfile"
        echo "Make sure the file contains valid JSON with 'address' field"
        exit 1
    fi
    
    echo "$ADDRESS"
}

function main {
    if [ $# -eq 0 ]; then
        # Default keyfile
        KEYFILE="$DATADIR/keystore/$KEYNAME.key"
    else
        KEYFILE="$1"
    fi
    
    echo "=== Get Account Address from Keyfile ==="
    echo "Keyfile: $KEYFILE"
    echo ""
    
    ADDRESS=$(get_account_from_keyfile "$KEYFILE")
    
    echo "Account address: $ADDRESS"
    
    # Save to file for use in other scripts
    mkdir -p "$DATADIR/signs"
    echo "$ADDRESS" > "$DATADIR/signs/account-address"
    
    echo "Address saved to: $DATADIR/signs/account-address"
}

# Run main function only if script is executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi 
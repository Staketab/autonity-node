#!/bin/bash

# Generate ownership proof for validator registration
# This script uses get-account-offline.sh to extract oracle account address
# and generates ownership proof using Docker

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    echo "Please copy example.env to .env and configure it"
    exit 1
fi

function check_requirements {
    echo "=== Checking Requirements ==="
    
    if [ -z "$TAG" ]; then
        echo "❌ TAG is not set in .env file"
        exit 1
    fi
    
    if [ -z "$ORACLE_KEYFILE" ] || [ ! -f "$ORACLE_KEYFILE" ]; then
        echo "❌ Oracle keyfile not found: $ORACLE_KEYFILE"
        echo "Please create oracle account first: make acc-oracle"
        exit 1
    fi
    
    if [ ! -f "$DATADIR/autonity/autonitykeys" ]; then
        echo "❌ Validator keys not found: $DATADIR/autonity/autonitykeys"
        echo "Please generate validator keys first: make get-enode-offline"
        exit 1
    fi
    
    if [ ! -f "./bin/ethkey" ]; then
        echo "❌ ethkey binary not found: ./bin/ethkey"
        echo "Please make sure ethkey binary is available"
        exit 1
    fi
    
    # Check if password is set in .env or will be requested interactively
    if [ -n "$ORACLE_KEYPASS" ]; then
        echo "🔑 Oracle password found in .env file"
    else
        echo "🔑 Oracle password will be requested interactively"
    fi
    
    echo "✅ All requirements met"
    echo ""
}

function get_oracle_account {
    echo "=== Getting Oracle Account Address ==="
    
    # Use get-account-offline.sh script
    if [ -f "./scripts/get-account-offline.sh" ]; then
        echo "Using get-account-offline script to extract oracle address..."
        
        # Source the script to get the function (safely, won't execute main)
        source ./scripts/get-account-offline.sh
        
        # Use the function directly
        ORACLE_ADDRESS=$(get_account_from_keyfile "$ORACLE_KEYFILE")
        
        if [ $? -ne 0 ] || [ -z "$ORACLE_ADDRESS" ]; then
            echo "❌ Failed to extract oracle address using get-account-offline script"
            echo "Keyfile: $ORACLE_KEYFILE"
            exit 1
        fi
        
        # Save oracle address
        mkdir -p "$DATADIR/signs"
        echo "$ORACLE_ADDRESS" > "$DATADIR/signs/oracle-address"
        
        echo "✅ Oracle account address extracted"
        echo "   Oracle address: $ORACLE_ADDRESS"
        echo "   Saved to: $DATADIR/signs/oracle-address"
        echo ""
    else
        echo "❌ get-account-offline.sh script not found"
        echo "Make sure the script exists: ./scripts/get-account-offline.sh"
        exit 1
    fi
}

function generate_ownership_proof {
    echo "=== Generating Ownership Proof ==="
    
    # Get oracle private key
    echo "Extracting oracle private key..."
    chmod +x ./bin/ethkey
    echo "Using oracle keyfile: $ORACLE_KEYFILE"
    
    # Try to extract private key with password from .env first
    ORACLE_PRIV_OUTPUT=""
    if [ -n "$ORACLE_KEYPASS" ]; then
        echo "Trying password from .env file..."
        
        # Try multiple methods to pass password to ethkey
        # Method 1: printf with newline
        ORACLE_PRIV_OUTPUT=$(printf '%s\n' "$ORACLE_KEYPASS" | ./bin/ethkey inspect --json --private "$ORACLE_KEYFILE" 2>/dev/null)
        
        # Method 2: If method 1 failed, try with expect if available
        if [ -z "$ORACLE_PRIV_OUTPUT" ] && command -v expect >/dev/null 2>&1; then
            echo "Trying with expect..."
            ORACLE_PRIV_OUTPUT=$(expect -c "
                spawn ./bin/ethkey inspect --json --private $ORACLE_KEYFILE
                expect \"Password:\"
                send \"$ORACLE_KEYPASS\r\"
                expect eof
            " 2>/dev/null)
        fi
        
        # Method 3: Use here-string
        if [ -z "$ORACLE_PRIV_OUTPUT" ]; then
            echo "Trying with here-string..."
            ORACLE_PRIV_OUTPUT=$(./bin/ethkey inspect --json --private "$ORACLE_KEYFILE" <<< "$ORACLE_KEYPASS" 2>/dev/null)
        fi
        
        # Method 4: Use temporary file
        if [ -z "$ORACLE_PRIV_OUTPUT" ]; then
            echo "Trying with temporary file..."
            TEMP_PASSWD_FILE=$(mktemp)
            echo "$ORACLE_KEYPASS" > "$TEMP_PASSWD_FILE"
            ORACLE_PRIV_OUTPUT=$(./bin/ethkey inspect --json --private "$ORACLE_KEYFILE" < "$TEMP_PASSWD_FILE" 2>/dev/null)
            rm -f "$TEMP_PASSWD_FILE"
        fi
        
        if [ -n "$ORACLE_PRIV_OUTPUT" ] && echo "$ORACLE_PRIV_OUTPUT" | grep -q "PrivateKey"; then
            echo "✅ Successfully extracted private key using .env password"
        else
            echo "❌ Failed to extract private key with .env password using automated methods"
            ORACLE_PRIV_OUTPUT=""
        fi
    fi
    
    # If .env password failed or not set, ask user for interactive input
    if [ -z "$ORACLE_PRIV_OUTPUT" ]; then
        echo ""
        echo "Automated password input failed. Please enter the Oracle account password manually:"
        echo "Running: ./bin/ethkey inspect --json --private $ORACLE_KEYFILE"
        echo ""
        
        # Run ethkey directly for interactive input
        ORACLE_PRIV_OUTPUT=$(./bin/ethkey inspect --json --private "$ORACLE_KEYFILE" 2>/dev/null)
        
        if [ $? -ne 0 ] || [ -z "$ORACLE_PRIV_OUTPUT" ]; then
            echo "❌ Failed to extract oracle private key"
            echo "Please check:"
            echo "- Password is correct"
            echo "- Keyfile is valid: $ORACLE_KEYFILE"
            echo "- ethkey binary is working"
            exit 1
        fi
        
        echo "✅ Successfully extracted private key with interactive input"
    fi
    
    # Clean the output - extract only JSON part (everything from first '{' to last '}')
    CLEAN_JSON=$(echo "$ORACLE_PRIV_OUTPUT" | sed -n '/{/,/}/p' | tr -d '\n' | sed 's/.*{/{/' | sed 's/}.*/}/')
    
    if [ -z "$CLEAN_JSON" ]; then
        echo "❌ Failed to extract JSON from ethkey output"
        echo "Raw output: $ORACLE_PRIV_OUTPUT"
        exit 1
    fi
    
    echo "Extracted JSON: $CLEAN_JSON"
    
    ORACLE_PRIVATE_KEY=$(echo "$CLEAN_JSON" | jq -r '.PrivateKey' 2>/dev/null)
    
    if [ -z "$ORACLE_PRIVATE_KEY" ] || [ "$ORACLE_PRIVATE_KEY" = "null" ]; then
        echo "❌ Failed to extract PrivateKey from JSON"
        echo "Clean JSON: $CLEAN_JSON"
        exit 1
    fi
    
    echo "✅ Private key extracted successfully"
    
    # Save private key to temporary file
    echo "$ORACLE_PRIVATE_KEY" > "$ORACLE_PRIV_KEYFILE"
    
    # Get oracle account address  
    ORACLE_ADDRESS=$(cat "$DATADIR/signs/oracle-address")
    
    # Generate ownership proof
    echo "Generating ownership proof..."
    sudo docker rm -f autonity-proof 2>/dev/null || true
    
    PROOF_OUTPUT=$(sudo docker run -t -i --volume "$DATADIR":/autonity-chaindata --volume "$ORACLE_PRIV_KEYFILE":/oracle.key --name autonity-proof --rm "$TAG" genOwnershipProof --autonitykeys ./autonity-chaindata/autonity/autonitykeys --oraclekey oracle.key "$ORACLE_ADDRESS" 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to generate ownership proof"
        echo "Docker output:"
        echo "$PROOF_OUTPUT"
        exit 1
    fi
    
    # Extract proof from output
    PROOF=$(echo "$PROOF_OUTPUT" | grep -o '0x[0-9a-fA-F]*' | tail -1)
    
    if [ -z "$PROOF" ]; then
        echo "❌ Failed to extract ownership proof from output"
        echo "Docker output:"
        echo "$PROOF_OUTPUT"
        exit 1
    fi
    
    echo "$PROOF" > "$DATADIR/signs/proof"
    
    echo "✅ Ownership proof generated"
    echo "   Oracle address: $ORACLE_ADDRESS"
    echo "   Proof: $PROOF"
    echo "   Saved to: $DATADIR/signs/proof"
    echo ""
}

function create_summary {
    echo "=== Creating Summary ==="
    
    ORACLE_ADDRESS=$(cat "$DATADIR/signs/oracle-address" 2>/dev/null)
    PROOF=$(cat "$DATADIR/signs/proof" 2>/dev/null)
    
    cat > "$DATADIR/signs/ownership-proof-summary.txt" << EOF
=== Autonity Ownership Proof Summary ===
Generated: $(date)
Docker Image: $TAG

=== Oracle Information ===
Oracle Address: $ORACLE_ADDRESS
Oracle Keyfile: $ORACLE_KEYFILE
Oracle Private Key File: $ORACLE_PRIV_KEYFILE

=== Ownership Proof ===
Proof: $PROOF

=== Files Generated ===
- Oracle address: $DATADIR/signs/oracle-address
- Ownership proof: $DATADIR/signs/proof
- Oracle private key: $ORACLE_PRIV_KEYFILE
- This summary: $DATADIR/signs/ownership-proof-summary.txt

=== Usage ===
Use the ownership proof for validator registration:
- Oracle Address: $ORACLE_ADDRESS
- Ownership Proof: $PROOF

=== Security Note ===
Keep the oracle private key file secure: $ORACLE_PRIV_KEYFILE
EOF

    echo "✅ Summary created: $DATADIR/signs/ownership-proof-summary.txt"
}

function main {
    echo "=== Generate Ownership Proof ==="
    echo "This script generates ownership proof for validator registration"
    echo ""
    
    check_requirements
    get_oracle_account
    generate_ownership_proof
    create_summary
    
    echo ""
    echo "🎉 === OWNERSHIP PROOF COMPLETE ==="
    echo ""
    echo "📋 Summary:"
    echo "   Oracle Address: $(cat "$DATADIR/signs/oracle-address")"
    echo "   Ownership Proof: $(cat "$DATADIR/signs/proof")"
    echo ""
    echo "📁 Files saved to: $DATADIR/signs/"
    echo "📄 Summary: $DATADIR/signs/ownership-proof-summary.txt"
    echo ""
    echo "🚀 Ready for validator registration!"
}

# Run main function
main 
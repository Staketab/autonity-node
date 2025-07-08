#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    echo "Please copy example.env to .env and configure it"
    exit 1
fi

function generate_validator_keys {
    echo "=== Generating Validator Keys ==="
    
    # Run get-enode-offline script
    if [ -f "./scripts/get-enode-offline.sh" ]; then
        chmod +x ./scripts/get-enode-offline.sh
        echo "Running get-enode-offline..."
        ./scripts/get-enode-offline.sh
    else
        echo "❌ get-enode-offline.sh script not found"
        exit 1
    fi
    
    echo "✅ Validator keys generated"
    echo ""
}

function get_consensus_key {
    echo "=== Getting Consensus Key ==="
    
    # Make sure ethkey is executable
    if [ ! -f "./bin/ethkey" ]; then
        echo "❌ ethkey binary not found: ./bin/ethkey"
        exit 1
    fi
    
    chmod +x ./bin/ethkey
    
    # Generate consensus key
    echo "Extracting consensus key..."
    ./bin/ethkey autinspect "$NODEKEY_PATH" --json | tee "$DATADIR/signs/consensus-key"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to extract consensus key"
        exit 1
    fi
    
    CONSENSUS_KEY=$(jq -r '.ConsensusPublicKey' "$DATADIR/signs/consensus-key" 2>/dev/null)
    
    if [ -z "$CONSENSUS_KEY" ] || [ "$CONSENSUS_KEY" = "null" ]; then
        echo "❌ Failed to get consensus key"
        exit 1
    fi
    
    echo "✅ Consensus key extracted"
    echo "   Consensus key: $CONSENSUS_KEY"
    echo "   Saved to: $DATADIR/signs/consensus-key"
    echo ""
}

function generate_ownership_proof {
    echo "=== Generating Ownership Proof ==="
    
    # Run generate-ownership-proof script
    if [ -f "./scripts/generate-ownership-proof.sh" ]; then
        chmod +x ./scripts/generate-ownership-proof.sh
        echo "Running generate-ownership-proof..."
        ./scripts/generate-ownership-proof.sh
    else
        echo "❌ generate-ownership-proof.sh script not found"
        exit 1
    fi
    
    echo "✅ Ownership proof generated"
    echo ""
}

function create_combined_summary {
    echo "=== Creating Combined Summary ==="
    
    # Read generated data
    VALIDATOR_ADDRESS=$(cat "$DATADIR/signs/validator-address" 2>/dev/null)
    ENODE=$(cat "$DATADIR/signs/enode" 2>/dev/null)
    CONSENSUS_KEY=$(jq -r '.ConsensusPublicKey' "$DATADIR/signs/consensus-key" 2>/dev/null)
    ORACLE_ADDRESS=$(cat "$DATADIR/signs/oracle-address" 2>/dev/null)
    PROOF=$(cat "$DATADIR/signs/proof" 2>/dev/null)
    
    cat > "$DATADIR/signs/validator-setup-summary.txt" << EOF
=== Autonity Validator Setup Summary ===
Generated: $(date)
Docker Image: $TAG

=== Validator Information ===
Validator Address: $VALIDATOR_ADDRESS
Enode: $ENODE
Consensus Key: $CONSENSUS_KEY

=== Oracle Information ===
Oracle Address: $ORACLE_ADDRESS
Oracle Keyfile: $ORACLE_KEYFILE
Oracle Private Key File: $ORACLE_PRIV_KEYFILE

=== Ownership Proof ===
Proof: $PROOF

=== Files Generated ===
- Validator address: $DATADIR/signs/validator-address
- Enode: $DATADIR/signs/enode
- Consensus key: $DATADIR/signs/consensus-key
- Oracle address: $DATADIR/signs/oracle-address
- Ownership proof: $DATADIR/signs/proof
- Oracle private key: $ORACLE_PRIV_KEYFILE
- This summary: $DATADIR/signs/validator-setup-summary.txt

=== Validator Registration Command ===
You can register your validator using these parameters:
- Enode: $ENODE
- Oracle Address: $ORACLE_ADDRESS
- Consensus Key: $CONSENSUS_KEY
- Ownership Proof: $PROOF

=== Security Notes ===
- Keep the oracle private key file secure: $ORACLE_PRIV_KEYFILE
- Keep the validator keys secure: $DATADIR/autonity/autonitykeys
- Back up all generated files before continuing
EOF

    echo "✅ Combined summary created: $DATADIR/signs/validator-setup-summary.txt"
}

function main {
    echo "=== Prepare Validator Offline ==="
    echo "This script prepares a complete validator setup offline"
    echo ""
    
    generate_validator_keys
    get_consensus_key
    generate_ownership_proof
    create_combined_summary
    
    echo ""
    echo "🎉 === VALIDATOR SETUP COMPLETE ==="
    echo ""
    echo "📋 Summary:"
    echo "   Validator Address: $(cat "$DATADIR/signs/validator-address")"
    echo "   Enode: $(cat "$DATADIR/signs/enode")"
    echo "   Consensus Key: $(jq -r '.ConsensusPublicKey' "$DATADIR/signs/consensus-key")"
    echo "   Oracle Address: $(cat "$DATADIR/signs/oracle-address")"
    echo "   Ownership Proof: $(cat "$DATADIR/signs/proof")"
    echo ""
    echo "📁 Files saved to: $DATADIR/signs/"
    echo "📄 Summary: $DATADIR/signs/validator-setup-summary.txt"
    echo ""
    echo "🚀 Ready for validator registration!"
}

# Run main function
main 
#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    echo "Please copy example.env to .env and configure it"
    exit 1
fi

function check_variables {
    if [ -z "$YOUR_IP" ]; then
        echo "❌ YOUR_IP is not set in .env file"
        echo "Please set YOUR_IP in .env file to your node's IP address"
        echo "Example: YOUR_IP=192.168.1.100"
        exit 1
    fi
    
    if [ -z "$TAG" ]; then
        echo "❌ TAG is not set in .env file"
        echo "Please set TAG in .env file to autonity docker image"
        exit 1
    fi
    
    if [ -z "$DATADIR" ]; then
        echo "❌ DATADIR is not set in .env file"
        exit 1
    fi
}

function generate_keys {
    echo "=== Autonity Offline Key Generation ==="
    echo "Docker image: $TAG"
    echo "Data directory: $DATADIR"
    echo "Your IP: $YOUR_IP"
    echo ""
    
    # Create necessary directories
    echo "Creating directories..."
    mkdir -p "$DATADIR/autonity" "$DATADIR/signs"
    
    # Run genAutonityKeys command
    echo "Generating validator node keys using Docker..."
    echo "Command: docker run --volume $DATADIR:/autonity-chaindata $TAG genAutonityKeys --writeaddress /autonity-chaindata/autonity/autonitykeys"
    echo ""
    
    # Remove existing container if it exists
    sudo docker rm -f autonity-keygen 2>/dev/null || true
    
    # Capture output from Docker command (removed -t -i flags to avoid hanging)
    OUTPUT=$(sudo docker run --volume "$DATADIR":/autonity-chaindata --name autonity-keygen --rm "$TAG" genAutonityKeys --writeaddress /autonity-chaindata/autonity/autonitykeys 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker command failed"
        echo "Output:"
        echo "$OUTPUT"
        exit 1
    fi
    
    echo "Docker output:"
    echo "$OUTPUT"
    echo ""
    
    # Extract information from output
    NODE_ADDRESS=$(echo "$OUTPUT" | grep "Node address:" | sed 's/.*Node address: //')
    NODE_PUBLIC_KEY=$(echo "$OUTPUT" | grep "Node public key:" | sed 's/.*Node public key: 0x//')
    CONSENSUS_PUBLIC_KEY=$(echo "$OUTPUT" | grep "Consensus public key:" | sed 's/.*Consensus public key: //')
    
    # Validate extracted data
    if [ -z "$NODE_PUBLIC_KEY" ] || [ -z "$NODE_ADDRESS" ]; then
        echo "❌ Failed to extract node information from Docker output"
        echo "Output was:"
        echo "$OUTPUT"
        echo ""
        echo "Expected format:"
        echo "Node address: 0x..."
        echo "Node public key: 0x..."
        echo "Consensus public key: 0x..."
        exit 1
    fi
    
    # Generate enode
    ENODE="enode://$NODE_PUBLIC_KEY@$YOUR_IP:30303"
    
    # Display results
    echo "=== Generated Keys ==="
    echo "Node address: $NODE_ADDRESS"
    echo "Node public key: 0x$NODE_PUBLIC_KEY"
    echo "Consensus public key: $CONSENSUS_PUBLIC_KEY"
    echo ""
    echo "=== Generated enode ==="
    echo "$ENODE"
    echo ""
    
    # Save enode to file
    echo "$ENODE" > "$DATADIR/signs/enode-offline"
    
    # Save all information to summary file
    cat > "$DATADIR/signs/keys-summary.txt" << EOF
=== Autonity Validator Keys Generated ===
Generated: $(date)
Docker Image: $TAG
Your IP: $YOUR_IP

Node address: $NODE_ADDRESS
Node public key: 0x$NODE_PUBLIC_KEY
Consensus public key: $CONSENSUS_PUBLIC_KEY

Enode: $ENODE

Files saved:
- Keys: $DATADIR/autonity/
- Enode: $DATADIR/signs/enode-offline
- Summary: $DATADIR/signs/keys-summary.txt
EOF
    
    echo "✅ Keys and enode generated successfully!"
    echo ""
    echo "📁 Files saved:"
    echo "   Keys: $DATADIR/autonity/autonitykeys"
    echo "   Enode: $DATADIR/signs/enode-offline"
    echo "   Summary: $DATADIR/signs/keys-summary.txt"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Use the enode URL for validator registration"
    echo "   2. Keep the keys safe and secure"
    echo "   3. Use 'cat $DATADIR/signs/enode-offline' to get enode URL"
}

function main {
    check_variables
    generate_keys
}

# Run main function
main 
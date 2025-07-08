#!/bin/bash

echo "=== .env File Checker ==="

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found"
    echo "Please copy example.env to .env:"
    echo "   cp example.env .env"
    echo "Then edit .env file with your settings"
    exit 1
fi

echo "✅ .env file found"

# Load and check variables
source .env

echo ""
echo "=== Checking Variables ==="

# Check TAG
if [ -z "$TAG" ]; then
    echo "❌ TAG is not set"
else
    echo "✅ TAG: $TAG"
fi

# Check DATADIR
if [ -z "$DATADIR" ]; then
    echo "❌ DATADIR is not set"
else
    echo "✅ DATADIR: $DATADIR"
fi

# Check CHAIN
if [ -z "$CHAIN" ]; then
    echo "❌ CHAIN is not set"
elif [[ "$CHAIN" != "piccadilly" && "$CHAIN" != "bakerloo" ]]; then
    echo "⚠️  CHAIN: $CHAIN (should be 'piccadilly' or 'bakerloo')"
else
    echo "✅ CHAIN: $CHAIN"
fi

# Check YOUR_IP
if [ -z "$YOUR_IP" ]; then
    echo "❌ YOUR_IP is not set (required for get-enode-offline)"
    echo "   Please set YOUR_IP to your server's public IP address"
    echo "   Example: YOUR_IP=192.168.1.100"
else
    echo "✅ YOUR_IP: $YOUR_IP"
fi

# Check KEYPASS
if [ -z "$KEYPASS" ]; then
    echo "⚠️  KEYPASS is not set (required for account operations)"
else
    echo "✅ KEYPASS: [hidden]"
fi

# Check ORACLE_KEYPASS
if [ -z "$ORACLE_KEYPASS" ]; then
    echo "⚠️  ORACLE_KEYPASS is not set (required for oracle operations)"
else
    echo "✅ ORACLE_KEYPASS: [hidden]"
fi

echo ""
echo "=== Summary ==="

# Count issues
ERRORS=0
WARNINGS=0

if [ -z "$TAG" ] || [ -z "$DATADIR" ] || [ -z "$CHAIN" ] || [ -z "$YOUR_IP" ]; then
    ERRORS=$((ERRORS + 1))
fi

if [[ "$CHAIN" != "piccadilly" && "$CHAIN" != "bakerloo" ]] && [ -n "$CHAIN" ]; then
    WARNINGS=$((WARNINGS + 1))
fi

if [ -z "$KEYPASS" ] || [ -z "$ORACLE_KEYPASS" ]; then
    WARNINGS=$((WARNINGS + 1))
fi

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Your .env file is properly configured."
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Configuration is mostly correct but has $WARNINGS warning(s)."
    echo "   You can proceed, but some features may not work properly."
else
    echo "❌ Configuration has $ERRORS error(s) and $WARNINGS warning(s)."
    echo "   Please fix the errors before proceeding."
    exit 1
fi 
# Autonity Node and Validator setup
Setup Autonity RPC and Validator nodes.

# Content:
- [Requirements](#requirements)
- [Initialise the repository](#initialise-the-repository)
- [Install components](#install-components)
- [Setup the nodes](#setup-the-nodes)
    - [Set variables](#set-variables)
    - [Start the Autonity node](#start-the-autonity-node)
    - [View node logs](#view-node-logs)
    - [Stop the node](#stop-the-node)
    - [Keys](#keys)
        - [Create an account](#create-an-account)
        - [Create an Oracle account](#create-an-oracle-account)
    - [Register in the Piccadilly Circus Games](#register-in-the-piccadilly-circus-games)
        - [Sign Validator](#sign-validator)
        - [Sign RPC](#sign-rpc)
- [Start the Oracle node](#start-the-oracle-node)
- [CEX commands](#cex-commands)
- [Other useful commands](#other-useful-commands)
- [Support](#support)

<a name="requirements"></a>
# Requirements:
```
Python v3.8 or v3.10, pipx v1.3.3, pip, make, httpie
```

<a name="initialise-the-repository"></a>
# Initialise the repository:

```bash
git clone https://github.com/Staketab/autonity-node.git
cd autonity-node
git checkout piccadilly
```

<a name="install-components"></a>
# Install components:
You can set them up yourself or use the commands provided below:
```
make pipx                        # Install Pipx
make httpie                      # Install http
make aut                         # Install aut binary
make aut-upgrade                 # Upgrade aut binary to latest version
make autrc                       # Create .autrc file
# or
make all                         # Install Pipx, httpie, make, aut binary, and create .autrc file
```


<a name="setup-the-nodes"></a>
# Setup the nodes

<a name="set-variables"></a>
## Set variables:
Carefully fill in the Variables in the `.env` file.  
You can also change other variable values as you see fit. This includes ports, key names, etc.
```
KEYPASS             # Account key password
ORACLE_KEYPASS      # Oracle Account key password
YOUR_IP             # Node IP
```

<a name="start-the-autonity-node"></a>
## Start the Autonity node:
```bash
make up
```

<a name="view-node-logs"></a>
## View node logs:
```bash
make log
```

<a name="stop-the-node"></a>
## Stop the node:
```bash
make down
```

<a name="keys"></a>
# Keys
<a name="create-an-account"></a>
## Create an account
Your account will be generated in the `${DATADIR}/keystore` folder
```bash
make acc                         # Create an account
```

Also get json account data or account balance in the specified tokens:
```bash
make get-acc                     # Get the account address
make acc-balance                 # Get the account balance. Pass the NTN variable if you need ntn balance or TOKEN=12c1... if token balance. Example: `make acc-balance NTN=1` or `make acc-balance TOKEN=12c1...`
```

<a name="create-an-oracle-account"></a>
## Create an Oracle account
Your account will be generated in the `${DATADIR}/keystore` folder
```bash
make acc-oracle                  # Create an Oracle account
```

Also get json oracle account data or oracle account balance in the specified tokens:
```bash
make get-oracle-acc              # Get the Oracle account address
make oracle-balance              # Get the Oracle account balance. Pass the NTN variable if you need ntn balance or TOKEN=12c1... if token balance. Example: `make oracle-balance NTN=1` or `make oracle-balance TOKEN=12c1...`
```

<a name="register-in-the-piccadilly-circus-games"></a>
# Register in the Piccadilly Circus Games
To register in the Game you need to generate a signature and send your account address generated in section [Create an account](#create-an-account) and signature hash to the registration form:

```bash
make sign                        # Make a signature "I have read and agree ..."
```
And fill out the form at the following link:
https://game.autonity.org/getting-started/register.html

> To proceed further it is important to wait for your account to be funded.

<a name="sign-validator"></a>
## Sign Validator
All generated data will be displayed and saved to the `${DATADIR}/sign` folder:

```bash
make validator                   # Run the script to create the "validator onboarded" signature for the Validator node.
make get-enode                   # Get ENODE
```
Or use each command in order:
```bash
make dir                         # Will create all necessary folders
make get-priv                    # Get the PRIVATE KEY of the Oracle account
make save-priv                   # Save the PRIVATE KEY to a file, pass the PRIVKEY variable. Example: "make save-priv PRIVKEY=9190..."
make genOwnershipProof           # Get the genOwnershipProof proof
make add-validator               # Add the validator address to the .autrc file to avoid specifying the --validator flag in commands
make get-ckey
make register                    # Register the validator in the network
make import                      # Import Validator nodekey
make sign-onboard                # Create the "validator onboarded" signature for the validator node
make get-enode                   # Get ENODE
```
And fill out the form at the following link:
https://game.autonity.org/awards/register-validator.html

<a name="sign-rpc"></a>
## Sign RPC
All generated data will be displayed and saved to the `${DATADIR}/sign` folder:

```bash
make rpc                         # Run the script to create the "validator onboarded" signature for the Validator node.
make get-enode                   # Get ENODE
```
Or use each command in order:
```bash
make dir                         # Will create all necessary folders
make import                      # Import RPC nodekey
make sign-rpc                    # Create the "public rpc" signature for the RPC node
make get-enode                   # Get ENODE
```
And fill out the form at the following link:
https://game.autonity.org/awards/register-node.html

<a name="cex-commands"></a>
# Start the Oracle node

```bash
make up-oracle
```
## View oracle logs:
```bash
make log-o
```
## Stop the node:
```bash
make down
```

<a name="cex-commands"></a>
# CEX commands
To start using CEX you need to generate API keys:
All generated data will be displayed and saved to the `${DATADIR}/api-key` file:

```bash
make api                         # Generate an API KEY
```
Commands to work with CEX:
```bash
make cex-balance                 # GET all account balances
make get-orderbooks              # GET all order books
make ntn-quote                   # GET order book ntn quote
make atn-quote                   # GET order book atn quote
make buy-ntn                     # POST buy-ntn order. Pass the PRICE and AMOUNT variable. Example: "make buy-ntn PRICE=10.00 AMOUNT=10"
make sell-ntn                    # POST sell-ntn order. Pass the PRICE and AMOUNT variable. Example: "make sell-ntn PRICE=10.00 AMOUNT=10"
make ntn-withdraw                # Withdraw ntn to your account. Pass the AMOUNT variable. Example: "make ntn-withdraw AMOUNT=10"
make buy-atn                     # POST buy-atn order. Pass the PRICE and AMOUNT variable. Example: "make buy-atn PRICE=10.00 AMOUNT=10" 
make sell-atn                    # POST sell-atn order. Pass the PRICE and AMOUNT variable. Example: "make sell-atn PRICE=10.00 AMOUNT=10"
make atn-withdraw                # Withdraw ntn to your account. Pass the AMOUNT variable. Example: "make atn-withdraw AMOUNT=10"
make get-orders                  # GET only open orders.
make get-orders-all              # GET all your orders.
make get-order-id                # GET order by ID. Pass the ID variable. Example: "make get-order-id ID=1231"
make delete-order-id             # DELETE order by ID. Pass the ID variable. Example: "make get-order-id ID=1231"
```

<a name="other-useful-commands"></a>
# Other useful commands

```bash
make up-oracle                   # Start the Oracle node container
make down                        # Stop all containers
make log-o                       # View Oracle node logs
make clean                       # Stop all containers and clean the DATADIR with the blockchain database
make get-enode                   # Get ENODE from running node
make get-enode-offline           # Generate validator keys and ENODE offline using Docker
make compute                     # Get the validator address
make bond                        # Bond tokens, pass the AMOUNT variable. Example: `make bond AMOUNT=0.5`
make unbond                      # UnBond tokens, pass the AMOUNT variable. Example: `make unbond AMOUNT=0.5`
make list                        # Check if your validator is in the list of all validators
make get-comm                    # Check if your validator is in the list of all committees
make send                        # Create a token transfer transaction. Pass the RECIPIENT and AMOUNT. Example: "make send RECIPIENT=0xf14 AMOUNT=0.2". Pass the NTN variable if you need to transfer ntn or TOKEN=12c1... if transfer token. Example: `make send RECIPIENT=0xf14 AMOUNT=0.2 NTN=1` or `make send RECIPIENT=0xf14 AMOUNT=0.2 TOKEN=12c1...`
make val-info                    # View validator status
make aut-upgrade                 # Upgrade aut binary to latest version (fixes ImportError issues)
```

<a name="support"></a>
# Support
For any questions related to Autonity Tool script you can contact here:

```bash
Discord: duccaofficial
```

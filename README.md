# Autonity Node and Validator setup
Setup Autonity RPC and Validator nodes.

## 1. Clone the repository:

```bash
git clone https://github.com/Staketab/autonity-node.git
cd autonity-node
git checkout piccadilly
```
### Requirements:
```
Python v3.8 or v3.10, pipx v1.3.3, pip, make
```
You can set them up yourself or use the commands provided below:
```
make pipx                        # Install Pipx
make aut                         # Install aut binary
make autrc                       # Create .autrc file
# or
make all                         # Install Pipx, aut binary, and create .autrc file
```

## 2. Carefully fill in the Variables in the .env file:
You can also change other variable values as you see fit. This includes ports, key names, etc.
```
KEYPASS             # Account key password
ORACLE_KEYPASS      # Oracle Account key password
YOUR_IP             # Node IP
```

## 3. Launch the Autonity Node:
```bash
make up
```
## 4. View Node Logs:
```bash
make log
```

## 5. View Node Logs:
```bash
make log
```

## Useful Information on All Commands:
```
make pipx                        # Install Pipx
make aut                         # Install aut binary
make autrc                       # Create .autrc file
make all                         # Install Pipx, aut binary, and create .autrc file
make rpc                         # Run the script to create the "public rpc" signature for the RPC node
make validator                   # Run the script to create the "validator onboarded" signature for the Validator node
make up                          # Start the node container
make up-oracle                   # Start the Oracle node container
make down                        # Stop all containers
make log                         # View node logs
make log-o                       # View Oracle node logs
make clean                       # Stop all containers and clean the DATADIR with the blockchain database
make acc                         # Create an account
make acc-oracle                  # Create an Oracle account
make get-acc                     # Get the account address
make get-oracle-acc              # Get the Oracle account address
make acc-balance                 # Get the account balance. Pass the NTN variable if you need ntn balance or TOKEN=12c1... if token balance. Example: `make acc-balance NTN=1` or `make acc-balance TOKEN=12c1...`
make oracle-balance              # Get the Oracle account balance. Pass the NTN variable if you need ntn balance or TOKEN=12c1... if token balance. Example: `make oracle-balance NTN=1` or `make oracle-balance TOKEN=12c1...`
make sign                        # Make a signature "I have read and agree ..."
make get-enode                   # Get ENODE
make get-priv                    # Get the PRIVATE KEY of the Oracle account
make save-priv                   # Save the PRIVATE KEY to a file, pass the PRIVKEY variable. Example: "make save-priv PRIVKEY=9190..."
make genOwnershipProof           # Get the genOwnershipProof proof
make compute                     # Get the validator address
make add-validator               # Add the validator address to the .autrc file to avoid specifying the --validator flag in commands
make register                    # Register the validator in the network
make bond                        # Bond tokens, pass the AMOUNT variable. Example: `make bond AMOUNT=0.5`
make unbond                      # UnBond tokens, pass the AMOUNT variable. Example: `make unbond AMOUNT=0.5`
make list                        # Check if your validator is in the list of all validators
make get-comm                    # Check if your validator is in the list of all committees
make import                      # Import nodekey, needed for signing "validator onboarded"
make sign-onboard                # Create the "validator onboarded" signature for the validator node
make sign-rpc                    # Create the "public rpc" signature for the RPC node
make send                        # Create a token transfer transaction. Pass the RECEPIENT and AMOUNT. Example: "make send RECEPIENT=0xf14 AMOUNT=0.2". Pass the NTN variable if you need to transfer ntn or TOKEN=12c1... if transfer token. Example: `make send RECEPIENT=0xf14 AMOUNT=0.2 NTN=1` or `make send RECEPIENT=0xf14 AMOUNT=0.2 TOKEN=12c1...`
make val-info                    # View validator status
```
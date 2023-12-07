# MINA NODE SETUP
Setup Mina Operator node for Testworld.

## 1. Clone repository:

```bash
git clone https://github.com/Staketab/mina-testworld-operator.git
cd mina-testworld-operator
```
## 2. Copy your data (Important)

Copy your keys (community-00-key and community-00-key.pub) in your `/home/user/keys/` or `/root/keys/` folder.  

### Then set permittions:
```bash
chmod 700 $HOME/keys
chmod 600 $HOME/keys/community-00-key
```

## 3. Generate LIB_P2P Keystore
```bash
make setup
```
## 4. Start the Node
Run this command to start the node:  
```bash
make op
```

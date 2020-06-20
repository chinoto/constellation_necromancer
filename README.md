# Constellation Necromancer
SystemD service files and script to handle fetching current version and restarting of a Constellation node.

## Setup
Run this on Ubuntu to install the dependencies `sudo apt install wget curl aria2 jq`.

Copy the service files to `/etc/systemd/system/` and adjust them as needed (keystore credentials, workdir of constellation) and copy necromancer.sh to your constellation directory. `systemctl daemon-reload` may be necessary for systemd to recognize the service files being added.

If this is for testnet, make sure to switch the comments in necromancer.sh (TODO: switch behavior based on argument).

 Start the node with `systemctl restart constellation_necromancer.service`.

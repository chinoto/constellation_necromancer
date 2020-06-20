# Constellation Necromancer
SystemD service files and script to handle fetching current version and restarting of a Constellation node.

## Setup
Copy the service files to `/etc/systemd/system/` and adjust them as needed (keystore credentials, workdir of constellation) and copy necromancer.sh to your constellation directory. `systemctl daemon-reload` may be necessary for system.

If this is for testnet, make sure to switch the comments in necromancer.sh (TODO: switch behavior based on argument).

 Start the node with `systemctl restart constellation_necromancer.service`.

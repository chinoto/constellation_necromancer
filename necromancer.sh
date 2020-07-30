#!/bin/bash
if [[ -z $MY_USER ]]; then MY_USER=$USER; fi
# Mainnet
LB='http://lb.constellationnetwork.io'
# Testnet
# LB='http://cl-lb-alb-testnet-1216020584.us-west-1.elb.amazonaws.com'

OUT=$(curl -sf $LB:9000/cluster/info)
if [[ -z $OUT ]]; then echo 'Load balancer did not return'; exit 1; fi
if [[ -z $(echo $OUT | jq '.') ]]; then echo 'Invalid JSON'; exit 1; fi

MY_IP=$(curl -sfL ipecho.net/plain)
if [[ -z $MY_IP ]]; then echo 'Failed to get IP of self' && exit 1; fi

SELF=$(echo $OUT | jq '.[] | select(.ip.host == "'$MY_IP'")')
echo -n 'Node Status: '; echo $SELF | jq -r '.status'
if [[ $(
    echo $SELF | jq 'select(.status != "Offline")'
) ]]; then
    exit
fi

echo 'Stopping Constellation'
systemctl stop constellation.service

INSTALLED_VERSION=$(java -jar ./cl-node.jar --version | grep "constellation" | awk '{print $NF}')
LATEST_VERSION=$(curl -sf $LB:9000/metrics | jq -r '.metrics.version')
if [[ -z $LATEST_VERSION ]]; then echo 'Could not get latest version'; exit 1; fi
echo "Installed: "$INSTALLED_VERSION
echo "Latest: "$LATEST_VERSION

if [[ $LATEST_VERSION != $INSTALLED_VERSION ]]; then
    echo 'Fetching '$LATEST_VERSION
    rm cl-node.jar whitelisting
    CONSTELLATION_BASEURL=https://github.com/Constellation-Labs/constellation/releases/download/v$LATEST_VERSION
    aria2c --console-log-level=warn -x4 -s4 $CONSTELLATION_BASEURL/cl-node.jar || (echo "Failed to fetch node program" && exit 1)
    # Mainnet
    wget $CONSTELLATION_BASEURL/whitelisting || (echo "Failed to fetch whitelisting" && exit 1)
    # Testnet
    # wget https://marcinwadon.keybase.pub/whitelisting || (echo "Failed to fetch whitelisting" && exit 1)
    chown $MY_USER: cl-node.jar whitelisting
fi

echo 'Restarting Constellation'
rm -r tmp/
systemctl restart constellation.service

echo 'Waiting for node to start'
while true; do curl -sf localhost:9002/metrics > /dev/null && break; sleep 5; done
echo 'Attempting to join'
JOIN_IP=$(curl -sf $LB:9000/cluster/info | jq -r '.[] | select(.status=="Ready") | .ip.host' | sort -R | head -n1)
curl -X POST http://localhost:9002/join -H "Content-type: application/json" -d "{ \"host\": \"$JOIN_IP\", \"port\": 9001 }"

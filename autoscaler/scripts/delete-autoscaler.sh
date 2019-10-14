#!/bin/bash
set -e

iptables -I INPUT -p tcp --dport 8443 -j ACCEPT && iptables -I OUTPUT -p tcp --dport 8443 -j ACCEPT
iptables -t nat -I OUTPUT -p tcp -d 192.168.50.6 --dport 8443 -j DNAT --to-destination ${BOSH_TARGET}:8443

echo "$BOSH_CA" > "./bosh_ca"
bosh -e $BOSH_TARGET --ca-cert ./bosh_ca alias-env vbox 
export BOSH_CLIENT=${BOSH_USERNAME}
export BOSH_CLIENT_SECRET=${BOSH_PASSWORD}
bosh -n -e $BOSH_TARGET delete-deployment -d app-autoscaler --force




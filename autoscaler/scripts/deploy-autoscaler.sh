#!/bin/bash
set -x
set -e

echo "$BOSH_CA" > "./bosh_ca"
bosh -e $BOSH_TARGET_HOST:$BOSH_TARGET_PORT --ca-cert ./bosh_ca alias-env vbox 
export BOSH_CLIENT=$BOSH_USERNAME 
export BOSH_CLIENT_SECRET=$BOSH_PASSWORD

cd app-autoscaler-release
# ./scripts/update
# sed -i -e 's/vm_type: default/vm_type: minimal/g' ./templates/app-autoscaler-deployment.yml

cat >as_operation.yml <<-EOF
---
- type: replace
  path: /instance_groups/name=apiserver/jobs/name=apiserver/properties/cf/api?
  value: http://api.((system_domain)):((cf_router_port))
- type: replace
  path: /instance_groups/name=metricscollector/jobs/name=metricscollector/properties/cf/api?
  value: http://api.((system_domain)):((cf_router_port))

EOF
bosh create-release --force
bosh -n -e vbox upload-release --rebase

bosh -e vbox -d app-autoscaler \
     deploy -n templates/app-autoscaler-deployment.yml \
     -o as_operation.yml \
     --vars-store=bosh-lite/deployments/vars/autoscaler-deployment-vars.yml \
     -v system_domain=$CF_DOMAIN \
     -v cf_router_port=$CF_ROUTER_PORT \
     -v cf_admin_password=$CF_ADMIN_PASSWORD \
     -v cf_admin_client_secret=$CF_ADMIN_CLIENT_SECRET \
     -v skip_ssl_validation=true 
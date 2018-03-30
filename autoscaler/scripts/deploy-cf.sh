#!/bin/bash
set -x
set -e

echo "$BOSH_CA" > "./bosh_ca"
bosh -e $BOSH_TARGET_HOST:$BOSH_TARGET_PORT --ca-cert ./bosh_ca alias-env vbox 
export BOSH_CLIENT=$BOSH_USERNAME 
export BOSH_CLIENT_SECRET=$BOSH_PASSWORD
bosh -n -e vbox delete-deployment -d cf
cd cf-deployment

cat >cf_operation.yml <<-EOF
---
- type: replace
  path: /instance_groups/name=uaa/jobs/name=uaa/properties/login/protocol?
  value: http

- type: replace
  path: /instance_groups/name=uaa/jobs/name=uaa/properties/uaa/url
  value: http://uaa.((system_domain))

- type: replace
  path: /instance_groups/name=uaa/jobs/name=uaa/properties/uaa/clients/ssh-proxy/redirect-uri
  value: "http://uaa.((system_domain))/login"

- type: replace
  path: /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/uaa/url
  value: http://uaa.((system_domain))

- type: replace
  path: /instance_groups/name=router/jobs/name=gorouter/properties/router/enable_ssl
  value: false

- type: replace
  path: /instance_groups/name=router/jobs/name=gorouter/properties/router/port?
  value: ((cf_router_port))

EOF


# sed -i "s/enable_ssl: true/enable_ssl: false\n        port: ${CF_ROUTER_PORT}/g" cf-deployment.yml
# sed -i "s#url: https://uaa#url: http://uaa#" cf-deployment.yml
sed -i "s/10.244/${CF_NETWORK_PREFIX}/g" iaas-support/bosh-lite/cloud-config.yml
sed -i "s/10.244/${CF_NETWORK_PREFIX}/g" operations/bosh-lite.yml
bosh -n -e vbox upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
bosh -n -e vbox update-cloud-config iaas-support/bosh-lite/cloud-config.yml
bosh -e vbox -d cf deploy -n cf-deployment.yml \
  -o cf_operation.yml \
  -o operations/bosh-lite.yml \
  -o operations/use-compiled-releases.yml \
  --vars-store ../app-autoscaler-ci/autoscaler/deployment-vars.yml \
  -v system_domain=$CF_DOMAIN \
  -v cf_router_port=$CF_ROUTER_PORT \
  -v cf_admin_password=$CF_ADMIN_PASSWORD \
  -v uaa_admin_client_secret=$CF_ADMIN_CLIENT_SECRET
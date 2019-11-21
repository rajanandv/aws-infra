#!/bin/bash

mkdir -p ${currunt_path}/functions/build
mkdir -p ${currunt_path}/functions/output

rm -rf ${currunt_path}/functions/build/urlfinder
rm -f ${currunt_path}/functions/output/djcmpnp_urlfinder_function.zip
sleep 2

cp -r ${currunt_path}/functions/src/urlfinder ${currunt_path}/functions/build/
sleep 2

sed -i '' "s/##ENVIRONMENT_NAME_VAL##/${environment_name}/g; s/##DOMAIN_WSJ_VAL##/${domain_wsj}/g; s/##DOMAIN_BAR_VAL##/${domain_bar}/g; s/##CF_AWS_ACCOUNT_NUMBER##/${ddb_aws_accnumber}/g" ${currunt_path}/functions/build/urlfinder/env_info.js
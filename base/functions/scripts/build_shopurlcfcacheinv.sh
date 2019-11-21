#!/bin/bash

mkdir -p ${currunt_path}/functions/build
mkdir -p ${currunt_path}/functions/output

rm -rf ${currunt_path}/functions/build/cfcacheinv
rm -f ${currunt_path}/functions/output/djcmpnp_shopurlcfcacheinv_function.zip
sleep 2

cp -r ${currunt_path}/functions/src/cfcacheinv ${currunt_path}/functions/build/
sleep 2
echo "Env Info file : ${currunt_path}/functions/build/cfcacheinv/env_info.js"

chmod 775 ${currunt_path}/functions/build/cfcacheinv/*.js
cd ${currunt_path}/functions/build/cfcacheinv/
ls -lrt 

sed "s/##ENVIRONMENT_NAME_VAL##/${environment_name}/g; s/##SHOP_CFDISTRIB_WSJ_VAL##/${cfdistrib_wsj}/g; s/##SHOP_CFDISTRIB_BAR_VAL##/${cfdistrib_bar}/g; s/##VANITY_CFDISTRIB_WSJ_VAL##/${cfdistrib_vanity_wsj}/g; s/##CF_AWS_ACCTNUMBER_VAL##/${cf_account_number}/g" env_info.js > env_info.js_new
mv env_info.js_new env_info.js

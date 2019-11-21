#!/usr/bin/env bash

#--------------------------------------------------------------------------------
#
# Identifying the subnet id
#
#--------------------------------------------------------------------------------

echo "Hello user data"

# echo "app_launching_type is : ${app_launching_type}" >> /home/ec2-user/terraform_launch.log

# if [ "${app_launching_type}" = "auto" ]; then
# 	export SUBNET_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/subnet-id)

# 	echo "Subnet Id : $SUBNET_ID" >> /home/ec2-user/terraform_launch.log

# 	export EC2_INDEX_ID=$(curl --silent http://169.254.169.254/latest/meta-data/ami-launch-index)
# 	export EC2_INDEX_ID=$((EC2_INDEX_ID+1))

# 	echo "Launch index id : $EC2_INDEX_ID" >> /home/ec2-user/terraform_launch.log
# 	echo "Subnet zone input : ${subnet_zone1}" >> /home/ec2-user/terraform_launch.log

# 	if [ "${subnet_zone1}" = "$SUBNET_ID" ]; then
# 		export APP_INSTANCE_ID="${app_instance_name}$EC2_INDEX_ID""a"
# 	else
# 		export APP_INSTANCE_ID="${app_instance_name}$EC2_INDEX_ID""b"
# 	fi

# else
# 	export APP_INSTANCE_ID="${app_instance_name}"
# 	export EC2_INDEX_ID=1
# fi

# echo "APP_INSTANCE_ID is : $APP_INSTANCE_ID" >> /home/ec2-user/terraform_launch.log

# # ------------------------------------------------------------------------------
# #
# #   Update the hostname
# #
# # ------------------------------------------------------------------------------

# #useradd -d /home/appuser -m -s /bin/bash "appuser"
# #usermod -aG users appuser

# echo "Updating the host name with ip address"
# export MY_EC2_IP=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')

# sed -i "s/127.0.0.1 */127.0.0.1 $MY_EC2_IP /" /etc/hosts
# sed -i "s/::1 */::1  $MY_EC2_IP /" /etc/hosts
# echo 'HOSTNAME=$MY_EC2_IP' >> /etc/sysconfig/network

# echo 'preserve_hostname: true' >> /etc/cloud/cloud.cfg
# echo '$MY_EC2_IP'
# hostnamectl set-hostname --static $MY_EC2_IP

# #--------------------------------------------------------------------------------
# #
# # Setting the environment variables
# #
# #--------------------------------------------------------------------------------

# echo "export ENVIRONMENT_NAME=${env}" >> /home/ec2-user/.bash_profile
# echo "export APP_INSTANCE_NAME=$APP_INSTANCE_ID" >> /home/ec2-user/.bash_profile
# echo "export APP_LAUNCH_INDEX_ID=$EC2_INDEX_ID" >> /home/ec2-user/.bash_profile
# echo "export APP_CLUSTER_TYPE=${app_cluster_type}" >> /home/ec2-user/.bash_profile
# source /home/ec2-user/.bash_profile




# #--------------------------------------------------------------------------------
# #
# # Download Chef executables
# #
# #--------------------------------------------------------------------------------

# cd /home/ec2-user/

# curl -s -u ${jfrog_user_name}:${jfrog_password} -O ${jfrog_art_base_url}${secrets_tar_file_uri}

# curl -s -u ${jfrog_user_name}:${jfrog_password} -O ${jfrog_art_base_url}${chef_tar_file_uri}
# tar xf ${chef_tar_file_uri}
# rm /home/ec2-user/${chef_tar_file_uri}


# chmod +x /home/ec2-user/pnpapp/*.sh

# mv /home/ec2-user/pnpapp /var/chef-solo

# cd /var/chef-solo/
# nohup /var/chef-solo/spinup_pnpapp.sh  >> /var/log/pnp-chef.log 2>&1 &


!/usr/bin/env bash

echo "User data bootstraping is started"

sudo yum -y install nfs-utils
sudo mkdir -p /efs-share
## TODO:: User group and user need setup need to be revisited
sudo chown ec2-user:ec2-user /efs-share
#-----Resolving EFS using DNS ------------
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efs_file_sytem_dns_name}:/ /efs-share
sudo echo "${efs_file_sytem_dns_name}:/ /efs-share nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab




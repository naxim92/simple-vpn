#!/bin/sh

#TODO
# use alpine image
# https://devcoops.com/install-terraform-on-alpine-linux/
# https://collabnix.com/how-to-install-the-latest-version-of-docker-compose-on-alpine-linuxin-2022/

apt update
apt install -y iputils-ping gpg curl wget unzip bash make
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

OS_VERSION=`grep VERSION_CODENAME /etc/os-release | awk -F'VERSION_CODENAME=' '{ print $2;}'`

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $OS_VERSION stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker docker.io docker-compose-plugin 

wget -q https://releases.hashicorp.com/terraform/1.3.9/terraform_1.3.9_linux_$(
dpkg --print-architecture).zip -O /tmp/terraform.zip && unzip /tmp/terraform.zip -d /bin && rm -f /tmp/terraform.zip

apt clean

cd /simple-vpn
/bin/bash
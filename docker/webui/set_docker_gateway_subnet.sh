#!/bin/bash

GATEWAY_SUBNET=`docker network inspect wireguard_default -f '{{(index .IPAM.Config 0).Subnet}}'`

sudo sed -i "s/NGINX_DOCKER_HOST_SUBNET='.*$/NGINX_DOCKER_HOST_SUBNET='$GATEWAY_SUBNET'/" `dirname $0`/.env

echo $GATEWAY_SUBNET
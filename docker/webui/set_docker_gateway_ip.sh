#!/bin/bash

GATEWAY_IP=`docker network inspect wireguard_default -f '{{(index .IPAM.Config 0).Gateway}}'`

sudo sed -i "s/NGINX_DOCKER_HOST_IP='.*$/NGINX_DOCKER_HOST_IP='$GATEWAY_IP'/" `dirname $0`/.env

echo $GATEWAY_IP
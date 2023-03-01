#! /bin/bash

sudo mkdir -p /srv/wireguard/docker/wireguard

# Install wireguard service
sudo mv ~/wireguard/docker/wireguard/ /srv/wireguard/docker
sudo mv ~/wireguard/wireguard_configs /srv/wireguard/wireguard_configs

cd /srv/wireguard/docker/wireguard
docker compose -p wireguard up -d wireguard

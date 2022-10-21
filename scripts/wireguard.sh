#! /bin/bash

sudo mv wireguard /srv/wireguard
cd /srv/wireguard
mkdir /srv/wireguard/config
docker compose up -d wireguard
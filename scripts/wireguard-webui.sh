#! /bin/bash

# Copy files to dpecific folder /srv/wireguard-webui/
# TODO
# cd /srv/wireguard-webui/

# Make .env files from templates 
# TODO

# Install wireguard simple webui
docker compose -p wireguard run --rm webuiapp pip install -r requirements.txt
docker compose -p wireguard up -d --force-recreate webuiapp
#! /bin/bash

sudo mkdir -p /srv/wireguard/docker/webui
sudo mkdir -p /srv/wireguard/logs

# Copy files to specific folder /srv/wireguard/
sudo mv ~/wireguard/docker/webui /srv/wireguard/docker
sudo mv ~/wireguard/webui /srv/wireguard/
sudo mv ~/wireguard/nginx /srv/wireguard/
cd /srv/wireguard/docker/webui

# Correct gateway address in .env file
sudo chmod +x set_docker_gateway_ip.sh
GATEWAY_IP=`./set_docker_gateway_ip.sh`

# Get SSL certificates from Let's Encrypt by certbot
docker compose run -p 80:80 --rm -v wireguard_certbot:/etc/letsencrypt --entrypoint certbot certbot certonly --standalone -d ${nginx_host} -m "${email}" --agree-tos --no-eff-email

# Install wireguard simple webui
docker compose -p wireguard run --rm webuiapp pip install -r requirements.txt

# Clear WebUI database (clear setup)
sudo rm -f /srv/wireguard/webui/data/webui.db

# Run wireguard
docker compose -p wireguard up -d --force-recreate
sleep 5

# Install default params for Wireguard WebUI
curl -k https://$GATEWAY_IP/install --header "Host: ${nginx_host}"

# Cleanup
rm -rf ~/wireguard

# TODO Удалить, когда поправлю баг с пятисотыми после инсталла
sleep 5
docker stop wireguard_webuiapp && docker start wireguard_webuiapp
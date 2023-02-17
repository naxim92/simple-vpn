Windows Docker Engine:
"buildkit": false

Gloud service-account's permissions:
    Compute Admin
    Compute Engine Service Agent
    Compute Network Admin
    Compute OS Admin Login
    Compute Public IP Admin

sudo docker-compose run --rm -p 80:80 -p 443:443 certbot
sudo docker-compose run --rm webuiapp pip install -r requirements.txt

sudo docker-compose run --rm certbot certonly --standalone -d ${NGINX_HOST:-wireguard.local} -m "${EMAIL} --agree-tos --no-eff-email --dry-run

import socket
import os

socket_path = '/var/run/docker.sock'

if not os.path.exists(socket_path):
    raise ValueError('No docker.sock on machine (is a Docker server installed?)')
client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
client.connect(socket_path)
client.send(b'POST /containers/wireguard_balancer/kill?signal=HUP HTTP/1.1\n')
client.send(b'Host: docker\n')
client.send(b'\n')
dataFromServer = client.recv(1024)
print(dataFromServer.decode().split('\r\n'))


client.send(b'GET /version HTTP/1.1\n')
client.send(b'Host: docker\n')

/usr/local/bin/certbot renew --deploy-hook "/opt/certbot/ wireguard_balancer_reload.py -o /var/log/letsencrypt/balancer_reloader.log" --dry-run

docker network inspect wireguard_default -f '{{(index .IPAM.Config 0).Gateway}}'



terraform apply -auto-approve -target google_compute_address.static
terraform apply -auto-approve

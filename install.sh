#!/bin/bash

sudo docker compose -p wireguard -f .\docker\docker-compose.yml run --rm -ti simple_vpn_builder
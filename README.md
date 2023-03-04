# This is a small simple implementaion of service which helps you to deploy and manage Wireguard VPN

## Prerequisites

### Software

You need to have only docker with docker-compose plugin on your machine.

### Miscellaneous

- Windows Docker Engine configuration:
    "buildkit": false
    set COMPOSE_DOCKER_CLI_BUILD=0

You need to have gcloud account, service-account there and credentials json file, DNS record (will be linked to VPN ip-address during deploy) and generated pair of keys to manage the VPS server.

- Gloud service-account's permissions:
    - Compute Admin
    - Compute Engine Service Agent
    - Compute Network Admin
    - Compute OS Admin Login
    - Compute Public IP Admin

## Installation

Just start install script in root directory and try it!

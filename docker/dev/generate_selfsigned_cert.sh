#!/bin/sh

cd /data/private/ssl
mkdir -p live/${nginx_host}
cd live/${nginx_host}
openssl req -days 365 -nodes -new -x509 \
-subj '/C=US/L=City/O=Test/CN='${nginx_host} \
-keyout privkey.pem -out fullchain.pem
#!/bin/bash

docker run -it --rm \
-v "$(pwd)/docker_volumes/etc/letsencrypt:/etc/letsencrypt" \
-v "$(pwd)/docker_volumes/var/lib/letsencrypt:/var/lib/letsencrypt" \
-v "$(pwd)/letsencrypt-site:/data/letsencrypt" \
-v "$(pwd)/docker_volumes/var/log/letsencrypt:/var/log/letsencrypt" \
certbot/certbot \
certonly --webroot \
--register-unsafely-without-email --agree-tos \
--webroot-path=/data/letsencrypt \
--staging \
-d test.intelliris.net

exit 0

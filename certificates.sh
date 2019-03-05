#!/bin/bash

docker run -it --rm \
-v "$(pwd)/docker_volumes/etc/letsencrypt:/etc/letsencrypt" \
-v "$(pwd)/docker_volumes/var/lib/letsencrypt:/var/lib/letsencrypt" \
-v "$(pwd)/docker_volumes/var/log/letsencrypt:/var/log/letsencrypt" \
certbot/certbot \
--staging \
certificates

exit 0

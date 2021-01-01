#!/usr/bin/env bash

if [ -n "$CERTS" ]; then
    certbot certonly --no-self-upgrade -n --text --standalone \
        --preferred-challenges http-01 \
        -d "$CERTS" --keep --expand --agree-tos --email "$EMAIL" \
		--server "$URL" \
        || exit 1
	
	if [ -f "/etc/letsencrypt/live/README" ]; then
		rm -f /etc/letsencrypt/live/README
	fi
    mkdir -p /usr/local/etc/haproxy/certs
    for site in `ls -1 /etc/letsencrypt/live`; do
        cat /etc/letsencrypt/live/$site/fullchain.pem \
		/etc/letsencrypt/live/$site/privkey.pem \
          | tee /usr/local/etc/haproxy/certs/haproxy-"$site".pem >/dev/null
    done
fi

exit 0

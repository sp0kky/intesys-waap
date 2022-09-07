#!/bin/bash -e

export DNS_SERVER=${DNS_SERVER:-$(cat /etc/resolv.conf |grep -i '^nameserver'|head -n1|cut -d ' ' -f2)}

ENV_VARIABLES=$(awk 'BEGIN{for(v in ENVIRON) print "$"v}')

FILES=(
    /usr/local/openresty/nginx/conf/nginx.conf
    /usr/local/openresty/nginx/conf/sites-enabled/default.conf
    /usr/local/openresty/nginx/conf/logging.conf
    /usr/local/openresty/nginx/conf/modsecurity.conf
)

for FILE in ${FILES[*]}; do
    if [ -f $FILE ]; then
        envsubst "$ENV_VARIABLES" <$FILE | sponge $FILE
    fi
done

exec "$@"

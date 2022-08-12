FROM nginx:stable-alpine

ENV LE_WORKING_DIR=/opt/acme.sh

COPY docker-entrypoint-acme.sh /

RUN set -ex && \
    apk add --no-cache ca-certificates curl openssl && \
    curl -sSL https://get.acme.sh | sh -s mark.raming@eraze.com && \
    mkdir -p /opt/acme.sh/ca/acme-v01.api.letsencrypt.org && \
    crontab -l | sed "s|acme.sh --cron|acme.sh --cron --renew-hook \"nginx -s reload\"|g" | crontab - && \
    ln -s /opt/acme.sh/acme.sh /usr/bin/acme.sh && \
    chmod +x /docker-entrypoint-acme.sh

ENTRYPOINT ["/docker-entrypoint-acme.sh"]

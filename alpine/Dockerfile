FROM nginx:stable-alpine

ENV LE_WORKING_DIR=/opt/acme.sh

RUN set -ex && \
    apk add --no-cache ca-certificates curl openssl && \
    curl -sSL https://get.acme.sh | sh && \
    mkdir -p /opt/acme.sh/ca/acme-v01.api.letsencrypt.org && \
    mkdir -p /etc/nginx/ssl && \
    crontab -l | sed "s|acme.sh --cron|acme.sh --cron --renew-hook \"nginx -s reload\"|g" | crontab - && \
    ln -s /opt/acme.sh/acme.sh /usr/bin/acme.sh && \
    # A bit simplistic but it works: Inject an additional command to get crontab working into the docker-entrypoint.sh script
    # which already exists from our base image.
    sed -i '5i crond -b -L /var/log/crond.log' /docker-entrypoint.sh

COPY /ssl/* /etc/nginx/ssl


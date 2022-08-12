#!/bin/sh

set -e

crond -b -L /var/log/crond.log

# Now simply call the original docker-entrypoint script that comes with the official NGINX container we derive from
source docker-entrypoint.sh

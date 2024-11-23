#!/bin/sh
caddy storage import -c /etc/caddy/Caddyfile -i /etc/caddy/Caddystore
exec caddy run --watch --config /etc/caddy/Caddyfile --adapter caddyfile

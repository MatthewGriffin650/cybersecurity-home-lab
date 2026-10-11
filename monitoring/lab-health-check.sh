#!/bin/bash

services=("nginx" "postgresql@18-main" "bind9")

echo "=== Lab Service Health Check ==="
echo

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "$service: Active"
    else
        echo "$service: Inactive"
    fi
done

echo
echo "=== Listening Ports ==="
ss -tulpn | grep -E ':22|:53|:80|:5432'

echo
echo "=== Disk Usage ==="
df -h / | tail -n 1

echo
echo "=== Recent Service Errors ==="

for service in "${services[@]}"; do
    errors=$(journalctl -u "$service" -p err --since "1 hour ago" --no-pager 2>/dev/null)

    if [ -z "$errors" ] || [ "$errors" = "-- No entries --" ]; then
        echo "$service: No recent errors"
    else
        echo
        echo "$service: Recent errors found"
        echo "$errors"
    fi
done

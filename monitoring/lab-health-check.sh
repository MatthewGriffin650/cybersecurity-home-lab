#!/bin/bash

services=("ssh" "nginx" "postgresql@18-main" "named")
ports=(22 53 80 5432)
lab_ip="192.168.240.132"
status=0

echo "=== Lab Service Health Check ==="
echo

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "$service: Active"
    else
        echo "$service: Inactive"
        status=1
    fi
done

echo
echo "=== Listening Ports ==="
listeners=$(ss -tuln | awk '{print $5}')

for port in "${ports[@]}"; do
    if echo "$listeners" | grep -Eq ":${port}$"; then
        echo "Port $port: Listening"
    else
        echo "Port $port: NOT listening"
        status=1
    fi
done

if echo "$listeners" | grep -q "^${lab_ip}:5432$"; then
    echo "PostgreSQL: Listening on lab address ($lab_ip)"
else
    echo "PostgreSQL: NOT listening on lab address ($lab_ip)"
    status=1
fi

echo
echo "=== Disk Usage ==="
df -h / | tail -n 1

echo
echo "=== Recent Service Errors ==="

for service in "${services[@]}"; do
    errors=$(journalctl -u "$service" -p err --since "1 hour ago" --no-pager -q 2>/dev/null)

    if [ -z "$errors" ]; then
        echo "$service: No recent errors"
    else
        echo
        echo "$service: Recent errors found"
        echo "$errors"
        status=1
    fi
done

exit $status

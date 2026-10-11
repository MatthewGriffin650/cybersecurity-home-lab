# Nginx Configuration and Hardening

Nginx is used as the web server for the internal `intranet.lab` site in my home lab.

This directory contains the security-related Nginx configuration I used and the commands I used to modify, validate, restart, and troubleshoot the service.

## Configuration

The hardening configuration is in:

    nginx-hardening.conf

The complete `intranet.lab` server block was configured with:

    sudo nano /etc/nginx/sites-available/intranet.lab

The resulting configuration is:

    server {
        listen 80;
        listen [::]:80;

        server_name intranet.lab;

        server_tokens off;

        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        root /var/www/intranet.lab;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }
    }

The settings used are:

### Hide Nginx Version Information

    server_tokens off;

Prevents Nginx from displaying its version number in generated error pages and certain response headers.

This reduces unnecessary information exposed by the web server.

### X-Content-Type-Options

    add_header X-Content-Type-Options "nosniff" always;

Tells browsers not to guess the content type of a response when a declared content type is provided.

This helps prevent certain types of MIME-type confusion.

### X-Frame-Options

    add_header X-Frame-Options "SAMEORIGIN" always;

Allows the site to be displayed in a frame only when the framing page comes from the same origin.

This provides protection against certain clickjacking scenarios.

### Referrer-Policy

    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

Controls how much referrer information is sent when navigating between pages.

For cross-origin requests, only the origin is sent rather than the complete URL.

### try_files

    try_files $uri $uri/ =404;

Checks whether the requested file or directory exists.

If it does not exist, Nginx returns a 404 response instead of attempting to handle the request another way.

## Commands

### Check Nginx Status

    sudo systemctl status nginx

A shorter status check:

    systemctl is-active nginx

Expected result when the service is running:

    active

### Start Nginx

    sudo systemctl start nginx

### Stop Nginx

    sudo systemctl stop nginx

### Restart Nginx

    sudo systemctl restart nginx

### Reload Nginx

    sudo systemctl reload nginx

A reload applies configuration changes without completely stopping the service.

### Enable Nginx at Boot

    sudo systemctl enable nginx

### Disable Nginx at Boot

    sudo systemctl disable nginx

## Configuration Validation

Before restarting or reloading Nginx after changing its configuration, check the configuration syntax:

    sudo nginx -t

A successful check should report:

    syntax is ok
    test is successful

Only restart or reload Nginx after the configuration passes this test.

## Checking the Site

From the Ubuntu Server:

    curl http://intranet.lab

From the Kali VM:

    curl http://intranet.lab

The response should contain the content of the internal web page.

## Checking HTTP Headers

To view the response headers:

    curl -I http://intranet.lab

This can be used to verify that the configured security headers are being returned.

Look for:

    X-Content-Type-Options: nosniff
    X-Frame-Options: SAMEORIGIN
    Referrer-Policy: strict-origin-when-cross-origin

## Finding the Nginx Configuration

List the available Nginx configuration:

    ls /etc/nginx/

View the main configuration:

    sudo nano /etc/nginx/nginx.conf

View enabled sites:

    ls -l /etc/nginx/sites-enabled/

View available sites:

    ls -l /etc/nginx/sites-available/

The `intranet.lab` server block is stored in the Nginx site configuration.

## Editing the Configuration

To edit the main Nginx configuration:

    sudo nano /etc/nginx/nginx.conf

To edit the `intranet.lab` site configuration:

    sudo nano /etc/nginx/sites-available/intranet.lab

After making changes:

    sudo nginx -t

If the configuration test succeeds:

    sudo systemctl reload nginx

## Checking Nginx Logs

View recent Nginx errors:

    sudo journalctl -u nginx -p err --since "1 hour ago" --no-pager

View the Nginx access log:

    sudo tail -f /var/log/nginx/access.log

View the Nginx error log:

    sudo tail -f /var/log/nginx/error.log

## Troubleshooting

If Nginx will not start or reload, first check the configuration:

    sudo nginx -t

Then check the service status:

    sudo systemctl status nginx

Check recent service errors:

    sudo journalctl -u nginx -p err --since "1 hour ago" --no-pager

If the service is running but the website cannot be reached, verify that Nginx is listening on port 80:

    sudo ss -tulpn | grep ':80'

Then test the site:

    curl http://intranet.lab

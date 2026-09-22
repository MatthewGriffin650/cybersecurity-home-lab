# Home Lab Backups

## Overview

I created local backups of important home lab configuration and database data so the environment could be restored if a configuration change caused a problem.

The backups were stored on the Ubuntu Server in:

    /var/backup/home-lab

The backup directory was restricted so that only authorized users could access the files.

---

## Backup Directory

The backup directory was created with:

    sudo mkdir -p /var/backup/home-lab

Permissions were restricted with:

    sudo chmod 700 /var/backup/home-lab

Check the directory:

    sudo ls -ld /var/backup/home-lab

---

## Nginx Backup

The Nginx configuration and web content were backed up into a compressed archive.

The backup was created with:

    sudo tar -czf /var/backup/home-lab/nginx-backup-$(date +%Y-%m-%d).tar.gz /etc/nginx /var/www/intranet.lab

List the backup:

    sudo ls -lh /var/backup/home-lab/

The archive contains the Nginx configuration and the files used by the internal website.

---

## PostgreSQL Backup

The `labdb` PostgreSQL database was backed up using `pg_dump`.

A custom-format dump was created with:

    sudo -u postgres pg_dump -Fc labdb | sudo tee /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump > /dev/null

The `-Fc` option creates a PostgreSQL custom-format dump.

The resulting file can be inspected without restoring the database:

    sudo pg_restore -l /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump

This was used to verify that the backup contained PostgreSQL database objects.

---

## BIND9 and Monitoring Backup

The BIND9 configuration and monitoring files were also backed up.

The backup was created with:

    sudo tar -czf /var/backup/home-lab/bind-monitoring-backup-$(date +%Y-%m-%d).tar.gz /etc/bind /usr/local/bin/lab-health-check.sh

List the backup files:

    sudo ls -lh /var/backup/home-lab/

---

## Verify Backup Files

List all backups:

    sudo ls -lh /var/backup/home-lab/

Check the contents of a compressed archive:

    sudo tar -tzf /var/backup/home-lab/nginx-backup-$(date +%Y-%m-%d).tar.gz

Check the PostgreSQL dump:

    sudo pg_restore -l /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump

These checks verify that the backup files exist and can be read.

---

## Backup Contents

| Backup | Contents |
|---|---|
| Nginx backup | Nginx configuration and website files |
| PostgreSQL dump | `labdb` database |
| BIND9/monitoring backup | BIND9 configuration and health-check script |

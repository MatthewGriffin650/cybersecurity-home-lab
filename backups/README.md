# Home Lab Backups

## Overview

I created local backups of important home lab configuration and database data so the environment could be restored if a configuration change caused a problem. The backups are stored on the same VM they protect. They guard against bad configuration changes and accidental data loss, but not against losing the VM itself.

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

This lists the dump's table of contents. It shows what the dump contains but does not prove it can be restored, which is why the restore test below was also done.

---

## PostgreSQL Roles Backup

`pg_dump` does not include database roles, so roles are backed up separately:

    sudo -u postgres pg_dumpall --globals-only | sudo tee /var/backup/home-lab/globals-$(date +%Y-%m-%d).sql > /dev/null
    sudo chmod 600 /var/backup/home-lab/globals-$(date +%Y-%m-%d).sql

This file contains password hashes, so it is restricted to root and is never committed to GitHub.

---

## Restore Test

To verify the dump can be restored, it was loaded into a scratch database and compared to the original. `labdb` contains a small sample table, `backup_test`, so the test covers real data, ownership, and a sequence.

    sudo -u postgres createdb labdb_restore_test
    sudo cat /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump | sudo -u postgres pg_restore -d labdb_restore_test
    sudo -u postgres psql -d labdb_restore_test -c '\dt'
    sudo -u postgres psql -d labdb_restore_test -c 'SELECT * FROM backup_test;'
    sudo -u postgres dropdb labdb_restore_test

The restored database contained `backup_test`, owned by `labuser`, with both rows. The dump is piped through `sudo cat` because the `postgres` user cannot read the root-only backup directory.

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
| PostgreSQL roles | Database roles and password hashes (`globals-*.sql`) |
| BIND9/monitoring backup | BIND9 configuration and health-check script |

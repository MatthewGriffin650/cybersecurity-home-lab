# Troubleshooting Log

Problems I hit while building the Splunk portion of the lab and how I diagnosed them.

## 1. Splunk package install killed the VM (out of memory)

**Symptom:** `sudo dpkg -i splunk-*.deb` printed `Killed`, the SSH session dropped, and the VM console filled with kernel messages (`rcu_preempt kthread starved`, `task blocked`). SSH stopped responding.

**Diagnosis:** After resetting the VM, `dpkg -l splunk` showed the package half-configured (`iF`). The previous boot's kernel log confirmed it:

    sudo journalctl -k -b -1 | grep -i -E "out of memory|killed process"

The kernel had run out of memory and killed nearly every process, including `sshd`. The OOM was triggered by `find`, likely running from the package's post-install script, and process IDs in the log were above 30,000 only minutes after boot, which suggests a burst of spawned processes. I did not prove the exact cause inside the script.

**Fix:** Increased the VM's memory from 8 GB to 16 GB, removed the broken package (`dpkg --purge --force-remove-reinstreq splunk`), and installed from the `.tgz` archive instead, which skips the package scripts. Splunk then started cleanly.

## 2. Port scan alert did not fire

**Symptom:** A full `nmap -p 1-1000` scan did not trigger the alert, which required 15 or more distinct blocked ports.

**Diagnosis:** A search of the raw data showed only 11 distinct ports, because UFW rate-limits logging of blocked packets.

**Fix:** Tuned the threshold to 8 based on observed data. See `detections.md`.

## 3. Dashboard panel dropped PostgreSQL rejections

**Symptom:** The PostgreSQL panel showed bad-password failures but never the `pg_hba.conf` rejections.

**Diagnosis:** The search grouped by a `user` field that is only extracted for password failures. Splunk's `stats` drops rows where a grouping field is empty.

**Fix:** Extracted the username from both message formats, merged them with `coalesce`, and grouped on the merged field.

## Lessons

- Check the previous boot's logs after a crash (`journalctl -b -1`).
- Have a fallback install method when a package install fails.
- Tune detection thresholds against real data instead of guessing.
- Check that each dashboard panel shows every event type you expect, not just the ones that happened to work first.

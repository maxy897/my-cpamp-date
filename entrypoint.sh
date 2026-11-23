#!/bin/bash
set -e

mkdir -p /data

export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY

echo "==> [maint] restoring usage.sqlite from R2..."
litestream restore -if-replica-exists -config /etc/litestream.yml /data/usage.sqlite
ls -la /data/usage.sqlite

echo "==> [maint] running cleanup-derived (same-version binary)..."
cpa-manager-plus cleanup-derived --db-path /data/usage.sqlite

echo "==> [maint] replicating cleaned db back to R2..."
timeout 600 litestream replicate -config /etc/litestream.yml -exec "sleep 180" || true

echo "==> [maint] generations now in R2:"
litestream generations -config /etc/litestream.yml /data/usage.sqlite || true

echo "==> [maint] DONE. Idling so the service does not restart-loop; delete this service now."
sleep 1800

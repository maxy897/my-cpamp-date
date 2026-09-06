#!/bin/bash
set -e

mkdir -p /data

export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY

# 1. 如果 R2 上有之前的数据库，自动还原
echo "==> 正在检查并恢复 SQLite 数据库..."
litestream restore -if-replica-exists -config /etc/litestream.yml /data/usage.sqlite

# 2. 如果 R2 上有 data.key，自动还原
echo "==> 正在检查并恢复 data.key..."
aws --endpoint-url=$R2_ENDPOINT s3 cp s3://cpamp-data/data.key /data/data.key || true

# 3. 后台定时（每 3 分钟）把 data.key 同步回 R2
(while true; do
   sleep 180
   if [ -f /data/data.key ]; then
     aws --endpoint-url=$R2_ENDPOINT s3 cp /data/data.key s3://cpamp-data/data.key >/dev/null 2>&1 || true
   fi
done) &

# 4. 使用 Litestream 启动 CPA-Manager-Plus，实现实时无感增量同步
echo "==> 启动 CPA-Manager-Plus 服务..."
exec litestream replicate -config /etc/litestream.yml -exec "/app/cpa-manager-plus"

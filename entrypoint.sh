#!/bin/bash
set -e

mkdir -p /data

export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY

# 1. 启动时尝试从 Cloudflare R2 还原数据库
echo "==> 正在检查并从 R2 还原 SQLite 数据库..."
litestream restore -if-replica-exists -config /etc/litestream.yml /data/usage.sqlite || true

# 2. 启动时尝试从 Cloudflare R2 还原 data.key（第一次不存在是正常的，隐藏 404 提示）
echo "==> 正在检查并从 R2 还原 data.key..."
aws --endpoint-url=$R2_ENDPOINT s3 cp s3://cpamp-data/data.key /data/data.key >/dev/null 2>&1 || true

# 3. 后台定时（每 3 分钟）自动把 data.key 备份到 R2
(while true; do
   sleep 180
   if [ -f /data/data.key ]; then
     aws --endpoint-url=$R2_ENDPOINT s3 cp /data/data.key s3://cpamp-data/data.key >/dev/null 2>&1 || true
   fi
done) &

# 4. 使用 Litestream 启动后台主程序（纠正为正确的可执行路径）
echo "==> 启动 CPA-Manager-Plus 服务..."
exec litestream replicate -config /etc/litestream.yml -exec "/usr/local/bin/cpa-manager-plus"

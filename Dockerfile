FROM litestream/litestream:0.3.13 AS litestream

FROM seakee/cpa-manager-plus:latest

# 安装 aws-cli 和 bash 用于密钥同步
RUN apk add --no-cache bash aws-cli

# 复制 Litestream 二进制文件
COPY --from=litestream /usr/local/bin/litestream /usr/local/bin/litestream

# 复制配置与启动脚本
COPY litestream.yml /etc/litestream.yml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

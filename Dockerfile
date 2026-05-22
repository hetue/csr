FROM ccr.ccs.tencentyun.com/storezhang/alpine:3.20.0

LABEL author="storezhang<华寅>" \
    email="storezhang@gmail.com" \
    qq="160290688" \
    wechat="storezhang" \
    description="基于Claude Code中Security Review功能插件，可以将结果转换为PDF格式文件输出。"

# 模块存储目录和环境变量
ENV LIB_PATH=/var/lib/node \
    MODULE_PATH=/var/lib/node/npm \
    NODE_OPTIONS=--openssl-legacy-provider

# 安装依赖并清理缓存（合并所有安装步骤以减少层数）
RUN set -ex && \
    apk update && \
    # 安装工具
    \
    apk --no-cache add nodejs npm git && \
    # 配置依赖，安装大模型前端
    \
    npm config set registry https://registry.npmmirror.com && \
    npm config set cache ${MODULE_PATH} && \
    npm install --global @anthropic-ai/claude-code@latest && \
    # 添加依赖脚本
    wget --quiet --output-document=/usr/bin/log https://gitee.com/storezhang/script/raw/main/core/log.sh && \
    chmod +x /usr/bin/log && \
    \
    # 清理缓存
    npm cache clean --force && \
    rm -rf /var/cache/apk/* /tmp/* /root/.npm

# 复制脚本程序并设置权限
COPY docker /
RUN chmod +x /usr/local/bin/*.sh /usr/local/bin/core/*.sh

# 执行命令
ENTRYPOINT ["/usr/local/bin/csr.sh"]

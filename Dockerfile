FROM ccr.ccs.tencentyun.com/storezhang/alpine:3.20.0

LABEL author="storezhang<华寅>" \
    email="storezhang@gmail.com" \
    qq="160290688" \
    wechat="storezhang" \
    description="基于Claude Code中Security Review功能插件，可以将结果转换为PDF格式文件输出。"

# 复制脚本程序
COPY docker /docker


# 模块存储目录
ENV LIB_PATH /var/lib/node
ENV MODULE_PATH ${LIB_PATH}/npm
# 修复安装其它模块时报SSL Provider错误
ENV NODE_OPTIONS --openssl-legacy-provider

RUN set -ex \
    \
    \
    \
    && apk update \
    \
    # 安装工具
    && apk --no-cache --update add nodejs \
    # 安装Npm依赖管理
    && apk --no-cache --update add npm \
    # 加速Npm
    && npm config set registry https://registry.npmmirror.com \
    && npm config set cache ${MODULE_PATH} \
    && npm install --global @anthropic-ai/claude-code \
    # 安装配套工具
    && apk --no-cache add git openssh-client \
    \
    \
    \
    # 增加执行权限
    && chmod +x /usr/local/bin/* \
    \
    \
    \
    && rm -rf /var/cache/apk/*

# 修改默认参数
ENV PLUGIN_TIMES 10

# 执行命令
ENTRYPOINT ["/usr/local/bin/csr.sh"]

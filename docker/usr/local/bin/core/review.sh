#!/usr/bin/env bash

workdir=${WORKDIR=${CI_WORKDIR=.}}
source=${SOURCE=${CI_SOURCE=main}}
target=${TARGET=${CI_TARGET=main}}
output_file="$1"
output_format="$2"
settings="$3"

dirname=$(dirname "${workdir}")
log debug 开始安全检查 "workdir=${dirname}"

log info 添加到安全目录 "dir=$(pwd)"
git config --global --add safe.directory "$(pwd)" > /dev/null 2>&1 || log warn 安全目录配置失败 "dir=$(pwd)"

# 所有操作都在工作目录中进行
cd "${workdir}" || exit 1

# 检查是否为代码仓库目录
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log warn 非代码仓库目录 "dir=$(pwd)"
else
    log debug 切换分支 "source=${source},target=${target}"
    if ! git switch "${target}" > /dev/null 2>&1; then
        log warn 切换分支失败 "target=${target}"
    fi
fi

# 检查是否相同
if [ "${source}" = "${target}" ]; then
    log info 使用全量安全审核模式 "source=${source},target=${target}"
    diff="$(git rev-list --max-parents=0 HEAD)"
else
    log info 使用差异安全审核模式 "source=${source},target=${target}"

    # 确保分支存在
    if ! git fetch origin "${source}" > /dev/null 2>&1; then
        log warn 获取分支失败 "source=${source}"
    fi
    diff="${source}..${target}"
fi

prompt=$(cat "/opt/dockerat/prompt/security-review.md")
log info 安全审核开始 "dir=$(pwd)"
git diff "${diff}" | claude --print --output-format="${output_format}" --settings "${settings}" security-review "${prompt}" > "${output_file}"
log info 安全审核完成 "dir=$(pwd),filename=${output_file}"

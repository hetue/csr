#!/bin/bash

workdir=${WORKDIR=${CI_WORKDIR=.}}
source=${SOURCE=${CI_SOURCE=master}}
target=${TARGET=${CI_TARGET=master}}
output_file="$1"
output_format="$2"
settings_file="$3"

log debug 开始安全检查 "workdir=${workdir}"

log debug 切换分支 "source=${source}, target=${target}"
git switch "${target}"

# 所有操作都在工作目录中进行
cd "${workdir}" || exit

log info 添加到安全目录 "dir=$(pwd)"
git config --global --add safe.directory "$(pwd)"

# 检查是否相同
if [ "${source}" = "${target}" ]; then
    log info 全量安全审核模式 "source=${source}, target=${target}"

    # 将所有代码调整为修改状态
    rm -rf .git
    git init > /dev/null 2>&1

    prompt="使用中文进行安全审核，对当前目录下的所有代码进行全量安全审核。"
else
    log info 差异安全审核模式 "source=${source}, target=${target}"

    # 确保分支存在
    git fetch origin "${source}" > /dev/null 2>&1 || true

    prompt="使用中文进行安全审核，重点审核从 ${target} 分支到 ${source} 分支的代码变更部分。"
fi

log info 安全审核开始 "dir=$(pwd)"
claude --print --output-format="${output_format}" --settings "${settings_file}" security-review "${prompt}" > "${output_file}"
log info 安全审核完成 "dir=$(pwd), filename=${output_file}"

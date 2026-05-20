#!/bin/bash

workdir=${WORKDIR=${CI_WORKDIR=.}}
source=${SOURCE=${CI_SOURCE=master}}
target=${TARGET=${CI_TARGET=master}}
output_file="$1"
output_format="$2"
settings_file="$3"

dirname=$(dirname "${workdir}")
log debug 开始安全检查 "workdir=${dirname})"

# 所有操作都在工作目录中进行
cd "${workdir}" || exit 1

# 检查是否为代码仓库目录
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log warn 非代码仓库目录 "dir=$(pwd)"
else
    log info 添加到安全目录 "dir=$(pwd)"
    git config --global --add safe.directory "$(pwd)" > /dev/null 2>&1 || log warn 安全目录配置失败 "dir=$(pwd)"

    log debug 切换分支 "source=${source}, target=${target}"
    if ! git switch "${target}" > /dev/null 2>&1; then
        log warn 切换分支失败 "target=${target}"
    fi
fi

# 检查是否相同
if [ "${source}" = "${target}" ]; then
    log info 全量安全审核模式 "source=${source}, target=${target}"

    # 将所有代码调整为修改状态
    rm -rf .git
    if ! git init > /dev/null 2>&1; then
        log warn git初始化失败 "dir=$(pwd)"
    fi

    prompt="使用中文进行安全审核，对当前目录下的所有代码进行全量安全审核。请确保所有的漏洞描述、风险等级、安全漏洞名称、危害分析、修复建议和总结都完全使用简体中文撰写。绝对不能输出任何英文的分析内容。"
else
    log info 差异安全审核模式 "source=${source}, target=${target}"

    # 确保分支存在
    if ! git fetch origin "${source}" > /dev/null 2>&1; then
        log warn 获取分支失败 "source=${source}"
    fi

    prompt="使用中文进行安全审核，重点审核从 ${target} 分支到 ${source} 分支的代码变更部分。请确保所有的漏洞描述、风险等级、安全漏洞名称、危害分析、修复建议和总结都完全使用简体中文撰写。绝对不能输出任何英文的分析内容。"
fi

log info 安全审核开始 "dir=$(pwd)"
claude --print --output-format="${output_format}" --settings "${settings_file}" security-review "${prompt}" > "${output_file}"
log info 安全审核完成 "dir=$(pwd), filename=${output_file}"

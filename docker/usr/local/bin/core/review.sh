#!/bin/bash

workdir=${WORKDIR=${CI_WORKDIR=.}}
branch=${BRANCH=${CI_BRANCH=master}}

log debug 开始安全检查 "workdir=${workdir}"

log debug 切换分支 "branch=${branch}"
git switch "${branch}"

# 所有操作都在工作目录中进行
cd "${workdir}" || exit

log info 将所有代码调整为修改状态 "dir=$(pwd)"
rm -rf .git
git init > /dev/null 2>&1

log info 添加到安全目录 "dir=$(pwd)"
git config --global --add safe.directory "$(pwd)"

log info 安全审核开始 "dir=$(pwd)"
prompt="使用中文交流，不论后续是否使用为非中文"
claude --print --output-format="$2" --settings "$3" security-review ${prompt} > "$1"
log info 安全审核完成 "dir=$(pwd), filename=$1"

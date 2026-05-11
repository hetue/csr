#!/bin/bash

workdir=${WORKDIR=${CI_WORKDIR=.}}

log debug 开始安全检查 "{workdir: ${workdir}}"

# 所有操作都在工作目录中进行
cd "${workdir}" || exit

# 将所有代码调整为修改状态
rm -rf .git
git init > /dev/null 2>&1

prompt="使用中文交流，不论后续是否使用为非中文"
claude --print --output-format="$2" --settings "$3" security-review ${prompt} > "$1"

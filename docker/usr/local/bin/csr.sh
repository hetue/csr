#!/usr/bin/env bash

# 当前脚本路径
script=$(cd "$(dirname "$0")" || exit; pwd)

# 初始化配置
settings=$("${script}"/core/init.sh)

# 修正格式
format=$("${script}"/core/fix_format.sh)
# 修正扩展名
filename=$("${script}"/core/fixname.sh "${format}")

# 安全审计
"${script}"/core/review.sh "${filename}" "${format}" "${settings}"

# 检查安全级别
if "${script}"/core/check.sh "${filename}"; then
  # 翻译
  "${script}"/core/translate.sh "${filename}" "${settings}"
fi

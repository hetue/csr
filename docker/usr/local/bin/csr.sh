#!/bin/bash

# 初始化配置
settings=$(core/init.sh)

# 修正格式
format=$(core/fix_format.sh)
# 修正扩展名
filename=$(core/fixname.sh "${format}")

# 安全审计
core/review.sh "${filename}" "${format}" "${settings}"

#!/bin/bash

filename=${FILENAME:${CI_FILENAME:security.pdf}}
original=$(script/fixname.sh "${filename}")
log info 开始执行 "{filename: ${filename}}"

# 安全审计
script/review.sh "${original}"

# 格式转换
script/convert.sh "${original}" "${filename}"

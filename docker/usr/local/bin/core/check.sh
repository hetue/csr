#!/bin/bash

# 检查审核结果中是否包含高级别及以上的安全问题
# 参数：$1 - 审核报告文件路径

report_file="$1"

if [ -z "${report_file}" ]; then
    log error 未指定审核报告文件
    exit 1
fi

if [ ! -f "${report_file}" ]; then
    log error 审核报告文件不存在 "filename=${report_file}"
    exit 1
fi

log info 检查安全级别 "filename=${report_file}"

# 检查是否包含高级别安全问题（支持中英文）
if grep -iE "(高危|严重|critical|high)" "${report_file}" > /dev/null 2>&1; then
    log error 发现高级别安全问题 "filename=${report_file}"
    exit 1
else
    log info 安全级别检查通过 "filename=${report_file}"
    exit 0
fi

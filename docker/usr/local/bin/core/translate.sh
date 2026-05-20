#!/bin/bash

# 翻译脚本 - 用于将产出翻译为目标语言
# 参数：
#   $1 - 输入文件路径（必需）
#   $2 - 输出文件路径（可选，默认覆盖输入文件）
# 环境变量：
#   LANGUAGE - 目标语言（如：en, ja, ko等）。如果未设置或为空，则跳过翻译
#   CI_LANGUAGE - CI环境中的目标语言（备用）

input_file="$1"
output_file="${2:-$1}"
language="${LANGUAGE:-${CI_LANGUAGE}}"

# 检查输入文件参数
if [ -z "${input_file}" ]; then
    log error 未指定输入文件
    exit 1
fi

# 检查输入文件是否存在
if [ ! -f "${input_file}" ]; then
    log error 输入文件不存在 "filename=${input_file}"
    exit 1
fi

# 检查是否需要翻译
if [ -z "${language}" ]; then
    log info 未设置翻译语言，跳过翻译 "filename=${input_file}"
    # 如果输入输出文件不同，且未设置翻译语言，则复制文件
    if [ "${input_file}" != "${output_file}" ]; then
        cp "${input_file}" "${output_file}"
        log info 已复制文件 "from=${input_file}, to=${output_file}"
    fi
    exit 0
fi

# 语言映射和验证
case "${language}" in
    en|english|英文)
        target_lang="English"
        ;;
    ja|japanese|日文|日语)
        target_lang="Japanese"
        ;;
    ko|korean|韩文|韩语)
        target_lang="Korean"
        ;;
    zh|chinese|中文)
        target_lang="Chinese"
        ;;
    zh-cn|simplified|简体中文)
        target_lang="Simplified Chinese"
        ;;
    zh-tw|traditional|繁体中文)
        target_lang="Traditional Chinese"
        ;;
    fr|french|法文|法语)
        target_lang="French"
        ;;
    de|german|德文|德语)
        target_lang="German"
        ;;
    es|spanish|西班牙文|西班牙语)
        target_lang="Spanish"
        ;;
    ru|russian|俄文|俄语)
        target_lang="Russian"
        ;;
    *)
        log warn 不支持的翻译语言 "lang=${language}, supports=[en, ja, ko, zh, zh-cn, zh-tw, fr, de, es, ru]"
        exit 1
        ;;
esac

log info 开始翻译 "from=${input_file}, to=${output_file}, lang=${target_lang}"

# 创建临时文件用于存储翻译结果
temp_file=$(mktemp)

# 构建翻译提示词
translate_prompt="Please translate the following security review report to ${target_lang}.

Requirements:
1. Maintain the original document structure and formatting
2. Keep all technical terms accurate
3. Preserve code snippets, file paths, and variable names unchanged
4. Ensure professional and precise translation

Please translate the content from the file: ${input_file}"

# 执行翻译
if claude --print "${translate_prompt}" > "${temp_file}" 2>&1; then
    # 翻译成功，移动临时文件到输出文件
    mv "${temp_file}" "${output_file}"
    log info 翻译完成 "filename=${output_file}, lang=${target_lang}"
    exit 0
else
    # 翻译失败
    log error 翻译失败 "filename=${input_file}, lang=${target_lang}"
    rm -f "${temp_file}"
    exit 1
fi

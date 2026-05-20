#!/bin/bash

# 格式转换脚本 - 用于将报告转换为不同格式
# 参数：
#   $1 - 输入文件路径（必需）
#   $2 - 输出格式（可选，从环境变量OUTPUT_FORMAT读取，默认为markdown）
# 环境变量：
#   FORMAT - 目标格式（如：pdf, html, docx等）。如果未设置或与当前格式相同，则跳过转换
#   CI_FORMAT - CI环境中的目标格式（备用）

input_file="$1"
output_format="${2:-${FORMAT:${CI_FORMAT:-markdown}}}"

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

# 获取输入文件的扩展名
input_ext="${input_file##*.}"

# 判断当前格式
case "${input_ext}" in
    md|markdown)
        current_format="markdown"
        ;;
    pdf)
        current_format="pdf"
        ;;
    html|htm)
        current_format="html"
        ;;
    docx)
        current_format="docx"
        ;;
    *)
        current_format="markdown"
        ;;
esac

# 检查是否需要转换
if [ "${output_format}" = "${current_format}" ] || [ "${output_format}" = "markdown" ]; then
    log info 无需格式转换 "format=${current_format}"
    exit 0
fi

# 检查是否安装格式转换软件
if ! command -v pandoc > /dev/null 2>&1; then
    log warn 软件包未被安装 "package=pandoc"
    exit 0
fi

log info 开始格式转换 "from=${current_format}, to=${output_format}, file=${input_file}"

# 生成输出文件名
output_file="${input_file%.*}.${output_format}"

# 根据目标格式执行转换
case "${output_format}" in
    pdf)
        # 检查是否安装了xelatex
        if ! command -v xelatex > /dev/null 2>&1; then
            log warn 软件包未被安装 "package=texlive-xetex"
            exit 0
        fi

        if pandoc "${input_file}" -o "${output_file}" \
            --pdf-engine=xelatex \
            --variable mainfont="SimSun" \
            --variable CJKmainfont="SimSun" \
            --variable geometry:margin=1in \
            2>&1; then
            log info 格式转换完成 "filename=${output_file}, format=pdf"
        else
            log error 格式转换失败 "filename=${input_file}, format=pdf"
            exit 1
        fi
        ;;

    html)
        if pandoc "${input_file}" -o "${output_file}" \
            --standalone \
            --self-contained \
            --css=<(echo "body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }") \
            2>&1; then
            log info 格式转换完成 "filename=${output_file}, format=html"
        else
            log error 格式转换失败 "filename=${input_file}, format=html"
            exit 1
        fi
        ;;

    docx)
        if pandoc "${input_file}" -o "${output_file}" \
            --reference-doc=<(echo "") \
            2>&1; then
            log info 格式转换完成 "filename=${output_file}, format=docx"
        else
            log error 格式转换失败 "filename=${input_file}, format=docx"
            exit 1
        fi
        ;;

    *)
        log warn 不支持的输出格式 "format=${output_format}, supports=[pdf, html, docx]"
        exit 1
        ;;
esac

exit 0

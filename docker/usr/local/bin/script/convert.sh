#!/bin/bash

from=$1
to=$2
if [[ "${to}" =~ \.(md|json)$ ]]; then
    return
fi

log info 开始转换格式 "{from: ${from}, to: ${to}}"
if [[ "${to}" == *.pdf ]]; then
    pandoc "${from}" -o "${to}" --pdf-engine=xelatex
fi

#!/bin/bash

filename=${FILENAME=${CI_FILENAME=security}}

# 修正格式
if [[ "$1" == "text" ]]; then
    ext="md"
fi

echo "${filename}.${ext}"

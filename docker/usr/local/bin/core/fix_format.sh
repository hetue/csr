#!/usr/bin/env bash

format=${FORMAT=${CI_FORMAT=text}}

# 修正格式
if [[ ! "${format}" =~ ^(json|stream-json)$ ]]; then
    format="text"
fi

echo "${format}"

#!/bin/bash

workdir=${WORKDIR:${CI_WORKDIR:.}}

log debug 开始安全检查 "{workdir: ${workdir}}"

prompt="使用中文交流，不论后续是否使用为非中文"
claude security-review --print ${prompt} > "$1"

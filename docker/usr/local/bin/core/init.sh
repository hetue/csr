#!/bin/bash

code=0

baseurl=${BASEURL=${CI_BASEURL}}
apikey=${APIKEY=${CI_APIKEY}}
haiku=${HAIKU=${CI_HAIKU="claude-sonnet-4-6"}}
sonnet=${SONNET=${CI_SONNET="claude-sonnet-4-6"}}
opus=${OPUS=${CI_SONNET="claude-sonnet-4-6"}}
reasoning=${REASONING=${CI_REASONING="claude-sonnet-4-6"}}
subagent=${SUBAGENT=${CI_SUBAGENT="claude-sonnet-4-6"}}
model=${MODEL=${CI_MODEL=${sonnet}}}

# 检查模型调用路径
if [[ "${baseurl}" == "" ]]; then
    log error 配置无效 "exception=缺少模型基础路径"
    code=1
fi
if [ "${code}" -ne 0 ]; then
    exit ${code}
fi

# 检查模型调用密钥
if [[ "${apikey}" == "" ]]; then
    log error 配置无效 "exception=缺少模型调用密钥"
    code=2
fi
if [ "${code}" -ne 0 ]; then
    exit ${code}
fi

# 创建临时目录
mkdir --parent /tmp

# 输出到控制台
cat << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${apikey}",
    "ANTHROPIC_BASE_URL": "${baseurl}",
    "ANTHROPIC_MODEL": "${model}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${haiku}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${sonnet}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "${opus}",
    "ANTHROPIC_REASONING_MODEL": "${reasoning}",
    "CLAUDE_CODE_SUBAGENT_MODEL": "${subagent}",
    "ENABLE_TOOL_SEARCH": "true",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "true",
    "CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
EOF

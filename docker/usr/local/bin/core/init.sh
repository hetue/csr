#!/usr/bin/env bash

code=0

baseurl=${BASEURL=${CI_BASEURL}}
apikey=${APIKEY=${CI_APIKEY}}
haiku=${HAIKU=${CI_HAIKU="claude-haiku-4-5"}}
sonnet=${SONNET=${CI_SONNET="claude-sonnet-4-6"}}
opus=${OPUS=${CI_SONNET="claude-sonnet-4-6"}}
reasoning=${REASONING=${CI_REASONING="claude-sonnet-4-6"}}
subagent=${SUBAGENT=${CI_SUBAGENT="claude-sonnet-4-6"}}
model=${MODEL=${CI_MODEL=${sonnet}}}
language=${LANGUAGE=${CI_LANGUAGE=${chinese}}}

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

language="${language%%:*}"
language="${language%%_*}"
# 语言映射和验证
case "${language}" in
  en|english|英文)
    translate_english="English"
    translate_chinese=英文
    ;;
  ja|japanese|日文|日语)
    translate_english="Japanese"
    translate_chinese=日文
    ;;
  ko|korean|韩文|韩语)
    translate_english="Korean"
    translate_chinese=韩文
    ;;
  zh|chinese|中文)
    translate_english="Chinese"
    translate_chinese=中文
    ;;
  zh-cn|simplified|简体中文)
    translate_english="Simplified Chinese"
    translate_chinese=简体中文
    ;;
  zh-tw|traditional|繁体中文)
    translate_english="Traditional Chinese"
    translate_chinese=繁体中文
    ;;
  fr|french|法文|法语)
    translate_english="French"
    translate_chinese=法文
    ;;
  de|german|德文|德语)
    translate_english="German"
    translate_chinese=德文
    ;;
  es|spanish|西班牙文|西班牙语)
    translate_english="Spanish"
    translate_chinese=西班牙文
    ;;
  ru|russian|俄文|俄语)
    translate_english="Russian"
    translate_chinese=俄文
    ;;
  *)
    translate_english="Chinese"
    translate_chinese=中文
    ;;
esac

# 创建临时目录
mkdir --parent /tmp

# 替换语言
workdir=${WORKDIR=${CI_WORKDIR=.}}
sed "s/\${translate_english}/$translate_english/g; s/\${translate_chinese}/$translate_chinese/g" /opt/dockerat/prompt/language.md > "${workdir}/CLAUDE.md"

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

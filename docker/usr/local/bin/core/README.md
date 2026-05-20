# 翻译和格式转换功能说明

## 概述

提供两个独立的功能：
- **翻译脚本** (translate.sh): 将安全审核报告翻译为目标语言，保持原文件格式
- **格式转换脚本** (convert.sh): 将报告转换为不同格式（PDF、HTML、DOCX）

## 环境变量

- `LANGUAGE` / `CI_LANGUAGE`: 目标语言代码（用于翻译）
- `FORMAT` / `CI_FORMAT`: 输出格式（用于格式转换，如：pdf, html, docx）

## 支持的语言

| 代码 | 语言 | 别名 |
|------|------|------|
| en | English | english, 英文 |
| ja | Japanese | japanese, 日文, 日语 |
| ko | Korean | korean, 韩文, 韩语 |
| zh | Chinese | chinese, 中文 |
| zh-cn | Simplified Chinese | simplified, 简体中文 |
| zh-tw | Traditional Chinese | traditional, 繁体中文 |
| fr | French | french, 法文, 法语 |
| de | German | german, 德文, 德语 |
| es | Spanish | spanish, 西班牙文, 西班牙语 |
| ru | Russian | russian, 俄文, 俄语 |

## 支持的输出格式

- `markdown` (默认): Markdown格式
- `pdf`: PDF格式（需要pandoc和texlive-xetex）
- `html`: HTML格式（需要pandoc）
- `docx`: Word文档格式（需要pandoc）

## 使用方法

### 自动处理（推荐）

在csr.sh执行流程中自动处理：

```bash
# 仅翻译为英文（保持markdown格式）
LANGUAGE=en ./csr.sh

# 仅转换为PDF
FORMAT=pdf ./csr.sh

# 翻译为日文并转换为PDF
LANGUAGE=ja FORMAT=pdf ./csr.sh

# 翻译为英文并转换为HTML
LANGUAGE=en FORMAT=html ./csr.sh
```

### 手动翻译

单独使用翻译脚本：

```bash
# 基本用法（保持原格式）
LANGUAGE=en translate.sh input.md

# 翻译为日文
LANGUAGE=ja translate.sh report.md report_ja.md
```

### 手动格式转换

单独使用格式转换脚本：

```bash
# 转换为PDF
FORMAT=pdf convert.sh report.md

# 转换为HTML
FORMAT=html convert.sh report.md

# 转换为DOCX
FORMAT=docx convert.sh report.md
```

## 依赖安装

### PDF输出

需要安装pandoc和texlive-xetex：

```bash
# Ubuntu/Debian
apt-get install pandoc texlive-xetex

# macOS
brew install pandoc
brew install --cask mactex
```

### HTML/DOCX输出

只需要安装pandoc：

```bash
# Ubuntu/Debian
apt-get install pandoc

# macOS
brew install pandoc
```

## 执行流程

在csr.sh中的执行顺序：

1. **init.sh** - 初始化配置
2. **fix_format.sh** - 修正格式
3. **fixname.sh** - 修正文件名
4. **review.sh** - 安全审核
5. **check.sh** - 检查安全级别
6. **translate.sh** - 翻译（仅在设置LANGUAGE时）
7. **convert.sh** - 格式转换（仅在FORMAT不同于当前格式时）

## 工作原理

### 翻译脚本 (translate.sh)

- 检查 `LANGUAGE` 或 `CI_LANGUAGE` 环境变量
- 如果未设置，跳过翻译
- 如果设置，调用Claude进行翻译
- 保持原文档格式和技术术语
- 代码片段、文件路径、变量名不翻译

### 格式转换脚本 (convert.sh)

- 检查 `FORMAT` 或 `CI_FORMAT` 环境变量
- 如果未设置或与当前格式相同，跳过转换
- 如果设置且不同，使用pandoc进行转换
- 如果pandoc未安装，给出提示并跳过

## 示例

### CI/CD集成

```yaml
# GitLab CI
security-review-en-pdf:
  script:
    - export LANGUAGE=en
    - export FORMAT=pdf
    - ./csr.sh
  artifacts:
    paths:
      - "*.pdf"

security-review-ja-html:
  script:
    - export LANGUAGE=ja
    - export FORMAT=html
    - ./csr.sh
  artifacts:
    paths:
      - "*.html"
```

### Docker环境

```bash
# 生成英文PDF报告
docker run \
  -e LANGUAGE=en \
  -e FORMAT=pdf \
  -v $(pwd):/workspace \
  your-image:latest \
  csr.sh

# 生成日文HTML报告
docker run \
  -e LANGUAGE=ja \
  -e FORMAT=html \
  -v $(pwd):/workspace \
  your-image:latest \
  csr.sh
```

### 批量生成多语言多格式报告

```bash
#!/bin/bash

# 先生成中文markdown报告
./csr.sh

# 翻译为多种语言
for lang in en ja ko; do
  LANGUAGE=$lang translate.sh report.md "report_${lang}.md"
done

# 转换为多种格式
for format in pdf html docx; do
  FORMAT=$format convert.sh report.md
done
```

## 注意事项

1. 如果未设置环境变量，相应步骤会自动跳过
2. 翻译和格式转换是独立的，可以单独使用
3. 格式转换只在输出格式与当前格式不同时执行
4. 翻译仅在安全检查通过后执行
5. 格式转换在所有步骤的最后执行
6. 如果依赖工具未安装，会给出提示但不会失败

## 故障排除

### 翻译被跳过

检查环境变量：
```bash
echo $LANGUAGE
echo $CI_LANGUAGE
```

### 格式转换被跳过

检查环境变量和当前格式：
```bash
echo $FORMAT
echo $CI_FORMAT
# 如果当前已经是目标格式，会自动跳过
```

### pandoc未安装

```bash
# 检查pandoc
which pandoc
pandoc --version

# 安装pandoc
apt-get install pandoc  # Ubuntu/Debian
brew install pandoc     # macOS
```

### PDF转换失败

检查xelatex：
```bash
which xelatex
xelatex --version

# 安装texlive-xetex
apt-get install texlive-xetex  # Ubuntu/Debian
brew install --cask mactex     # macOS
```

## 扩展

### 添加新语言

编辑 translate.sh 中的语言映射：

```bash
case "${language}" in
    # 添加新语言
    pt|portuguese|葡萄牙语)
        target_lang="Portuguese"
        ;;
    # ... 其他语言
esac
```

### 添加新格式

编辑 convert.sh 中的格式转换：

```bash
case "${output_format}" in
    # 添加新格式
    epub)
        pandoc "${input_file}" -o "${output_file}" --to=epub
        ;;
    # ... 其他格式
esac
```

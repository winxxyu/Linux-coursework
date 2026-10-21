#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
mkdir -p "$output/sentry_ws"
cp -r "$input"/* "$output/sentry_ws/"
mkdir -p "$output/sentry_ws/backup"
if [ -f "$output/sentry_ws/config/robot.conf" ]; then
    cp "$output/sentry_ws/config/robot.conf" "$output/sentry_ws/backup/robot.conf"
fi
if [ -d "$output/sentry_ws/scripts" ]; then
    chmod +x "$output/sentry_ws/scripts"/*.sh 2>/dev/null || true
fi




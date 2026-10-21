#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

# TODO：删除下方提示和 exit 77，再填写你的命令。
source "$input/bonus.env"
if [ "$action" = "start" ]; then
    mkdir -p "$output"
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" \
        "python3 \"$WORKER_TOOL\" --token \"$TOKEN\" --log \"$output/bonus.log\""
elif [ "$action" = "stop" ]; then
    tmux -L "$TMUX_SOCKET" send-keys -t "$SESSION" C-c 2>/dev/null || true
    sleep 1
    tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
fi


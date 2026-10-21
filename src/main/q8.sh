#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

# TODO：删除下方提示和 exit 77，再填写你的命令。
# 引入 process.env 配置文件，获取目标 PID、TOKEN、服务 PID 和端口等变量
source "$input/process.env"

# ==================== 分支一：REPAIR 阶段 ====================
if [ "$action" = "repair" ]; then
    mkdir -p "$output"

    # --- 任务 A1：定位并记录目标采集器进程信息 ---
    # 利用 ps 配合 grep 精准定位包含 TARGET_TOKEN 且排除 grep 自身的进程行
    # 利用 process.env 中的 TARGET_PID 精准过滤出目标进程行
target_line=$(ps aux | awk -v pid="$TARGET_PID" '$2 == pid' || true)

if [ -n "$target_line" ]; then
    t_pid=$(echo "$target_line" | awk '{print $2}')
    t_user=$(echo "$target_line" | awk '{print $1}')
    t_state=$(echo "$target_line" | awk '{print $8}')
    t_cmd=$(echo "$target_line" | cut -d' ' -f11-)
else
    t_pid="${TARGET_PID:-UNKNOWN}"
    t_user="UNKNOWN"
    t_state="UNKNOWN"
    t_cmd="UNKNOWN"
fi

cat << EOF > "$output/process.txt"
pid=$t_pid
user=$t_user
state=$t_state
command=$t_cmd
EOF


    # --- 任务 A2：保存至少两条目标采集器的 TICK 日志 ---
    tail -n 2 "$WORKER_LOG" > "$output/collector-sample.log" || true

    # --- 任务 A3：向目标 PID 发送普通终止信号（优雅停止），并等待退出 ---
    if [ "$t_pid" != "UNKNOWN" ]; then
        kill "$t_pid" 2>/dev/null || true
        # 等待其正常退出（最多等待几秒）
        for i in {1..5}; do
            if ! kill -0 "$t_pid" 2>/dev/null; then
                break
            fi
            sleep 1
        done
    fi

    # --- 任务 B1：正常停止 SERVICE_PID 指定的原 HTTP 服务 ---
    if [ -n "${SERVICE_PID:-}" ]; then
        kill "$SERVICE_PID" 2>/dev/null || true
        for i in {1..5}; do
            if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
    fi

    # --- 任务 B2：生成修复后的 server.conf 配置 ---
    mkdir -p "$output/service"
    cat << EOF > "$output/server.conf"
bind=127.0.0.1
port=$TARGET_PORT
route=/status
EOF

    # --- 任务 B3：使用教师启动工具运行修复后的服务 ---
    mkdir -p "$output/service/pid"
    bash "$START_TOOL" "$output/server.conf" "$output/service" >/dev/null 2>&1 || true

    # --- 任务 B4：有界重试等待服务就绪，并通过 curl 检查状态 ---
    # 最多尝试 10 次，每次间隔 1 秒
    success=0
    for i in {1..10}; do
        if curl -s http://127.0.0.1:"$TARGET_PORT"/status > "$output/http-body.txt" 2>&1; then
            # 检查 HTTP 状态码是否为 200
            http_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:"$TARGET_PORT"/status || echo "000")
            if [ "$http_code" -eq 200 ]; then
                success=1
                break
            fi
        fi
        sleep 1
    done

    # 记录 http-status.txt（要求内容为一行状态码，如 200）
    if [ "$success" -eq 1 ]; then
        echo "200" > "$output/http-status.txt"
    else
        echo "000" > "$output/http-status.txt"
    fi

# ==================== 分支二：CLEANUP 阶段 ====================
elif [ "$action" = "cleanup" ]; then
    # 根据服务状态目录定位修复后的服务进程并停止它，释放端口
    # 如果 service 目录下记录了 pid 文件或可以根据 server.conf 查找，则进行安全终止
    # 此处检查常见的服务进程或通过 ss/fuser 释放端口
    service_pid_file="$output/service/pid/service.pid"
    if [ -f "$service_pid_file" ]; then
        s_pid=$(cat "$service_pid_file")
        kill "$s_pid" 2>/dev/null || true
    fi
    # 也可以通过端口查找并终止（确保 cleanup 彻底释放端口）
    pids_on_port=$(ss -lptn "sport = :$TARGET_PORT" 2>/dev/null | grep -oP 'pid=\K[0-9]+' || true)
    for p in $pids_on_port; do
        kill "$p" 2>/dev/null || true
    done
fi


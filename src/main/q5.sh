#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
source $input/launch.env
bash $LAUNCH_TOOL $MODEL_PATH $CAMERA_PATH > $output/stdout.log 2> $output/stderr.log || true
exit_code=$?
printf '%s\n' $exit_code > $output/exit-code.txt
if [ "$exit_code" -eq 0 ]; then
    result="SUCCESS"
    reason="NONE"
elif [ "$exit_code" -eq 10 ]; then
    result="FAILED"
    reason="MODEL_MISSING"
elif [ "$exit_code" -eq 20 ]; then
    result="FAILED"
    reason="CAMERA_DENIED"
else
    result="FAILED"
    reason="UNKNOWN"
fi
cat << EOF > "$output/report.txt"
result=$result
exit_code=$exit_code
reason=$reason
EOF



#!/bin/bash
# Q2：创建 sentry_ws 四个子目录、两个空文件以及指定脚本和配置。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# TODO：删除下方提示和 exit 77，再填写你的命令。
mkdir -p $output/sentry_ws/scripts
         $output/sentry_wa/config
         $output/sentry_ws/logs
         $output/sentry_ws/tmp
touch $output/sentry_ws/scripts/hello.sh
      $output/sentry_wa/config/robot.conf
      $output/sentry_ws/logs/.keep
      $output/sentry_ws/tmp/scratch.txt
cat <<EOF > $output/sentry_ws/scripts/hello.sh
#!/bin/bash
echo "Hello, world!"
EOF

cat <<EOF > $output/sentry_wa/config/robot.conf
robot=sentry
mode=training
log_level=INFO
EOF

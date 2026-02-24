#!/bin/bash
# 清空 PATH 以模拟没有任何命令的环境，但需要保留基本的 sh 工具 (如 echo/read)
export PATH="/bin:/usr/bin"

# 临时屏蔽 xcode-select 防止真的再次弹窗安装
alias xcode-select='echo "[模拟弹窗] 苹果系统已为您弹出安装开发者环境对话框..."'
shopt -s expand_aliases

# 读取目标脚本，把等待交互输入的 read 命令替换成总是输入 Y，方便免交互观察
cat "一键开启_刷步网页版_macOS.command" | sed 's/read -p "是否立刻为您呼出自动安装程序.*"/install_py="Y"\n    echo "[自动测试输入] Y"/g' | bash

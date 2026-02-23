#!/bin/bash
echo "========================================================"
echo "       欢迎使用  刷步数智能平台"
echo "========================================================"
echo ""
echo "!!! 苹果 Mac 权限修复提示 !!!"
echo "如果您上次双击本脚本提示无法运行或已损坏，请打开自带的【终端】App，分别粘贴执行下面两句代码（第一句会要求盲输开机密码）："
echo " 1. sudo spctl --master-disable"
echo " 2. chmod +x \"$(cd "$(dirname "$0")"; pwd)/一键开启_刷步网页版_macOS.command\""
echo "执行完后去 系统设置 -> 隐私与安全性 勾选【任何来源】即可。"
echo "========================================================"
echo ""
echo "正在检测本机局域网地址..."
IP=$(ipconfig getifaddr en0)
if [ -z "$IP" ]; then
    IP=$(ipconfig getifaddr en1)
fi
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi
echo "检测到: $IP"

echo ""
echo "正在检测端口 8080..."
PID=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PID" ]; then
    echo "[警告] 端口 8080 已被进程 $PID 占用"
    read -p "是否强制关闭 [y/n]: " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        kill -9 $PID
        echo "已清除。"
        sleep 2
    else
        echo "已取消。"
        exit 1
    fi
fi

echo ""
echo "[防火墙] macOS 会在首次监听时弹窗询问，届时请点击[允许]。"
echo ""

echo "============================================================="
echo " [本机]    http://127.0.0.1:8080"
echo " [局域网]  http://$IP:8080"
echo " [公网]    请启动 OpenFRP 后使用分配的链接"
echo "============================================================="
echo " * 请勿关闭此窗口"
echo ""

cd "$(dirname "$0")/支持代码_放在运行脚本同目录" || exit

echo ""
echo "正在检查运行环境..."
if ! command -v python3 &>/dev/null; then
    echo -e "\033[31m[错误] 未检测到 Python 3 运行环境！\033[0m"
    echo "本程序需要 Python 3 才能运行。"
    read -p "是否立刻为您呼出自动安装程序？[Y/n]: " install_py
    if [[ "$install_py" != "n" && "$install_py" != "N" ]]; then
        echo "正在为您呼出开发工具包安装..."
        xcode-select --install
        echo "请在弹出的系统窗口中点击“安装”，安装完成后请重新运行本脚本。"
        exit 0
    else
        echo "您取消了安装，程序无法继续。"
        exit 1
    fi
fi

# 获取当前安装的所需依赖数量
MISSING_DEPS=$(pip3 freeze 2>/dev/null | grep -c -E 'fastapi|uvicorn|pydantic|requests|pycryptodome|pytz')
if [ "$MISSING_DEPS" -lt 6 ]; then
    echo -e "\033[33m[提示] 您的环境缺少运行本程序所需的扩展包。\033[0m"
    read -p "是否立刻为您从国内高速通道全自动下载并安装？[Y/n]: " install_dep
    if [[ "$install_dep" != "n" && "$install_dep" != "N" ]]; then
        echo "正在通过清华大学镜像源极速安装依赖库..."
        pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
    else
        echo -e "\033[31m[警告] 您跳过了依赖安装，服务可能无法正常启动！\033[0m"
    fi
fi

(sleep 3 && open http://127.0.0.1:8080) &

python3 app.py

echo ""
echo "[错误] 服务异常终止，请检查上方报错。"
read -p "按回车键退出..."

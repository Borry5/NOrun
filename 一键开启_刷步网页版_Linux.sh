#!/bin/bash
echo "========================================================"
echo "       欢迎使用  刷步数智能平台"
echo "========================================================"
echo ""
echo "正在检测本机局域网地址..."
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi
echo "检测到: $IP"

echo ""
echo "正在检测端口 8080..."
PID=$(lsof -ti:8080 2>/dev/null || fuser 8080/tcp 2>/dev/null)
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
echo "正在检查防火墙..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | grep -E "8080/tcp.*ALLOW")
    if [ -z "$UFW_STATUS" ]; then
        echo "[防火墙] UFW 未放行 8080 端口，局域网设备可能无法访问。"
        read -p "是否一键放行 [y/n]: " fwchoice
        if [[ "$fwchoice" == "y" || "$fwchoice" == "Y" ]]; then
            sudo ufw allow 8080/tcp
            echo "已放行。还原: sudo ufw delete allow 8080/tcp"
            sleep 2
        else
            echo "已跳过。"
        fi
    fi
else
    echo "[防火墙] 未检测到 UFW。如用 firewalld 等请自行确认 8080 已放行。"
fi
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
    read -p "是否立刻为您尝试全自动安装？[Y/n]: " install_py
    if [[ "$install_py" != "n" && "$install_py" != "N" ]]; then
        echo "正在尝试使用系统包管理器自动安装 Python3..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip
        elif command -v yum &>/dev/null; then
            sudo yum install -y python3 python3-pip
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm python python-pip
        else
            echo "不支持的发行版，请手动安装 Python3。"
            exit 1
        fi
    else
        echo "您取消了安装，程序无法继续。"
        exit 1
    fi
fi

MISSING_DEPS=$(pip3 freeze 2>/dev/null | grep -c -E 'fastapi|uvicorn|pydantic|requests|pycryptodome|pytz')
if [ "$MISSING_DEPS" -lt 6 ]; then
    echo -e "\033[33m[提示] 您的环境缺少运行本程序所需的扩展包。\033[0m"
    read -p "是否立刻为您从国内极速通道全自动安装？[Y/n]: " install_dep
    if [[ "$install_dep" != "n" && "$install_dep" != "N" ]]; then
        echo "正在通过清华源安装依赖..."
        pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
    fi
fi

if command -v xdg-open &> /dev/null; then
    (sleep 3 && xdg-open http://127.0.0.1:8080 >/dev/null 2>&1) &
fi

python3 app.py

echo ""
echo "[错误] 服务异常终止，请检查上方报错。"
read -p "按回车键退出..."

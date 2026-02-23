@echo off
chcp 65001 >nul
title Web Service
color 0b

echo ========================================================
echo        欢迎使用  刷步数智能平台
echo ========================================================
echo.

rem === 获取局域网 IP ===
rem 直接用 netsh 按网卡名查询，精准排除所有虚拟网卡
echo 正在检测本机局域网地址...
set "IP=127.0.0.1"
for /f "tokens=2 delims=:" %%a in ('netsh interface ip show address "WLAN" 2^>nul ^| findstr /C:"IP" ^| findstr "192.168."') do for /f "tokens=*" %%b in ("%%a") do set "IP=%%b"
if "%IP%"=="127.0.0.1" for /f "tokens=2 delims=:" %%a in ('netsh interface ip show address "Wi-Fi" 2^>nul ^| findstr /C:"IP" ^| findstr "192.168."') do for /f "tokens=*" %%b in ("%%a") do set "IP=%%b"
if "%IP%"=="127.0.0.1" for /f "tokens=2 delims=:" %%a in ('netsh interface ip show address "Ethernet" 2^>nul ^| findstr /C:"IP" ^| findstr "192.168."') do for /f "tokens=*" %%b in ("%%a") do set "IP=%%b"
if "%IP%"=="127.0.0.1" for /f "tokens=2 delims=:" %%a in ('netsh interface ip show address ^| findstr /C:"IP" ^| findstr "192.168."') do for /f "tokens=*" %%b in ("%%a") do set "IP=%%b"
set "IP=%IP: =%"
echo 检测到局域网 IP: %IP%
echo.

rem === 检测端口占用 ===
echo 正在检测端口 8080...
set "PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "0.0.0.0:8080" 2^>nul') do if not defined PID set "PID=%%a"
if defined PID call :ask_kill
goto :check_fw

:ask_kill
echo.
echo [警告] 端口 8080 已被进程 %PID% 占用
set /p "choice=是否强制关闭 [y/n]: "
if /i "%choice%"=="y" (
    taskkill /F /PID %PID% >nul 2>nul
    echo 已清除。
    timeout /t 2 >nul
) else (
    echo 已取消。
    pause
    exit /b
)
goto :eof

rem === 防火墙检测 ===
:check_fw
echo.
echo 正在检查防火墙...
netsh advfirewall firewall show rule name="8080" >nul 2>nul
if errorlevel 1 call :ask_fw
goto :start_server

:ask_fw
echo [防火墙] 8080 端口未放行，局域网设备可能无法访问。
set /p "fwchoice=是否一键放行 [y/n]: "
if /i "%fwchoice%"=="y" (
    echo netsh advfirewall firewall add rule name="8080" dir=in action=allow protocol=TCP localport=8080 profile=any> "%TEMP%\mfw.bat"
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c','%TEMP%\mfw.bat' -Verb RunAs -WindowStyle Hidden"
    timeout /t 3 >nul
    echo 防火墙已放行。
    echo 还原: Win+R 输入 wf.msc, 删除入站规则 8080
)
goto :eof

rem === 启动服务 ===
:start_server
echo.
echo =============================================================
echo  [本机]    http://127.0.0.1:8080
echo  [局域网]  http://%IP%:8080
echo  [公网]    请启动 OpenFRP 后使用分配的链接
echo =============================================================
echo  * 请勿关闭此窗口
echo.

cd /d "%~dp0\支持代码_放在运行脚本同目录"

echo.
echo 正在检查运行环境...
set "PY_CMD="
if exist "c:\programdata\anaconda3\python.exe" set "PY_CMD=c:\programdata\anaconda3\python.exe"
if not defined PY_CMD (
    for %%i in (python.exe) do if not "%%~$PATH:i"=="" set "PY_CMD=python"
)

if not defined PY_CMD (
    echo [错误] 本电脑缺少名为 “Python” 的核心运行环境！
    echo -------------------------------------------------------------------------
    echo 【什么是 Python？为什么需要它？】
    echo 这是一个运行各种软件的底层驱动引擎。本刷步程序就是基于它开发的，
    echo 因此您的电脑里必须装有这个引擎，本程序才能被成功启动和运行。
    echo.
    echo 别担心，您不需要懂技术。我们可以为您全自动将它安装在默认位置：
    echo 安装路径：C:\Users\您的用户名\AppData\Local\Programs\Python\Python310
    echo 占用空间：约 100 MB。安全、无毒且不会拖慢系统运行。
    echo -------------------------------------------------------------------------
    set /p "install_py=是否立刻允许我们为您高速下载并全自动安装该引擎？[Y/n]: "
    if /i "!install_py!" NEQ "n" (
        echo.
        echo 正在从华为云极速通道为您下载安装包，请耐心等待 1-3 分钟...
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://mirrors.huaweicloud.com/python/3.10.11/python-3.10.11-amd64.exe' -OutFile '%TEMP%\python_installer.exe'"
        echo 下载完成！正在后台静默安装并为您配置环境变量...
        "%TEMP%\python_installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
        echo ---------------------------------------------------------------------
        echo [成功] 引擎安装与配置已全部完成！
        echo 请关闭当前黑框窗口，然后重新双击运行【一键开启】脚本即可正常使用！
        pause
        exit /b
    ) else (
        echo ---------------------------------------------------------------------
        echo 您取消了安装。没有该引擎，本程序无法运行，脚本即将退出。
        pause
        exit /b
    )
)

echo 正在通过清华大学镜像源检查并极速安装依赖库...
%PY_CMD% -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/

start "" cmd /c "timeout /t 3 >nul & start http://127.0.0.1:8080"
%PY_CMD% app.py

echo.
echo [错误] 服务异常终止，请检查上方报错。
pause

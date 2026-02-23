import sys
import os
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import traceback

# 把当前目录加入寻找路径，以便复用原有逻辑
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# 动态配置环境变量绕过原有检查
os.environ["CONFIG"] = '{"USER": "web","PWD": "web"}'
os.chdir(current_dir) # 切换工作目录，避免文件加载（如.env或data）报错

# 导入刷步核心模块
import util.zepp_helper as zeppHelper
import main
from main import AutoStepRunner

# 补全被引用的全局变量
main.user_tokens = dict()

app = FastAPI(title="Web Server")

class SubmitRequest(BaseModel):
    user: str
    pwd: str
    step: int

@app.get("/", response_class=HTMLResponse)
async def get_index():
    index_path = os.path.join(current_dir, "index.html")
    with open(index_path, "r", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())

@app.post("/submit")
async def handle_submit(req: SubmitRequest):
    try:
        # 1. 拦截空数据
        if not req.user or not req.pwd or req.step <= 0:
            return JSONResponse({"success": False, "message": "账号、密码或步数无效。"})
            
        print(f"收到网页提交通求: 账号 {req.user}, 目标步数 {req.step}")

        # 2. 调用原本的 Runner 类逻辑
        runner = AutoStepRunner(req.user, req.pwd)
        
        # 禁用加密功能保存，因为是 Web 无状态单次调用
        runner.invalid = False 
        
        # 执行提交 (复用 main.py 逻辑)
        exec_msg, success = runner.login_and_post_step(req.step, req.step)
        
        # 3. 提取执行结果
        if success:
            return JSONResponse({"success": True, "message": exec_msg})
        else:
            return JSONResponse({"success": False, "message": exec_msg})
            
    except Exception as e:
        error_msg = traceback.format_exc()
        print(error_msg)
        return JSONResponse({"success": False, "message": f"系统内部错误：{str(e)}"})

if __name__ == "__main__":
    print("================== 网页控制台启动 ==================")
    print("请保证电脑和手机在同一个 Wi-Fi（局域网）下。")
    print("在手机浏览器输入这台电脑的 IP 地址 加 :8080 端口即可访问！")
    print("==========================================================")
    uvicorn.run(app, host="0.0.0.0", port=8080)

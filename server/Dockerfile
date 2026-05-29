# SpeakMate Server
# Railway 部署配置文件

# 运行时
FROM python:3.11-slim

# 安装依赖
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY . .

# 启动
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "$PORT"]

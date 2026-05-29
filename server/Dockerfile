FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY . .

# 直接暴露端口
EXPOSE 3001

# 硬编码启动，不依赖任何环境变量
CMD uvicorn main:app --host 0.0.0.0 --port 3001

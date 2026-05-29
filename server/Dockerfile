FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY . .

EXPOSE 3001

# 用 python 命令（容器里没有 python3）
CMD python -m uvicorn main:app --host 0.0.0.0 --port 3001

# QosQanat ML микросервисі — өндіріске арналған образ.
FROM python:3.12-slim

WORKDIR /app

# Жүйелік тәуелділіктер (torch/scientific stack үшін)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000
ENV PYTHONUNBUFFERED=1

# Денсаулық тексеру
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/health').status==200 else 1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

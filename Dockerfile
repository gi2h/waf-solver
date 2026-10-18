FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

RUN apt-get update && apt-get install -y unzip xvfb && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

EXPOSE 8000
CMD ["sh", "-c", "xvfb-run --server-args='-screen 0, 1920x1080x24' uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]

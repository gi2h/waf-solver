FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

# Xvfb dibutuhkan untuk mode headful, meskipun pyvirtualdisplay akan me-manage-nya
RUN apt-get update && apt-get install -y unzip xvfb && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install browser bawaan patchright
RUN patchright install chromium

COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]

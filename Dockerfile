FROM python:3.10-slim

# 1. Install dependensi OS standar untuk Playwright
RUN apt-get update && apt-get install -y \
    wget gnupg unzip libglib2.0-0 libnss3 libnspr4 libatk1.0-0 \
    libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Install Browser Chromium khusus Playwright beserta dependensinya
RUN playwright install --with-deps chromium

# 4. Ekstrak app.zip
COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

# 5. Jalankan server
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
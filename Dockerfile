FROM python:3.10-slim

# 1. Install dependensi OS dasar, xvfb, dan unzip
RUN apt-get update && apt-get install -y \
    wget gnupg unzip xvfb libglib2.0-0 libnss3 libnspr4 libatk1.0-0 \
    libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy requirements dan install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Instal Chromium khusus untuk Patchright beserta semua dependensi OS-nya
# (Perintah ini memastikan Chrome bisa jalan sempurna di dalam Docker)
RUN patchright install --with-deps chromium

# 4. Ekstrak aplikasi Anda
COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

# 5. Gunakan Port 8080 sesuai settingan Railway
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8080 --workers 1"]

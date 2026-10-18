# 1. Gunakan base image resmi Playwright (Sudah include Python, Chromium, & dependensi OS)
FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

# 2. Set working directory di dalam container
WORKDIR /app

# 3. Copy file requirements dan install dependensi Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy file app.zip, ekstrak isinya, lalu hapus file zip-nya
COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

# 5. Expose port (Railway akan mengabaikan ini dan pakai $PORT, tapi ini untuk dokumentasi)
EXPOSE 8080

# 6. Jalankan Uvicorn menggunakan variabel $PORT dari Railway
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]

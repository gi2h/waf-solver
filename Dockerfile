# 1. Gunakan base image resmi Playwright
FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

# 2. Instal unzip (karena image ini sangat minimalis)
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# 3. Set working directory
WORKDIR /app

# 4. Copy requirements dan install dependensi Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy file app.zip, ekstrak isinya, lalu hapus file zip-nya
COPY app.zip .
RUN unzip app.zip -d /app/ && rm app.zip

# 6. Jalankan server
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]

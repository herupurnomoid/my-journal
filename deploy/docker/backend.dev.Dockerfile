FROM python:3.11-slim

# Mengatur variabel lingkungan untuk performa Python di Docker
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Menetapkan working directory
WORKDIR /app

# Install sistem dependensi yang umum dibutuhkan
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip install poetry==1.7.1

# Menyalin file spesifikasi dependency
COPY pyproject.toml poetry.lock* ./

# Konfigurasi poetry (jangan buat virtual env, karena docker sudah terisolasi)
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

# Karena ini untuk lokal development, kode sumber akan di-mount dari docker-compose
# Command default ini akan menjalankan Uvicorn dengan mode Hot-Reload
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

FROM python:3.11-slim

WORKDIR /app

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Копирование requirements и установка зависимостей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копирование всего кода приложения
COPY . .

# Создание директории для данных пользователей
RUN mkdir -p data/users

# Переменные окружения (можно переопределить в Northflank)
ENV PYTHONUNBUFFERED=1

# Запуск бота
CMD ["python", "main.py"]

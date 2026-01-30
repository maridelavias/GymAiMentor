# Развертывание GymAiMentor на Northflank

## Предварительные требования

1. Аккаунт на [Northflank](https://northflank.com)
2. Репозиторий с кодом на GitHub/GitLab (или другой поддерживаемый VCS)
3. Токены:
   - `TELEGRAM_TOKEN` - токен от Telegram Bot API
   - `GIGACHAT_TOKEN` - токен для GigaChat API

## Шаги развертывания

### 1. Подготовка репозитория

Убедитесь, что в репозитории есть:
- `Dockerfile`
- `requirements.txt`
- `.dockerignore`
- Весь код приложения

### 2. Создание проекта на Northflank

1. Войдите в Northflank Dashboard
2. Создайте новый проект (или используйте существующий)
3. Выберите регион (например, `europe-west`)

### 3. Создание Combined Service

1. В проекте нажмите **"Create new"** → **"Service"**
2. Выберите тип: **"Combined Service"** (build + deployment)
3. Настройте:

#### Basic Information
- **Name**: `gym-ai-mentor` (или любое другое имя)

#### Repository
- **Project Type**: GitHub/GitLab (в зависимости от вашего репозитория)
- **Project URL**: URL вашего репозитория
- **Branch**: `main` или `master`

#### Build Settings
- **Build Type**: `Dockerfile`
- **Dockerfile Path**: `/Dockerfile` (если в корне)
- **Build Context**: `/` (корень репозитория)

#### Deployment Settings
- **Instances**: `1` (можно увеличить для масштабирования)
- **Deployment Plan**: `nf-compute-10` (минимальный план, можно выбрать больше)
- **Storage**:
  - **Ephemeral Storage**: `2048` MB (минимум для хранения данных пользователей)
  - **Shared Memory (shmSize)**: `64` MB

#### Environment Variables
Добавьте следующие переменные окружения в секции **Runtime Environment**:

```
TELEGRAM_TOKEN=your_telegram_bot_token
GIGACHAT_TOKEN=your_gigachat_token
GIGACHAT_MODEL=GigaChat-2-Max
GIGACHAT_TEMPERATURE=0.35
GIGACHAT_MAX_TOKENS=5000
GIGACHAT_TIMEOUT=90
GIGACHAT_RETRIES=3
```

**Важно**: Используйте **Secrets** в Northflank для хранения токенов:
1. Перейдите в **Secrets** в вашем проекте
2. Создайте секреты для `TELEGRAM_TOKEN` и `GIGACHAT_TOKEN`
3. В настройках сервиса используйте ссылки на эти секреты

#### Ports
Для телеграм-бота порты не нужны (используется polling), но можно оставить пустым или удалить секцию.

### 4. Настройка Persistent Storage (РЕКОМЕНДУЕТСЯ)

Для сохранения данных пользователей между перезапусками:

1. В настройках сервиса перейдите в **Storage** → **Volumes**
2. Нажмите **"Add Volume"**
3. Настройте:
   - **Name**: `user-data`
   - **Size**: минимум `1024` MB (можно больше, но уменьшить потом нельзя)
   - **Container Mount Path**: `/app/data` (абсолютный путь)
   - **Volume Mount Path**: оставьте пустым (или укажите `users` для подпапки)

**Важно**: 
- После добавления volume сервис будет ограничен **1 инстансом** (для бота это нормально)
- Данные будут сохраняться между перезапусками контейнера
- Рекомендуется настроить автоматические бэкапы в разделе **Backups**

### 5. Health Checks (опционально)

Так как бот использует polling, health checks не критичны, но можно добавить простую проверку:

- **Type**: `Command`
- **Command**: `python -c "import sys; sys.exit(0)"`
- **Interval**: `60` секунд

### 6. Запуск сервиса

1. Сохраните все настройки
2. Нажмите **"Create Service"**
3. Northflank автоматически:
   - Соберет Docker образ
   - Развернет сервис
   - Запустит бота

### 7. Мониторинг

После развертывания:
- Проверьте логи в разделе **Logs**
- Убедитесь, что бот запустился (должно быть сообщение "Бот запущен (polling).")
- Протестируйте бота в Telegram

## Обновление бота

При каждом push в репозиторий:
1. Northflank автоматически обнаружит изменения
2. Пересоберет образ
3. Развернет новую версию (в зависимости от настроек автоматического деплоя)

Или можно вручную:
1. Перейти в сервис
2. Нажать **"Redeploy"** или **"Rebuild"**

## Troubleshooting

### Бот не запускается
- Проверьте логи в разделе **Logs**
- Убедитесь, что все переменные окружения установлены
- Проверьте, что токены валидны

### Данные пользователей теряются
- Убедитесь, что настроен Volume для `/app/data`
- Проверьте права доступа к директории

### Ошибки при сборке
- Проверьте, что Dockerfile корректен
- Убедитесь, что все зависимости в `requirements.txt`

## Дополнительные настройки

### Автомасштабирование
Если ожидается высокая нагрузка, можно включить:
- **Horizontal Autoscaling**: включить
- **Min Replicas**: `1`
- **Max Replicas**: `3` (или больше)
- **CPU Threshold**: `70%`

### Резервное копирование
Настройте регулярные бэкапы Volume с данными пользователей через Northflank Backups.

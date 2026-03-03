# OZON Oskemen Mini App

Telegram-бот и Mini App для vape shop в стиле маркетплейса.

Стек:
- `Python`
- `FastAPI`
- `aiogram`
- `SQLite`

## Что реализовано

- Только Mini App сценарий (`/start` -> кнопка открытия магазина).
- Витрина товаров: карточки, подробная страница, избранное, корзина.
- Оформление заказа: контакт, адрес, доставка, оплата наличными.
- Отправка заказа в Telegram-группу.
- Профиль: история заказов, язык (базово), поддержка.
- Админка внутри Mini App:
  - добавление/редактирование/отключение товаров;
  - настройка параметров доставки и контакта поддержки.
  - просмотр всех заказов и смена статусов (`new`, `confirmed`, `delivering`, `done`, `cancelled`).

## Быстрый старт

1. Создайте и активируйте виртуальное окружение:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

2. Установите зависимости:

```powershell
pip install -r requirements.txt
```

3. Создайте `.env` на основе примера:

```powershell
Copy-Item .env.example .env
```

4. Заполните минимум:
- `BOT_TOKEN`
- `ADMIN_USER_IDS` (ваш Telegram user id через запятую)
- `ORDERS_GROUP_ID` (id группы для заказов)
- `WEBAPP_URL` (для Telegram нужен `https`; для локальной проверки можно оставить `http://127.0.0.1:8000`)

5. Запуск:

```powershell
python main.py
```

После запуска:
- API и Mini App: `http://127.0.0.1:8000`
- health-check: `http://127.0.0.1:8000/health`

## Запуск через .bat

- Локально:
  - Запустите `zapusk_local.bat`

- Через Cloudflare (для открытия Mini App прямо в Telegram):
  - Запустите `zapusk_cloudflare.bat`
  - Скрипт сам:
    - поднимет tunnel `https://...trycloudflare.com`;
    - обновит `WEBAPP_URL` в `.env`;
    - запустит бота.

## Настройка Telegram

1. У бота должен быть `Menu Button` с Web App URL (код делает это автоматически при старте).
2. Откройте диалог с ботом и нажмите `/start`.
3. Нажмите кнопку `Открыть каталог`.

## Важно для продакшена

- `WEBAPP_URL` должен быть `https://...`
- Выключите `DEV_MODE` (`false`).
- Для стабильной работы используйте VPS/Render/Railway/Fly.io.

## Простой деплой на Render

1. Создайте новый `Web Service` из этой папки (через GitHub или ZIP).
2. Build command:

```bash
pip install -r requirements.txt
```

3. Start command:

```bash
python main.py
```

4. В Environment Variables задайте:
- `BOT_TOKEN`
- `WEBAPP_URL` = ваш URL Render сервиса (`https://...onrender.com`)
- `ORDERS_GROUP_ID`
- `ADMIN_USER_IDS`
- `DEV_MODE=false`

5. После деплоя откройте бота, отправьте `/start`, нажмите `Открыть OZON Oskemen`.

## Аватар бота

Аватар Telegram-бота меняется через `@BotFather` (`/setuserpic`).  
В самом Mini App логотип берется из `MINI_APP_LOGO_URL`.

## Где править дизайн

- `static/styles.css`
- `static/app.js`
- `static/index.html`

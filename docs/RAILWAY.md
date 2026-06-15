# Railway — деплой и авто-деплой (один сервис: web + API + DB)

> Цель: **один push в GitHub → авто-деплой всей платформы** на Railway.
> Один контейнер (корневой `Dockerfile`) собирает Flutter web и отдаёт его из
> FastAPI, поэтому один URL обслуживает UI + API + ТВ-табло (один origin, CORS
> не нужен). База — управляемый Postgres Railway. GitHub Secrets / Actions **не
> нужны** — авто-деплой делает сам Railway через свой GitHub App.

## Архитектура

```
GitHub (форк)  ──push──▶  Railway service "kozshifo"
                            ├─ build: корневой Dockerfile (multi-stage)
                            │    stage 1: flutter build web --release
                            │    stage 2: FastAPI + alembic upgrade head + uvicorn
                            │    (web из stage 1 копируется в /build/web,
                            │     FastAPI авто-монтирует его на "/")
                            └─ Postgres (плагин Railway) ──DATABASE_URL──┐
                                                                          ▼
                                                  app.core.config нормализует
                                                  postgresql:// → postgresql+psycopg://
```

Публичный URL вида `https://kozshifo-production.up.railway.app` (или свой домен).
ТВ-табло: `<URL>/tv/<branch_id>`. Swagger: `<URL>/docs`.

## Файлы, которые это включают (уже в репозитории)

| Файл | Роль |
|---|---|
| `Dockerfile` (корень) | multi-stage: Flutter web + FastAPI в одном образе. Цель Railway. |
| `.dockerignore` | держит контекст сборки чистым (не тянет build/, .venv, .env…). |
| `railway.json` | builder=DOCKERFILE, healthcheck `/health`, restart on-failure. |
| `backend/app/core/config.py` | валидатор `_pin_psycopg_driver`: бэрный `postgresql://` → `postgresql+psycopg://` (Railway отдаёт бэрную схему, мы возим psycopg v3). |
| корневой `Dockerfile` CMD | слушает `$PORT` (Railway инжектит), дефолт 8000 для прочих хостов. |

> Локальная разработка по-прежнему через `backend/Dockerfile` + `docker-compose.yml`
> (это НЕ трогалось). Корневой `Dockerfile` — только для облака/одного сервиса.

## Разовая настройка (через дашборд Railway, ~10 минут)

1. **Форк** `farruhsho/kozshifo` → свой GitHub (кнопка *Fork*). Запушить туда
   ветку с этими файлами (см. ниже «Как залить изменения в форк»).
2. На **railway.app** → *New Project* → *Deploy from GitHub repo* → выбрать
   свой форк `kozshifo`. Railway установит свой GitHub App на твой аккаунт
   (для своего форка прав достаточно — владелец оригинала не нужен).
3. **Postgres**: в проекте → *New* → *Database* → *Add PostgreSQL*. Railway
   создаст переменную `DATABASE_URL` (и `PG*`). Привязать её к сервису API:
   проще всего в сервисе → *Variables* → добавить
   `DATABASE_URL = ${{Postgres.DATABASE_URL}}` (reference на плагин).
4. Сервис API → **Settings**:
   - *Source* → Root Directory: **оставить пустым** (Dockerfile в корне).
   - Build уже определится из `railway.json` (Dockerfile).
   - *Networking* → *Generate Domain* (получишь публичный URL).
5. Сервис API → **Variables** — задать обязательное (production-гарды упадут без них):
   ```
   ENVIRONMENT=production
   SECRET_KEY=<python -c "import secrets;print(secrets.token_urlsafe(48))">
   SEED_DIRECTOR_PASSWORD=<сильный пароль владельца, НЕ дефолт из репо>
   UPLOAD_DIR=/app/data/uploads
   TZ=Asia/Tashkent
   DATABASE_URL=${{Postgres.DATABASE_URL}}
   ```
   Опционально: `SEED_DIRECTOR_EMAIL`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.
   `CORS_ORIGINS` НЕ нужен (web с того же origin). `PORT` задаёт сам Railway.
6. *Deploy*. Первая сборка дольше (тянет Flutter SDK и собирает web) — это норма.
   Контейнер на старте сам прогонит `alembic upgrade head` и засидит директора.

## Авто-деплой

После шага 2 авто-деплой **уже включён**: каждый push в подключённую ветку
форка (по умолчанию `main`) запускает новую сборку и выкатку. Ничего больше
настраивать не надо — ни GitHub Actions, ни секретов в GitHub.

## Как залить изменения в форк (git)

```powershell
# 1. Форкнуть на GitHub (web). Затем клонировать СВОЙ форк в чистую папку:
git clone https://github.com/<твой-логин>/kozshifo.git
cd kozshifo
# 2. Скопировать сюда новые/изменённые файлы из рабочей папки:
#    Dockerfile, .dockerignore, railway.json, backend/app/core/config.py
# 3. Закоммитить и запушить:
git add Dockerfile .dockerignore railway.json backend/app/core/config.py
git commit -m "deploy: single-image Railway target (web+API), pin psycopg DSN"
git push origin main
```

## Проверка после деплоя

```
GET <URL>/health        → {"status":"ok", ... "env":"production"}
<URL>/                  → Flutter UI (логин director@kozshifo.uz / SEED_DIRECTOR_PASSWORD)
<URL>/docs              → Swagger
<URL>/tv/<branch_id>    → ТВ-табло
```

## Известные ограничения / заметки

- **Загруженные файлы (B-сканы) эфемерны.** Файловая система контейнера Railway
  не переживает редеплой. Для постоянного хранения подключить **Railway Volume**
  на `/app/data` (Service → Settings → Volumes, mount path `/app/data`) и оставить
  `UPLOAD_DIR=/app/data/uploads`. Иначе — как и на Cloud Run — файлы теряются при
  рестарте (БД в Postgres не теряется).
- **Версия Flutter.** Образ `ghcr.io/cirruslabs/flutter:stable` плавающий. Если
  сборка web однажды сломается из-за версии Dart, запинить тег под `.metadata`
  (revision `3b62efc2a3da49882f43c372e0bc53daef7295a6`, SDK `^3.10.7`).
- **Синхронизация форка.** Если разработка идёт в `farruhsho/kozshifo`, периодически
  подтягивать upstream в форк (`git remote add upstream …; git fetch upstream;
  git merge upstream/main; git push`), иначе авто-деплой выкатывает старый код.
- **Стоимость.** Railway free/hobby с триалом; Postgres + always-on сервис могут
  выйти за бесплатный лимит — проверить тариф под нагрузку клиники.
```

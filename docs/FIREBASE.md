# Firebase — ОТЛОЖЕННАЯ интеграция (handoff для будущего агента)

> Статус на 2026-06-13: **НЕ подключено и подключать рано.** Сервер для связки
> ещё не прибыл. Когда владелец скажет «сервер пришёл — настраивай», этот файл
> — твоя инструкция. До того момента НЕ добавляй firebase-пакеты в pubspec.

## Что к чему

- **Firebase-проект уже создан владельцем:** `kozshifo-32e6f`.
- **Зачем он нужен этой платформе** (по ультра-промтам владельца, см. память/доки):
  1. **Push-уведомления (FCM)** врачам/директору — модуль Notifications уже
     имеет серверный шов: `backend/app/core/notify.py` (каналы `log` и
     `telegram`; push станет третьим провайдером по тому же паттерну —
     строка `Notification(channel="push", status="queued")` + доставка в
     daemon-потоке, токен/ключи только через env, см. как сделан Telegram).
  2. Возможные следующие шаги: хостинг web-сборки (`build/web`), Crashlytics,
     Analytics — решает владелец, не предполагай.

## Как подключать (когда придёт сервер)

```bash
# 1. Инструменты (один раз на машине):
npm install -g firebase-tools        # или standalone Firebase CLI
firebase login
dart pub global activate flutterfire_cli

# 2. Связка Flutter-приложения с проектом (из корня репозитория):
flutterfire configure --project=kozshifo-32e6f
#    → сгенерирует lib/firebase_options.dart + платформенные конфиги.
#    Выбирай платформы: web (основная), android/windows по необходимости.

# 3. Зависимости (ТОЛЬКО после проверки гейта из AGENTS.md §6!):
flutter pub add firebase_core firebase_messaging
dart run build_runner build --delete-conflicting-outputs   # ДОЛЖЕН остаться зелёным
```

## Критические гейты (не нарушай)

1. **AGENTS.md §6:** пакеты с dart native build hooks ломают `build_runner`
   на Dart 3.10 (история с `flutter_secure_storage`/`objective_c`).
   После `flutter pub add firebase_*` СРАЗУ прогони `dart run build_runner
   build` и `flutter analyze` — если codegen упал, откатывай и ищи версии без
   hook'ов. Это блокер №1 всей интеграции.
2. `lib/firebase_options.dart` — генерируемый файл, коммитится (это публичные
   client-ключи), но **серверные ключи FCM (service account JSON) — только
   через env/секреты**, по образцу `TELEGRAM_BOT_TOKEN` в
   `backend/app/core/config.py` (+ прод-гард в `_production_guards`, как для
   SECRET_KEY).
3. Backend-отправка push: библиотека `firebase-admin` в
   `backend/requirements.txt`; токены устройств — новая колонка/таблица
   (например `user_device_tokens`) + alembic-ревизия (помни server_default
   для NOT NULL на непустых таблицах и именованные FK в batch-режиме —
   грабли уже задокументированы в истории коммитов).
4. Все 4 гейта (§ DoD в AGENTS.md) должны остаться зелёными; уведомления
   никогда не ломают бизнес-запрос (контракт notify.py).

## Куда вписать push-канал (карта кода)

| Точка | Файл |
|---|---|
| Шов провайдеров уведомлений | `backend/app/core/notify.py` (`notify()`, `_deliver_telegram` — копируй паттерн) |
| Настройки/env | `backend/app/core/config.py` (+ `backend/.env.example`, `docker-compose.yml`) |
| События, которые уже шлются | low_stock (`core/notify.check_low_stock`), критичные инсайты (`features/dashboard._notify_critical_insights`) |
| Журнал уведомлений | `GET /notifications` (модель `app/models/notification.py`) |
| Flutter-приём (FCM) | после `flutterfire configure`: init в `lib/main.dart`, токен регистрировать через новый endpoint |

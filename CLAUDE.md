> ⚡ **AGENTS & DEVELOPERS — READ `AGENTS.md` FIRST**, then `PLATFORM.md`
> (current status & roadmap) and `README.md` (how to run).
>
> This file is the **aspirational product brief** — the *target* vision of the
> whole platform. It describes what we are building toward, **not** what is
> already built. For what actually exists / is in progress, see the status
> matrix in **`PLATFORM.md`** and the handoff in **`AGENTS.md`**.
> Не предполагай, что модуль готов, только потому что он упомянут здесь.

---

# KO'Z SHIFO MEDICAL ERP PLATFORM

Ты являешься автономной командой разработки уровня Enterprise.

Твои роли:

* CTO
* Chief Software Architect
* Principal Engineer
* Product Owner
* Business Analyst
* Senior UX Architect
* Lead QA Engineer
* Database Architect
* ERP Architect
* HIS Architect
* Inventory Architect
* Financial Systems Architect

---

# PROJECT MISSION

Создать полноценную медицинскую ERP платформу для глазной клиники.
Не просто приложение. Не просто CRM. Полноценную систему управления клиникой.

---

# AUTONOMOUS MODE

Не задавать лишние вопросы. Если решение очевидно — принимать его самостоятельно,
использовать лучшие современные практики и проектировать систему так, как если бы
она обслуживала: 100000 пациентов, 500 сотрудников, 10 филиалов, миллионы записей.

---

# CORE BUSINESS FLOW — Patient Journey

Главный объект системы — путь пациента:

Регистратура регистрирует пациента → создаётся Patient → создаётся Visit →
выбираются услуги → принимается оплата → печатается чек → создаётся талон очереди →
очередь отображается на телевизоре → пациент проходит диагностику → медицинское
оборудование автоматически отправляет результаты → результаты прикрепляются к визиту →
врач открывает карточку, видит результаты, назначает лечение ИЛИ операцию →
назначения отправляются на ресепшен → пациент оплачивает доп. услуги → создаются
задачи лечения / операция → автоматически списываются расходники → обновляются
финансы и аналитика → визит закрывается.

---

# MODULES

Identity & Access · Patients · Reception · Queue · TV Queue · Diagnostics ·
Medical Devices · Doctors · Treatment · Operations · Inventory · Warehouse ·
Purchasing · Suppliers · Finance · Payroll · CRM · Reports · Analytics ·
Notifications · Audit · Settings · Director Dashboard

---

# INVENTORY

Склад поддерживает: категории, подкатегории, товары, лекарства, расходники,
материалы, инструменты, поставщиков, партии, срок годности, штрихкод/QR,
минимальный остаток, автоматическое списание, инвентаризацию, закупки, возвраты,
перемещения.

---

# MEDICAL DEVICES

Поддержка интеграций: REST API, TCP/IP, USB, Serial Port, SDK, CSV, XML, JSON,
HL7, DICOM. Для каждого устройства хранить: название, модель, производитель,
серийный номер, тип подключения, настройки, логи, результаты, файлы.

---

# DIRECTOR CONTROL CENTER

Директор — владелец системы. Управляет: филиалами, сотрудниками, ролями, правами,
услугами, ценами, операциями, расходами, складами, кабинетами, документами,
шаблонами, настройками, интеграциями.

# DIRECTOR KPI

Доход (день/месяц/год), расход, прибыль, средний чек, новые/повторные пациенты,
количество и доход от операций, конверсии (консультация→операция,
диагностика→операция, операция→лечение), выручка по врачам/услугам/филиалам,
нагрузка врачей/кабинетов, остатки склада, себестоимость и маржинальность
операций, ROI рекламы, LTV пациента, Cash Flow, финансовый прогноз, прогноз
операций/закупок/загрузки.

---

# PERMISSION SYSTEM

Users · Roles · Permissions · RolePermissions · UserPermissions ·
FeaturePermissions · BranchPermissions. Все права динамические. **Никаких
hardcoded ролей.**

# AUDIT SYSTEM

Логировать абсолютно все действия: создание, редактирование, удаление, оплата,
возврат, скидка, диагноз, операция, настройки, права, вход, выход, импорт, экспорт.

---

# DEVELOPMENT RULES

**Frontend:** Flutter · Riverpod · GoRouter · Freezed · Dio
**Backend:** FastAPI · PostgreSQL · Docker
**Архитектура:** Feature First · Clean Architecture · Repository Pattern ·
Dependency Injection

---

# CHANGE IMPACT ENGINE

При изменении таблицы / API / экрана / бизнес-процесса / роли / права / отчёта /
настройки — автоматически проверять влияние на: Database, API, UI, Analytics,
Reports, Permissions, Audit, Notifications, PDF, Queue, TV Queue, Inventory,
Finance.

# TASK ENGINE

Любую задачу разбивать: Epic → Feature → SubFeature → MicroTask → Testing →
Documentation → Deployment, с Definition Of Done и Acceptance Criteria.

# RESPONSE FORMAT

Всегда выдавать: Analysis · Architecture · Database · API · UI/UX · Tasks ·
Risks · Testing · Deployment.

---

# FINAL GOAL

Создать медицинскую платформу уровня **ERP + CRM + HIS + Inventory + Finance**,
готовую к использованию в реальной клинике без перепроектирования архитектуры.

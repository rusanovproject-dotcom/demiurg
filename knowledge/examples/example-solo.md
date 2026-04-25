# Пример: Solo-офис — Артём, фрилансер-разработчик

## Сценарий
Артём — фрилансер. Делает бот доставки еды (Python/aiogram), лендинг (Next.js), ведёт Telegram-канал про разработку. Работает один. Нужен один агент = Director, который закрывает всё.

---

## Дерево папок

```
artem-office/
├── CLAUDE.md              # Director = единственный агент
├── context.md             # текущий фокус
├── knowledge/
│   ├── INDEX.md
│   ├── tone-of-voice.md
│   └── tech-stack.md
└── docs/                  # заметки, решения
```

## CLAUDE.md

```markdown
# AI Office — Артём (Solo)

Ты — AI-ассистент Артёма. Единственный агент: и стратег, и кодер, и контентщик.

## Проекты

| Проект | Стек | Где живёт |
|--------|------|-----------|
| food-bot/ | Python 3.11, aiogram 3, PostgreSQL, Docker | VPS 194.58.xx.xx |
| landing/ | Next.js 14, Tailwind, Vercel | Vercel auto-deploy |
| tg-channel/ | Контент, посты | @artem_dev_log |

## Правила
1. Код — чистый, типизированный, с docstrings
2. Коммиты — conventional commits (feat/fix/docs)
3. Не трогай .env, docker-compose.prod.yml
4. Перед деплоем — `pytest` для food-bot, `npm run build` для landing
5. Посты в канал — разговорный стиль, без корпоратива (см. knowledge/tone-of-voice.md)
6. Если задача > 1 часа — спроси план, не делай молча

## Контекст
Читай context.md перед каждой сессией.

## Стек (подробно)
См. knowledge/tech-stack.md

## НЕ делает
- Не деплоит без подтверждения Артёма
- Не меняет схему БД без обсуждения
- Не пишет посты длиннее 1500 символов
- Не использует сторонние API без согласования
```

## context.md

```markdown
# Контекст — март 2026

## Фокус
- food-bot: MVP запущен, пилим оплату (ЮKassa)
- landing: редизайн главной, добавить отзывы
- канал: 2 поста/неделю, серия "как я делал бота"

## Важно сейчас
- Дедлайн оплаты: 28 марта
- Landing отзывы: макет в Figma готов
- Канал: черновик поста #12 в docs/drafts/

## Решения
- БД: PostgreSQL (не SQLite) — масштабируемость
- Деплой: Docker на VPS, не serverless — контроль
```

## knowledge/INDEX.md

```markdown
# Knowledge Base

| Файл | Что внутри |
|------|-----------|
| tone-of-voice.md | Стиль постов в канал |
| tech-stack.md | Стек, версии, почему выбрано |
```

## knowledge/tone-of-voice.md

```markdown
# Tone of Voice — @artem_dev_log

## Стиль
- Разговорный, как рассказываешь другу
- Первое лицо, "я сделал", "я попробовал"
- Короткие абзацы (2-3 предложения)
- Один пост = одна мысль

## Антислова
баннить: "данный", "является", "осуществлять", "в рамках", "комплексный"

## Формат поста
- Заголовок-крючок (вопрос или провокация)
- Тело: 800-1200 символов
- Финал: вывод или вопрос читателям
```

## knowledge/tech-stack.md

```markdown
# Tech Stack

## food-bot
- Python 3.11, aiogram 3.3
- PostgreSQL 16 + asyncpg
- Redis — кеш меню, сессии FSM
- Docker Compose (dev + prod)
- Pytest + pytest-asyncio

## landing
- Next.js 14 (App Router)
- Tailwind CSS 3.4
- Vercel (auto-deploy из main)

## Инфра
- VPS: Ubuntu 22.04, 2 vCPU, 4GB RAM
- CI: GitHub Actions (lint + test)
- Домен: artem-food.ru (Cloudflare DNS)
```

---

## DRY-RUN: 3 теста

### Тест 1: «Допили оплату в боте»
```
→ Читаю context.md... фокус = оплата ЮKassa, дедлайн 28 марта
→ Читаю tech-stack.md... Python 3.11, aiogram 3, asyncpg
→ Открываю food-bot/, ищу handlers/payment.py
→ Пишу код интеграции ЮKassa, добавляю тесты
→ pytest ✅ → коммит: "feat(payment): add YooKassa integration"
✅ Результат: рабочий код + тесты, ждёт деплоя от Артёма
```

### Тест 2: «Напиши пост про выбор БД»
```
→ Читаю tone-of-voice.md... разговорный, первое лицо, 800-1200 символов
→ Читаю tech-stack.md... PostgreSQL, выбор осознанный
→ Пишу пост: "Почему я выбрал PostgreSQL, а не SQLite для бота"
→ Проверяю антислова — чисто
→ 950 символов ✅
✅ Результат: готовый пост, сохранён в docs/drafts/
```

### Тест 3: «Обнови лендинг — добавь блок отзывов»
```
→ Читаю context.md... макет в Figma готов
→ Читаю tech-stack.md... Next.js 14, Tailwind
→ Создаю components/Testimonials.tsx
→ npm run build ✅
✅ Результат: компонент готов, Vercel задеплоит при пуше
```

---

## Метрики

| Метрика | Значение |
|---------|----------|
| Файлов в офисе | 6 |
| Строк CLAUDE.md | 42 |
| Агентов | 1 (Director = всё) |
| Knowledge-файлов | 2 |
| Время развёртки | ~5 мин |
| Покрытие задач | код, контент, инфра |

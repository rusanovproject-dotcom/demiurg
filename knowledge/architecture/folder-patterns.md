# Паттерны структуры папок

Три эталонных паттерна в зависимости от масштаба проекта.
Demiurg выбирает один и адаптирует под конкретный случай.

---

## Паттерн 1: SOLO (1 человек, 1-3 проекта)

Минимальная структура. Один Director, без отдельных агентов.

```
workspace/
├── CLAUDE.md           ← единственный агент (Director + исполнитель)
├── context.md          ← приоритеты, что в работе (≤30 строк)
├── projects/
│   ├── project-a/
│   │   ├── CLAUDE.md   ← контекст проекта (стек, деплой, правила)
│   │   └── src/
│   └── project-b/
│       ├── CLAUDE.md
│       └── src/
├── knowledge/
│   ├── INDEX.md        ← навигация по всем файлам знаний
│   ├── notes/          ← заметки, идеи, исследования
│   └── references/     ← внешние материалы, ссылки
└── ops/
    ├── log.md          ← что сделано (append-only)
    └── decisions/      ← почему приняли решение X
```

Правила:
- CLAUDE.md в корне — единая точка входа
- context.md обновляется после каждой сессии
- knowledge/INDEX.md — обязателен, это карта для агента

---

## Паттерн 2: SMALL TEAM (1-2 человека, 3-7 проектов, 2-4 агента)

Появляется разделение ролей. Director отдельно, 2-3 специалиста.

```
workspace/
├── CLAUDE.md           ← Director (роутинг, координация)
├── AGENTS.md           ← карта агентов (кто, где, что делает)
├── context.md          ← snapshot текущего состояния (≤50 строк)
├── projects/
│   ├── project-a/
│   │   ├── CLAUDE.md   ← агент проекта (CTO-профиль)
│   │   └── ...
│   ├── project-b/
│   │   ├── CLAUDE.md
│   │   └── ...
│   └── project-c/
├── knowledge/
│   ├── INDEX.md
│   ├── brand/          ← бренд, позиционирование, tone of voice
│   ├── audience/       ← ЦА, исследования, CustDev
│   ├── methodology/    ← продукт, методология, программы
│   └── intel/          ← конкуренты, тренды, аналитика
├── agents/             ← CLAUDE.md файлы специалистов
│   ├── cto.md          ← код, инфраструктура
│   └── cmo.md          ← контент, маркетинг
├── ops/
│   ├── log.md
│   ├── decisions/
│   └── daily-logs/     ← ежедневные отчёты
└── skills/
    └── demiurg/      ← этот скилл
```

Правила:
- Агенты в agents/ — это роли, не дубли Director
- Каждый агент видит ТОЛЬКО свои файлы (прописано в его CLAUDE.md)
- knowledge/INDEX.md — единственная точка входа в знания
- context.md — пишет Director, читают все

---

## Паттерн 3: FULL OFFICE (команда, 5+ проектов, 5+ агентов)

Полная структура с отделами, памятью, и автоматизациями.

```
workspace/
├── CLAUDE.md             ← Director (только роутинг, ≤100 строк)
├── AGENTS.md             ← полная карта + граф зависимостей
├── context.md            ← TOP-5 приоритетов (≤50 строк)
├── projects/
│   ├── my-app/
│   │   ├── CLAUDE.md     ← CTO-профиль для этого проекта
│   │   └── ...
│   ├── my-assistant/
│   ├── my-booking/
│   ├── content-engine/
│   └── ...
├── knowledge/
│   ├── INDEX.md          ← мастер-индекс со всеми файлами
│   ├── brand/
│   │   ├── INDEX.md      ← индекс раздела
│   │   ├── positioning.md
│   │   └── tone-of-voice.md
│   ├── audience/
│   │   ├── INDEX.md
│   │   ├── avatar.md
│   │   └── research/
│   ├── methodology/
│   │   ├── INDEX.md
│   │   └── ...
│   ├── intel/
│   │   ├── INDEX.md
│   │   └── ...
│   └── processes/        ← описания бизнес-процессов
├── agents/
│   ├── cto.md
│   ├── cmo.md
│   ├── program.md
│   ├── community.md
│   ├── operations.md
│   ├── intelligence.md
│   └── coach.md
├── ops/
│   ├── log.md            ← append-only лог операций
│   ├── decisions/        ← по файлу на решение
│   ├── daily-logs/       ← YYYY-MM-DD.md
│   └── memory/
│       ├── episodic.md   ← что произошло (факты)
│       ├── semantic.md   ← что выучили (знания)
│       └── procedural.md ← как делать (процедуры)
├── skills/
│   ├── demiurg/
│   └── ...               ← другие скиллы
└── archive/              ← устаревшие файлы (не удалять, архивировать)
```

Правила:
- Director НИКОГДА не читает код проектов напрямую
- Каждый раздел knowledge/ имеет свой INDEX.md
- ops/memory/ — три типа памяти, обновляются после каждой сессии
- archive/ — сюда перемещаются устаревшие файлы (лучше архив чем удаление)
- Максимум вложенности: 3 уровня (workspace/category/topic/file.md)

---

## Паттерн 4: HIERARCHICAL OFFICE (10+ агентов, двухуровневый роутинг)

Когда агентов больше 10 — плоский AGENTS.md становится слишком большим для
контекста Director'а. Решение: двухуровневая иерархия.

```
workspace/
├── CLAUDE.md             ← Director (роутит только между Heads)
├── AGENTS.md             ← только 7 Heads (не все 20+ агентов)
├── context.md
├── departments/
│   ├── product/
│   │   ├── CLAUDE.md     ← Head of Product (роутит между CTO, Designer, Tech Lead)
│   │   ├── AGENTS.md     ← только 3-4 специалиста отдела
│   │   └── agents/
│   │       ├── cto.md
│   │       ├── designer.md
│   │       └── tech-lead.md
│   ├── content/
│   │   ├── CLAUDE.md     ← Head of Content
│   │   ├── AGENTS.md
│   │   └── agents/
│   │       ├── copywriter.md
│   │       ├── marketer.md
│   │       └── designer.md
│   └── operations/
│       ├── CLAUDE.md     ← Head of Operations
│       ├── AGENTS.md
│       └── agents/
│           ├── agent-architect.md
│           └── quality-reviewer.md
├── knowledge/            ← общая база знаний (все отделы)
├── ops/
└── projects/
```

Правила:
- Director видит только Heads (7 записей, не 20+)
- Каждый Head видит только свой отдел (3-4 специалиста)
- knowledge/ общий — все отделы ссылаются на одну базу
- Двухшаговый роутинг: Director → Head → Specialist
- Warning: при >10 агентов предложи этот паттерн

---

## Общие правила для всех паттернов

1. **Имена файлов** — английский, kebab-case: `tone-of-voice.md`, не `тон_голоса.md`
2. **Контент** — на языке пользователя (обычно русский)
3. **CLAUDE.md** — всегда в корне каждой значимой папки
4. **INDEX.md** — в каждой knowledge-папке с >3 файлами
5. **context.md** — один на весь workspace, обновляется часто
6. **Нет файлов в корне** кроме CLAUDE.md, AGENTS.md, context.md
7. **Максимум 7±2 папок** на одном уровне (правило Миллера)

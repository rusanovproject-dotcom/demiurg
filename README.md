# Demiurg — архитектор AI-систем

Демиург собирает AI-агентов и AI-офисы как **системы вокруг знаний**, а не клоны шаблонов. Один скилл, два режима, восемь фаз, своя память.

```
INTAKE → BRIEF → SCOUT → KNOWLEDGE → BUILD → VALIDATE → ITERATE → WIRE
```

---

## Что внутри

```
demiurg/
├── CLAUDE.md             # точка входа, self-trigger rules, характер
├── AGENTS.md             # реестр субагентов и конвейер
├── MEMORY.md             # шаблон памяти между сессиями
├── agents/               # 9 субагентов (Knowledge Miner, Builder, Validator, Refiner...)
├── skills/
│   ├── build/            # единый скилл сборки (SINGLE / TEAM)
│   └── audit-project/    # универсальный аудит существующего офиса
├── knowledge/
│   ├── architecture/     # 18+ файлов: blueprint, memory, routing, handoff, director-cookbook...
│   ├── tactics/          # guardrails, validation, context-economy, debug-playbook
│   ├── examples/         # few-shot: copywriter / tech-lead / wizard / solo / team / offer-architect
│   ├── templates/        # office-tour, quick-start, user-guide, office-passport
│   ├── skill-mastery/    # anatomy / writing-guide / advanced-patterns / evaluation
│   ├── evolving/         # learnings / failures / discoveries / audit-lessons (твоя память)
│   ├── offer-principles.md
│   └── cheat-sheet.md
└── scripts/
    ├── validate-agent.sh   # бесплатная проверка одного агента (без LLM)
    ├── validate.sh         # health-check директории (6 проверок)
    ├── validate-office.sh  # проверка офиса целиком
    └── wire-check.sh       # финальная проверка перед "готов"
```

---

## Установка

### Вариант 1 — Демиург как отдельный проект (рекомендую)

```bash
git clone <url> demiurg
cd demiurg
claude
```

В сессии Claude Code пиши: `создай агента-копирайтера` или `собери AI-офис для коуча`.

### Вариант 2 — Демиург внутри своего workspace

```bash
cd ~/workspace
git clone <url> demiurg
```

Из любого места в workspace зови Демиурга:
```
cd demiurg && claude
```

---

## Как пользоваться

### Один агент или скилл — режим SINGLE (10-30 мин)

Триггеры: `создай агента`, `один скилл`, `добавь агента`.

```
INTAKE (5-6 вопросов одним сообщением)
  ↓
BRIEF (роль, задачи, связи)
  ↓
SCOUT (мировой топ по домену → knowledge/scout/)
  ↓
KNOWLEDGE MINING (что есть в твоём workspace, score 0-10)
  ↓
BUILD (Builder создаёт CLAUDE.md + skills/)
  ↓
VALIDATE (validate-agent.sh + Validator-субагент, score 0-100)
  ↓
ITERATE (если score 60-79 — Refiner, макс 2 раунда)
  ↓
WIRE (обновить AGENTS.md, прописать handoff)
```

### Целая команда — режим TEAM (45-90 мин)

Триггеры: `собери команду`, `wizard`, `офис с нуля`.

Wizard ведёт через intake → blueprint → состав команды → для каждого агента: knowledge → build → validate → iterate → финальный wire + soul + onboarding.

---

## Принципы

1. **Агент строится ВОКРУГ знаний.** Без data-pack — пустышка с правильной структурой.
2. **Few-shot побеждает abstract guidelines.** В `knowledge/examples/` — реальные образцы, Builder их читает.
3. **Score < 5 = блокер.** Программный, в `_score.json`. Текстовый блокер модель игнорирует.
4. **Self-trigger rules — хардкоды.** Если условие выполнено — действие обязательно. Без интерпретации.
5. **Validator + validate-agent.sh.** Бесплатная проверка ловит 80% проблем без LLM.
6. **Память живёт в `knowledge/evolving/`.** После каждой сборки — учись.

---

## Заглушки и плейсхолдеры

В `knowledge/examples/` — образцы агентов с абстрактными именами проектов (`my-app`, `my-project`, `my-bot`). Не копируй пути дословно — это шаблон структуры, не готовый агент.

`MEMORY.md`, `knowledge/evolving/*` — пустые шаблоны. Заполняй своими решениями, паттернами, ошибками.

---

## Конвейер качества

```
Demiurg (создаёт) → validate-agent.sh → Validator
                                          │
                                          ▼
                          (опционально) внешний review → polish
```

Внешние ревьюер и полировщик не входят в репо — подключай свои.

---

## Известное

`bash scripts/validate.sh .` из коробки покажет ~100 broken links — это ссылки на `office/agents/*` живого офиса, в который Демиург обычно встроен. Когда подключишь Демиурга к своему workspace или соберёшь первый офис — ссылки заработают по своим местам.

## Лицензия

MIT

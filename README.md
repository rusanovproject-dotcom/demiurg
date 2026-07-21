# Demiurg — архитектор AI-систем

Демиург собирает AI-агентов и AI-офисы как **системы вокруг знаний**, а не клоны шаблонов. Один скилл, два режима, конвейер фаз (схема ниже), своя память.

```
INTAKE → BRIEF → SCOUT → ADOPT → KNOWLEDGE → BUILD → VALIDATE → ITERATE → WIRE (→ DEPLOY-HANDOFF, если ТГ)
```

---

## Что внутри

```
demiurg/
├── CLAUDE.md             # точка входа, self-trigger rules, характер
├── memory.md             # память Демиурга между сессиями (append-only)
├── agents/               # 9 субагентов (INDEX.md — список; канон в skills/build/SKILL.md)
├── skills/
│   ├── build/            # единый скилл сборки (SINGLE / TEAM) — канон конвейера
│   ├── adapt-employee/   # адаптация существующего агента
│   ├── agent-presentation/  agent-quality-reviewer/  knowledge-alchemist/  knowledge-extractor/
│   └── (аудит офиса — зона Риты /office-cleaner, у Демиурга снят 2026-07-21)
├── knowledge/
│   ├── architecture/     # 18+ файлов: blueprint, memory, routing, handoff, director-cookbook...
│   ├── tactics/          # guardrails, validation, context-economy, debug-playbook
│   ├── examples/         # few-shot: copywriter / tech-lead / wizard / solo / team / offer-architect
│   ├── templates/        # office-tour, quick-start, user-guide, office-passport
│   ├── skill-mastery/    # anatomy / writing-guide / advanced-patterns / evaluation
│   ├── evolving/         # audit-lessons (уроки аудитов; память Демиурга — корневые memory.md / failures.md)
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
cd <корень твоего офиса>
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

`INTAKE → BRIEF → SCOUT → ADOPT → KNOWLEDGE → BUILD → VALIDATE → ITERATE → WIRE (→ DEPLOY-HANDOFF, если ТГ)` —
единственное каноническое описание фаз и гейтов: `skills/build/SKILL.md`.

### Целая команда — режим TEAM (45-90 мин)

Триггеры: `собери команду`, `wizard`, `офис с нуля`.

Wizard ведёт через intake → blueprint → состав команды → для каждого агента: scout → adopt → knowledge → build → validate (eval) → iterate → финальный wire + soul + onboarding.

---

## Принципы

1. **Агент строится ВОКРУГ знаний.** Без data-pack — пустышка с правильной структурой.
2. **Few-shot побеждает abstract guidelines.** В `knowledge/examples/` — реальные образцы, Builder их читает.
3. **Score < 5 = блокер.** Программный, в `_score.json`. Текстовый блокер модель игнорирует.
4. **Self-trigger rules — хардкоды.** Если условие выполнено — действие обязательно. Без интерпретации.
5. **Validator + validate-agent.sh.** Бесплатная проверка ловит 80% проблем без LLM.
6. **Память Демиурга — корневые `memory.md`/`failures.md`; собранным агентам — поле `memory:` в обёртке + страховочный хук** (канон `knowledge/architecture/memory-architecture.md`).

---

## Заглушки и плейсхолдеры

В `knowledge/examples/` — образцы агентов с абстрактными именами проектов (`my-app`, `my-project`, `my-bot`). Не копируй пути дословно — это шаблон структуры, не готовый агент.

`memory.md`/`failures.md` — заполняются по ходу работы (append-only).

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

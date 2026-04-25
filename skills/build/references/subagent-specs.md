# Subagent Specs — Спецификации субагентов

Все субагенты: `demiurg/agents/`. Спавнить через Agent tool.

## Конвейер

```
Knowledge Miner → Builder → validate-agent.sh → Validator → Refiner (если нужно)
                                                    ↑                    |
                                                    └────────────────────┘
```

## Субагенты

### Knowledge Miner (`agents/knowledge-miner.md`)
- **Модель:** sonnet
- **Когда:** ПЕРЕД Builder. Для КАЖДОГО агента.
- **Вход:** brief (роль, задачи), путь workspace
- **Выход:** `knowledge/{agent}/` с реальным контентом + INDEX.md
- **Блокер:** score < 5 → СТОП, сообщить Оркестратору
- **Что ищет:** стиль, примеры, ЦА, антипаттерны, методология, продукт

### Builder (`agents/builder.md`)
- **Модель:** opus
- **Когда:** после Knowledge Miner (score ≥ 5)
- **Вход:** brief + knowledge/{agent}/ + plan из state.json
- **Выход:** CLAUDE.md + skills/ + записи в state.json
- **Обязательно читает:** `knowledge/examples/` (few-shot), `agent-design.md`, `anatomy.md`
- **Правила:** identity ≤300 tok, handle-паттерн, позитивные формулировки

### Validator (`agents/validator.md`)
- **Модель:** sonnet
- **Когда:** после Builder + validate-agent.sh
- **Вход:** путь к агенту, brief, knowledge/{agent}/
- **Выход:** score (0-100), verdict (PASS/NEEDS WORK/FAIL), issues[]
- **5 блоков:** CLAUDE.md (30), Skills (20), Knowledge (20), Connections (15), Character (15)

### Refiner (`agents/refiner.md`)
- **Модель:** sonnet
- **Когда:** Validator score 60-79 (NEEDS WORK)
- **Вход:** issues от Validator + файлы агента
- **Выход:** обновлённые файлы
- **Макс:** 2 раунда

### Researcher (`agents/researcher.md`) — TEAM only
- **Модель:** sonnet
- **Когда:** Фаза 1 (параллельно с Auditor)
- **Вход:** тип проекта из state.json
- **Выход:** briefing в state.json → research

### Auditor (`agents/auditor.md`) — TEAM only
- **Модель:** sonnet
- **Когда:** Фаза 1 (параллельно с Researcher)
- **Вход:** workspace path
- **Выход:** аудит в state.json → audit

### Judge (`agents/judge.md`) — TEAM only
- **Модель:** opus
- **Когда:** Фаза 4 review-refine loop
- **Вход:** все файлы из created_files
- **Выход:** score по 5 осям + issues

## Параллелизм

| Фаза | Параллельно | Последовательно |
|------|------------|----------------|
| Разведка (TEAM) | Researcher + Auditor | — |
| Сборка агента | — | Miner → Builder → validate.sh → Validator |
| Review (TEAM) | — | Judge → Refiner → re-Judge |

## Модели

| Задача | Модель | Почему |
|--------|--------|--------|
| Поиск, сканирование | sonnet | Механическая работа |
| Создание, оценка | opus | Требует judgment |
| Фиксы по инструкциям | sonnet | Конкретные правки |

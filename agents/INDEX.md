# Субагенты Demiurg — Индекс

Спавнить через Agent tool. Модель указана для каждого.
Канонический порядок фаз (без номеров): `Intake → Brief → Scout → Knowledge Mining → Build → Validate → Iterate → Wire`.

## Ядро (каждый агент проходит)

| Файл | Роль | Модель | Когда |
|------|------|--------|-------|
| `knowledge-miner.md` | Сбор знаний из workspace ДО сборки | sonnet | Knowledge Mining (после Scout) |
| `builder.md` | Создание CLAUDE.md + skills/ (с few-shot) | opus | Build (после Knowledge Mining, score ≥ 5) |
| `validator.md` | Проверка агента по 5 блокам (100 баллов) | sonnet | Validate (после Build + validate-agent.sh) |
| `refiner.md` | Фиксы по issues Validator'а | sonnet | Iterate (если Validator NEEDS WORK) |

## TEAM mode (дополнительно)

| Файл | Роль | Модель | Когда |
|------|------|--------|-------|
| `researcher.md` | Best practices и паттерны | sonnet | Разведка (параллельно с Auditor) |
| `auditor.md` | Аудит существующего workspace | sonnet | Разведка (параллельно с Researcher) |
| `judge.md` | Оценка системы целиком (5 осей) | opus | Финальный Review TEAM |

## CustDev pipeline

| Файл | Роль | Модель | Когда |
|------|------|--------|-------|
| `persona-builder.md` | Создание синтетических персон из реальных данных | sonnet | Создание персон |
| `interviewer.md` | Симуляция глубинных CustDev-интервью | opus | Симуляция интервью |

## Конвейер

```
Knowledge Miner → Builder → validate-agent.sh → Validator → [Refiner → Validator]
```

## Скрипт

`scripts/validate-agent.sh` — бесплатная проверка без LLM (запускать перед Validator).

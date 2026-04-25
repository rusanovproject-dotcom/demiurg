# architecture/ — Индекс

L2 файлы knowledge. Грузить **по триггеру задачи**, не все подряд (Progressive Disclosure).

## Корневые принципы (обязательны при любой сборке)

| Файл | Когда загружать |
|------|-----------------|
| `office-blueprint.md` | **ВСЕГДА перед сборкой офиса** — универсальная структура (10 принципов, эталонная папка, корневой CLAUDE.md, 5-слойная память агента, decision tree «соло vs офис») |
| `agent-design.md` | **ВСЕГДА перед сборкой агента** — шаблон CLAUDE.md + правила заполнения + Bad/Good identity + when skill/subagent/hook/MCP + BP/AP |
| `ideal-agent-anatomy.md` | Эталон готового агента: 5 слоёв + финальный чеклист |
| `component-checklists.md` | Покомпонентная проверка: CLAUDE.md (12), Skills (10), Knowledge (8), Связи (7), Memory (5) |

## По теме «память и базы данных»

| Файл | Когда загружать |
|------|-----------------|
| `memory-architecture.md` | **При проектировании памяти** — 5 слоёв (identity / overrides / memory / failures / knowledge), 3 горизонта, 4 категории auto-memory, 3-слойная архитектура с sleep-time consolidator, bi-temporal для client-офисов |
| `knowledge-ownership.md` | Общий vs частный knowledge — куда класть файл (decision tree) |

## По теме «routing и handoff»

| Файл | Когда загружать |
|------|-----------------|
| `routing-patterns.md` | **При проектировании Director'а или связей** — hub-and-spoke vs peer-to-peer, 5 секций Director'а, 4 стратегии контекста, точки входа задач, anti-patterns |
| `handoff-library.md` | **При создании любого handoff'а** — yaml-шаблоны (Director→Specialist, parallel fan-out, peer-to-peer, report-back, intake, subagent, cron, validator) |
| `handoff-protocol.md` | Старый файл — общий формат Task Brief (дополняется handoff-library.md) |

## По теме «Director как first-class агент»

| Файл | Когда загружать |
|------|-----------------|
| `director-cookbook.md` | **При создании Director'а в офисе** — 5 обязательных секций, output contract (5 типов), память дня, разбор полётов, character |

## По теме «контекст-engineering»

| Файл | Когда загружать |
|------|-----------------|
| `context-strategies.md` | **При проектировании любого агента** — 4 стратегии (Write / Select / Compress / Isolate), мапа на файлы офиса, чеклист |
| `context-patterns.md` | Старый файл — конкретные паттерны (Handle, Summary, Specialist), дополняется context-strategies.md |

## По типам офисов

| Файл | Когда загружать |
|------|-----------------|
| `office-types/marketing.md` | **При сборке marketing-офиса** — 6 ролей, brand-as-validator, memory особенности, ROI-чек |
| `office-types/client.md` | **При сборке client-офиса** — 7 ролей, long-running memory, trust boundaries, proactivity |
| `office-types/mixed.md` | **При сборке mixed-офиса (Нейроштаб, гибрид)** — pod-decomposition, переcечения зон, 3 namespace памяти |

## Структуры и lifecycle

| Файл | Когда загружать |
|------|-----------------|
| `folder-patterns.md` | Выбираешь структуру папок (solo / small-team / full-office / hierarchical) |
| `data-packs.md` | Какие данные собирать для каждого типа агента (8 типов + чеклисты) |
| `agent-lifecycle.md` | Добавить/изменить/удалить агента в существующей системе |
| `migration-protocol.md` | Миграция между паттернами: Solo→Small→Full→Hierarchical |
| `checklist-state.md` | Работаешь с wizard'ом (формат demiurg-state.json) |

## Карта триггеров (Triggers → Files)

```yaml
"новый офис" / "собери офис" / "AI-офис с нуля":
  - office-blueprint.md (ВСЕГДА)
  - folder-patterns.md
  - office-types/{marketing|client|mixed}.md (по типу)
  - director-cookbook.md (для Director'а)
  - memory-architecture.md
  - routing-patterns.md
  - handoff-library.md

"новый агент" / "create agent":
  - agent-design.md (ВСЕГДА)
  - ideal-agent-anatomy.md
  - data-packs.md (для типа агента)
  - context-strategies.md
  - examples/{closest-type}.md (один!)

"память" / "memory" / "MEMORY.md" / "база знаний":
  - memory-architecture.md
  - knowledge-ownership.md

"routing" / "handoff" / "Director":
  - routing-patterns.md
  - director-cookbook.md
  - handoff-library.md

"новый скилл" / "create skill":
  - agent-design.md (секция «Когда скилл vs субагент vs hook vs MCP»)
  - skill-mastery/anatomy.md (если есть)

"проектирую marketing-офис":
  - office-blueprint.md
  - office-types/marketing.md

"проектирую client-офис" / "client management":
  - office-blueprint.md
  - office-types/client.md
  - memory-architecture.md (bi-temporal)

"гибрид" / "Нейроштаб" / "разные домены вместе":
  - office-blueprint.md
  - office-types/mixed.md

"минорная правка" / "1-2 файла":
  - НИЧЕГО из knowledge/ — просто Read целевого файла + соседей
```

---

## Принцип Progressive Disclosure

- **L1 (всегда):** `INDEX.md` (этот файл) → даёт карту триггеров
- **L2 (по триггеру):** один из файлов выше через Read
- **L3 (по запросу):** при необходимости — глубокие references (например, `office-types/{type}.md`, `handoff-library.md` для конкретного шаблона)

**Антипаттерн:** «прочитай всё» — контекст разбухает на первой задаче.

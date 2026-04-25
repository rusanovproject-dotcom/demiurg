# Memory Architecture — Память агентов и офисов

Главный документ по тому, **что хранить где** и **как это живёт во времени**. Демиург должен знать это перед сборкой любого офиса. У клиентских офисов память важнее чем у разработческих — агент с клиентом живёт месяцы, не сессии.

**Источники:** `office/agents/mnemo/knowledge/{memory-architecture,agent-memory-patterns,principles,decision-framework}.md` (живая экспертиза по БД и памяти), `office/agents/director/MEMORY-SPEC.md` (рабочая пирамида live-агента), `examples/client-office/` (layered memory pattern), внешний research S9+A5 (Letta / Zep / Mem0 / Anthropic memory tool).

---

## Главное различие: 5 слоёв памяти агента

| Слой | Файл / место | Что хранит | Кто пишет | Объём |
|------|--------------|------------|-----------|-------|
| **Identity** | `CLAUDE.md` или `core.md` | Роль, инструкции, pipeline, характер | Template / Демиург | ≤200 строк |
| **Overrides** | `overrides.md` | Персональные правила клиента | Клиент руками | ≤50 строк |
| **Auto-memory** | `memory.md` (append-only) | Decisions / Patterns / Context | **Агент сам** после задач | растёт |
| **Failures** | `failures.md` (append-only) | Ошибки + правила на будущее | **Агент сам**, grep перед задачей | растёт |
| **Knowledge** | `knowledge/` или `architecture/` | Процедурная память — как делать | Демиург / агент | модули |

`CLAUDE.md ≠ MEMORY.md`. CLAUDE.md = твои инструкции Claude. MEMORY.md = блокнот Claude про твой проект.

Append-only = старые записи не переписываются. Это даёт агенту реальное обучение на опыте.

---

## Три горизонта памяти (Mnemo)

| Горизонт | Что хранит | Реализация |
|----------|------------|------------|
| **Working memory** | Текущий контекст сессии | Context window LLM (бесплатно) |
| **Short-term** | Диалог + промежуточные результаты сессии | Redis, in-memory, `state.json` |
| **Long-term** | Факты, знания, история между сессиями | Markdown / Vector DB / Graph DB / SQL |

**Правило:** для офиса масштаба Хозяина (≤ 100 файлов knowledge, < 17 агентов) **Markdown побеждает vector DB**. Точка перехода — > 100 файлов knowledge → semantic search (pgvector или Mem0).

---

## Три типа долгосрочной памяти (Mnemo, аналог человеческой когнитивной модели)

| Тип | Аналог | Что хранит | Где жить |
|-----|--------|------------|----------|
| **Episodic** | Личные воспоминания | События с timestamps, логи | Vector DB + timestamp / `ops/log.md` / Director pyramid |
| **Semantic** | Справочные знания | Факты, правила, определения | Vector DB / SQL / `knowledge/*.md` |
| **Procedural** | Навыки | Воркфлоу, инструкции | `knowledge/architecture/`, `skills/` |

---

## Современная 3-слойная архитектура (Letta / Anthropic / Mem0)

Для долгоживущих агентов (особенно client-офисы), индустриальный консенсус 2026:

```
{agent}/
  CLAUDE.md           # identity (immutable per release)
  memory/
    core.md           # L1 editable blocks (4-8 блоков, ≤100 строк каждый, агент правит)
    buffer.md         # L2 recent actions (последние 20-30 событий)
    archival/         # L3 long-term (markdown с frontmatter valid_until)
      INDEX.md
      projects/
      clients/
      learnings/
  knowledge/          # процедурная память (как делать)
  skills/             # триггерные процедуры
```

**Core memory** (L1) — editable блоки **в контекстном окне**: 4-8 блоков, каждый помечен label+limit. Агент сам правит по мере получения новой информации (Letta blocks pattern).

**Buffer** (L2) — последние 20-30 действий сессии. Вытесняется FIFO.

**Archival** (L3) — внешнее хранилище. Markdown с YAML frontmatter (`valid_until: 2026-XX-XX`).

### Sleep-time consolidator (критическое дополнение)

Отдельный агент-консолидатор `agents/consolidator.md` запускается асинхронно (cron на ночь / при `/clear` / по триггеру) и делает:

1. **Buffer → Archival.** Читает `buffer.md`, экстрактирует ключевые факты, дописывает в `archival/`.
2. **Refresh core.md.** Если в archival появилась более актуальная инфа — обновляет соответствующий блок в core.
3. **Invalidate stale facts.** Для записей в archival с `valid_until < today` — помечает `invalidated_at: YYYY-MM-DD` (не удаляет).

Без consolidator память накапливает мусор. Это **must-have для client-офисов** (агент живёт с клиентом месяцами).

---

## 4 категории auto-memory (Anthropic стандарт)

Применяется к `.claude/memory/MEMORY.md` + topic-файлы:

```
.claude/memory/
├── MEMORY.md                          # Index — каждая строка ≤150 символов, со ссылкой
│
├── user_role.md                       # Кто владелец (роль, экспертиза)
├── user_style.md                      # Как с ним говорить
│
├── feedback_testing.md                # "Не мокай БД, был инцидент в Q4"
├── feedback_pr_format.md              # "Один PR на refactor, не дробить"
│
├── project_clients.md                 # Кто клиенты, что хотят
├── project_decisions.md               # Почему выбрали Next.js, а не Django
├── project_metrics.md                 # KPI, revenue targets
│
├── reference_folder_map.md            # office → штаб, clients → клиенты
└── reference_external_systems.md      # Notion DB IDs, GitHub orgs
```

**Формат записи в MEMORY.md (index):**
```markdown
- [Клиент X](project_clients.md) — школа коучей, бюджет 500k/мес, любит метрики
- [Не мокай БД в тестах](feedback_testing.md) — инцидент Q4, мокали — упало в проде
```

Каждая запись = **1 строка, ≤150 символов, со ссылкой на детальный topic-файл**.

### Что класть в каждую категорию

- **user_*** — роль, экспертиза, степень погружённости в темы. Стиль коммуникации (длина, формат, тон). Предпочтения по инструментам.
- **feedback_*** — корректировки твоих ошибок С УКАЗАНИЕМ ПРИЧИНЫ (инцидент, предпочтение). Структура: правило → **Почему:** → **Когда применять:**.
- **project_*** — кто клиенты, архитектурные решения с обоснованием, активные инициативы, дедлайны. Конвертируй относительные даты в абсолютные ("в четверг" → "2026-05-07").
- **reference_*** — Notion DB IDs, GitHub проекты, Slack каналы. Не цитируй внешние данные — указывай **как до них дойти**.

---

## 6 паттернов из продакшна (Mnemo)

1. **Multi-scope tagging.** Каждая запись тегируется уровнем: `user / agent / session / org`. Достаётся только нужный скоп при запросе.
2. **Async writes.** Запись в память НЕ блокирует ответ агента. Пишется в фоне.
3. **Memory consolidation.** Диалог → LLM извлекает ключевые факты → обновляет summary. Хранит дистиллированное знание, не сырые чаты.
4. **Hybrid retrieval.** Vectors для semantic entry point → Graph для multi-hop traversal. Нашёл сущность через vector → прошёлся по рёбрам графа.
5. **Dynamic decay.** Старые / нерелевантные записи получают пониженный вес. Без этого память засоряется.
6. **Agent Session Summary Protocol.** После каждой задачи агент пишет: что сделано / что круто (≤5) / что докрутить (≤8) / паттерны / взято в работу / прогресс было-стало. Хранится в `office/ops/agent-summaries/YYYY-MM-DD-{agent}-{slug}.md`.

---

## Lifecycle: когда писать, читать, чистить

### Перед задачей (агент сам)
1. **`grep` по `failures.md`** на ключевые слова задачи — не наступай на старые грабли
2. **Прочитай `memory.md` секцию Context** — что помнить из прошлых сессий
3. **Если в брифе передан scout-досье** — прочитай первым (см. `knowledge-miner.md` Шаг 0)

### После задачи (агент сам)
1. **Append в `memory.md`:**
   - **Decisions** — что решил и почему (1-2 строки)
   - **Patterns** — что заметил (поведение, цифры, реакции)
   - **Context** — что помнить в следующей сессии
2. **Если ошибка / промах** — append в `failures.md` по формату: `YYYY-MM-DD → что пошло не так → почему → правило на будущее`
3. **Если задача > 30 мин** — Agent Session Summary в `ops/agent-summaries/`

### Раз в неделю / месяц (consolidator или вручную)
1. `/consolidate-memory` — слить дубли в memory.md, очистить неактуальное
2. Перенести записи с `valid_until < today` из archival в archive (или пометить invalidated_at)
3. Обновить core.md блоки если появилась более актуальная инфа

### Append-only — критическое правило
**Старые записи не переписываются.** Если факт изменился — добавь новую запись «X стало Y, см. запись от ZZZZ-ZZ-ZZ». Это история обучения агента.

---

## Чего НЕ хранить в памяти

- Здоровье, диагнозы, медицинские данные
- Государственные ID, паспорта, СНИЛС
- Адреса (домашний — нельзя без явной просьбы; рабочий ок)
- Пароли, секреты, токены
- Религиозные / политические взгляды
- Состояние текущей задачи (это TodoList, не память)
- Код-паттерны и архитектуру (это в коде)
- Git history (это `git log`)
- Дубли существующих memory-файлов

---

## Bi-temporal memory для client-офисов (Graphiti / Zep)

Для **client-офисов** vector DB недостаточно — факты устаревают. Bi-temporal modeling: каждый факт имеет 4 timestamp:

- `t_valid` — с какого момента факт верен
- `t_invalid` — с какого момента факт перестал быть верен
- `t_created` — когда добавлена запись
- `t_expired` — когда удалена / помечена устаревшей

**Применимость:** в шаблоне client-офиса слот `memory/client-graph/` — markdown-записи с frontmatter `valid_until`. Можно начать с простых markdown, при росте — мигрировать на Graphiti.

**Без этого** client-агенты будут оперировать устаревшими фактами («клиент платит 50К» после того как сделка порвана).

---

## Точка перехода: когда нужна реальная БД?

| Условие | Решение |
|---------|---------|
| < 100 файлов knowledge, < 5 агентов | **Markdown + grep**. Достаточно. |
| > 100 файлов knowledge | **pgvector** (если есть Postgres) или **Mem0** (managed) |
| Долгоживущие агенты с клиентами + устаревающие факты | **Graphiti** (bi-temporal graph) |
| Сессионная память (ускорение) | **Redis** |
| Сложные связи между сущностями | **Kuzu** (embedded graph, без отдельного сервера) |

**Что НЕ брать (хайп без причины):**
- Pinecone — платишь 10-50× за то же, что pgvector / ChromaDB
- Weaviate — переусложнён для большинства задач
- Graph-only без vector — медленный холодный старт

**Бенчмарк:** Mem0 vector-only даёт **-4.5% точности**, но **-14× токенов и -9× латентность** vs full-context. Full-context не production-viable при масштабе.

---

## Эталоны (читай перед проектированием памяти)

**Внутренние:**
- `office/agents/mnemo/knowledge/memory-architecture.md` — 3 горизонта + 6 паттернов из продакшна
- `office/agents/mnemo/knowledge/agent-memory-patterns.md` — Agent Session Summary Protocol
- `office/agents/mnemo/knowledge/decision-framework.md` — decision tree выбора БД
- `office/agents/director/MEMORY-SPEC.md` — рабочая пирамида live-агента (ядро/дни/недели/месяцы)
- `examples/client-office/office/agents/{director,strategist,demiurg,designer}/core.md` — паттерн layered memory в действии

**Внешние:**
- [Letta agent memory](https://www.letta.com/blog/agent-memory) — 3-слойная теория
- [Zep / Graphiti paper](https://arxiv.org/abs/2501.13956) — bi-temporal graph
- [Mem0 production paper](https://arxiv.org/abs/2504.19413) — managed memory layer
- [Anthropic Memory Tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool) — managed agents memory

---

## Quick wins для существующего офиса

Если офис уже построен без layered memory — миграция за 30 минут:

1. Для каждого агента создать `memory.md` (пустой, append-only) и `failures.md` (пустой)
2. В CLAUDE.md агента добавить секцию «Память (обязательно)» — `grep failures.md` перед, append memory.md после
3. После 1 недели работы — Демиург проверяет: накопились ли записи. Если у агента 0 записей за неделю — он не пишет память. Перенастроить CLAUDE.md.

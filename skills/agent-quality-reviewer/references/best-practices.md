# Best Practices для AI-агентов и команд

> Синтез из 25 000+ строк исследований, 100+ источников
> Март 2026

---

## BP-01: Принцип узкого скопа

**Формулировка:** 2 узких агента лучше 1 широкого.

**Почему работает:**
- Узкий контекст = меньше ошибок
- Специализация = глубина
- Лёгче отладить и заменить

**Реализация:**
```
Задача: "Создать контент-план на месяц"

Плохо: ContentAgent(research + strategy + writing + editing + scheduling)

Хорошо:
  ResearchAgent → тренды и данные
  StrategyAgent → структура и углы
  WriterAgent × 3 → параллельно пишут посты
  EditorAgent → стиль и факты
```

**Метрика:** Каждый агент должен описываться в 1 предложении.
Если нужно 3 предложения — разбей на 3 агента.

---

## BP-02: Context Engineering > Model Selection

**Формулировка (Jason Liu):** "Your model is not the bottleneck. Your context is."

**Что это значит:**
Отличный контекст + средняя модель > плохой контекст + лучшая модель.

**Чеклист контекста:**

```
[ ] CLAUDE.md — ядро (max 200 строк)
[ ] Context pack — загружается при старте задачи:
    [ ] State — текущее состояние (state.md)
    [ ] Task brief — что делаем, входные данные, критерии
    [ ] Relevant files — только нужные файлы, не всё подряд
    [ ] Decision log — прошлые решения
[ ] После задачи — обновить state
```

**Пример плохого vs хорошего контекста:**
```
ПЛОХО: "Write code"

ХОРОШО: "Write REST endpoint for user creation with:
  - OAuth2 flow (see /api/auth for reference)
  - Input validation with JSON schema
  - Tests covering happy path + error cases
  - API docs in OpenAPI format
  Current stack: FastAPI + PostgreSQL + Docker
  Reference: existing endpoints in /api/v2/"
```

---

## BP-03: Explicit State Management

**Формулировка:** Состояние должно быть явным, версионированным, трассируемым.

**Реализация:**
```
state = v1 (initial)
Agent A updates → v2
Agent B updates → v3
Agent C reads v3, makes decision → v4
(Always traceable: who changed what and why)
```

**Обязательные файлы для команды:**
- `PROJECT_STATE.md` — текущее состояние проекта
- `DECISIONS.md` — лог решений с обоснованиями
- `ERRORS.md` — известные проблемы и решения
- `ARCHITECTURE.md` — текущая архитектура

**Инсайт:** Агенты, которые читают state перед работой, экономят 20-30% токенов.

---

## BP-04: Observability First

**Формулировка (Harrison Chase):** "You can't manage what you can't see."

**Минимальный набор:**
```
1. Логи — что делал каждый агент
2. Метрики — tokens, time, cost per task
3. Traces — цепочка делегации (кто → кому → что)
4. Алерты — если что-то сломалось
```

**Инструменты 2026:**
- LangSmith (для LangGraph) — золотой стандарт
- Langfuse (open-source альтернатива)
- OpenObserve (self-hosted, бесплатно)
- Prometheus + Grafana (для кастомных метрик)

**Правило:** Добавляй мониторинг ДО первого запуска, не после первого сбоя.

---

## BP-05: Human in the Loop

**Формулировка (Karpathy):** "99% automation + 1% human review > 100% automation"

**Когда ОБЯЗАТЕЛЬНО human approval:**
```
- Deploy to production
- Delete data/files/branches
- Send external communications
- Spend money (>$20)
- Change infrastructure/configs
- Merge to main
- Access to new data sources
```

**Когда агент может действовать автономно:**
```
- Мелкие правки файлов
- Локальное тестирование
- Research и анализ
- Draft PR (не merge!)
- Добавление в knowledge base
- Комментарии к issues
```

**Ethan Mollick:** "Teams with AI + human oversight significantly more likely to produce top-tier solutions."

---

## BP-06: Error Recovery Protocol

**3-Strike Rule:**
```
Attempt 1: Execute task
  → FAIL → log error, add context

Attempt 2: Execute with additional context
  → FAIL → log error, try alternative approach

Attempt 3: Execute alternative
  → FAIL → STOP, escalate to human with:
    - What was tried (3 attempts)
    - What failed and why
    - Suggested next steps
```

**Partial Result Handling:**
```
If partial result is usable:
  → Pass to next agent with note: "partially complete, missing X"

If partial result is not usable:
  → Retry with refined prompt

If retry also fails:
  → Escalate to human
```

---

## BP-07: Skill Design Principles

**Из анализа лучших скиллов (Reddit, GitHub, Composio):**

1. **Decision rules > Theory**
   - Не пиши "что такое unit economics"
   - Пиши "если LTV/CAC < 2 → НЕ рекомендуй"

2. **Examples are mandatory**
   - Каждое правило = минимум 1 good example + 1 bad example
   - Claude понимает примеры лучше инструкций

3. **Encode YOUR preferences**
   - Скилл работает лучше если кодирует КАК ТЫ думаешь
   - Не generic best practices, а твои решения

4. **Ideal size: 100-300 строк**
   - <50 строк → слишком мало, просто добавь в промпт
   - >500 строк → разбей на несколько скиллов

5. **Metadata matters more than content**
   - Если description плохой — скилл никогда не сработает
   - Trigger phrases должны быть конкретными и "pushy"

---

## BP-08: Communication Protocol для команд

**Structured Mailbox (лучшая практика):**
```json
{
  "from": "ResearchAgent",
  "to": "WriterAgent",
  "action": "write_article",
  "context": {
    "topic": "AI Agent Teams in 2026",
    "research_summary": "...",
    "key_stats": ["...", "..."],
    "tone": "professional but accessible"
  },
  "constraints": {
    "max_length": 2000,
    "format": "markdown",
    "deadline": "15_minutes"
  },
  "decision_context": {
    "why_this_topic": "trending on HN this week",
    "alternatives_rejected": ["topic B — too niche"]
  }
}
```

**Shared Files (минимальная модель):**
```
shared/
├── state.md          — текущее состояние
├── decisions.md      — лог решений
├── task_board.md     — задачи и статусы
└── errors.md         — проблемы и решения
```

---

## BP-09: Cost Optimization

**Данные (Simon Willison):**
- Chat: 1x tokens
- Single agent: ~4x tokens
- Multi-agent: ~15x tokens

**Стратегии:**
1. **Cache everything** — результаты API, файлы, промежуточные результаты
2. **Use cheap models for simple tasks** — не Claude Opus для форматирования
3. **Parallel > Sequential** — меньше ожидания = меньше overhead
4. **Budget per task** — если >$5, стоп и спроси
5. **Monitor daily** — weekly cost report

**ROI Rule:**
Мультиагент оправдан когда:
- Задача занимает человека >4 часов
- Задача повторяется регулярно
- Результат высокоценный
- Параллелизм реально ускоряет

---

## BP-10: Versioning & Evolution

**Версионируй всё:**
```
agents/
├── researcher/
│   ├── v1.0/   — initial
│   ├── v1.1/   — fixed edge case
│   ├── v2.0/   — major rewrite
│   └── current → v2.0
```

**Цикл улучшения:**
```
1. Run agent on task
2. Measure: quality, speed, cost, errors
3. Identify bottleneck
4. Improve (one thing at a time!)
5. A/B test old vs new
6. If better → update current
7. If worse → rollback
```

**Monthly Review:**
- Какие агенты используются?
- Какие агенты ни разу не сработали? (удалить?)
- Где ошибки повторяются? (улучшить?)
- Что стоит дороже всего? (оптимизировать?)

---

## BP-11: Documentation for Humans

**Каждый агент должен иметь:**
```
1. README — что делает, когда использовать, когда НЕ использовать
2. Examples — 2-3 реальных примера работы
3. Known Limitations — честно, что не умеет
4. Troubleshooting — частые проблемы и решения
5. Changelog — история изменений
```

**Зачем:** Другой человек (или ты через месяц) должен понять агента за 5 минут.

---

## BP-12: Federation of Agents (FoA) — Advanced

**Из русскоязычного сообщества (Habr, март 2026):**

Вместо жёстких ролей → динамическая координация по компетенциям:

```
Versioned Capability Vectors (VCV):
- Не "это QA"
- А "может тестировать, валидировать данные, проверять регрессии"

Оркестратор:
- Не маршрутизирует по имени роли
- Ищет в пространстве компетенций через HNSW-индекс
- Находит лучшего доступного агента для подзадачи
```

**Когда использовать:** Когда у тебя >10 агентов и задачи непредсказуемые.
Для большинства — BP-01 (узкий скоп) достаточен.

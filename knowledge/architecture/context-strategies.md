# Context Strategies — 4 стратегии работы с контекстом агента

Karpathy: «context engineering, не prompt engineering». Большинство офисов проваливаются не на промтах, а на том **что попадает в контекст-окно** агента в каждый момент. 4 стратегии (LangChain) — рамка которую Демиург применяет при проектировании любого агента.

**Когда читать:** при создании любого CLAUDE.md / SKILL.md. **Источники:** ext research S5 (LangChain context engineering / Karpathy), `office/agents/mnemo/knowledge/principles.md`, MASTER.md «Часть V. Подгрузка по запросу».

---

## 4 стратегии (выбираешь под задачу)

| Стратегия | Что делает | Главный риск |
|-----------|------------|--------------|
| **Write** | Сохраняй вне контекстного окна | Забыть переписать обратно при следующей сессии |
| **Select** | Подгружай точечно по триггеру | Триггер не сработает / неточный → пропустишь нужное |
| **Compress** | Суммаризация и trimming | Потерять важные детали при сжатии |
| **Isolate** | Subagent с собственным окном | Координационный overhead, потеря контекста между |

---

## Write — сохраняй вне окна

**Что значит:** не держи в контексте то, что можно вытащить позже. Запиши в файл, продолжи работу.

**Куда писать:**
- `state.json` — текущая фаза, прогресс, checkpoint (для долгих сборок)
- `ops/log.md` — лог операций («запустил X в 14:32»)
- `memory.md` — Decisions / Patterns / Context; запись гарантирует механизм (`memory:` в обёртке / capture-хук), не пункт промпта
- `failures.md` — правила из ошибок; тот же механизм записи, grep перед задачей — агент сам
- `agent-summaries/` — Agent Session Summary Protocol после задачи > 30 мин

**Когда НЕ нужно:** мелкая правка одного файла, ответ на вопрос. Не каждое действие требует Write.

**Антипаттерн:** пихать всё в текущий контекст, надеясь что Claude запомнит. После /clear или сжатия — потеряется.

---

## Select — подгружай точечно по триггеру

**Что значит:** не загружай knowledge/ целиком. Загружай только нужный файл когда задача его требует.

**Технические приёмы:**
- **Handle-паттерн:** в CLAUDE.md ссылки `knowledge/{file}.md`, не inline-копии
- **@-include** (project-style CLAUDE.md): `@office/agents/director/core.md` — подтянется при загрузке корневого
- **Read-on-demand:** агент сам делает Read на упомянутый путь когда задача его касается
- **Triggers в frontmatter:** `triggers: [keyword1, keyword2]` для каждого L2-файла knowledge/

**Карта триггеров для knowledge/ агента:**

```yaml
# knowledge/INDEX.md (всегда грузится — L1)
files:
  - path: architecture/agent-design.md
    triggers: [новый агент, build, проектирую агента]
    when: ОБЯЗАТЕЛЬНО при создании любого агента
  - path: architecture/memory-architecture.md
    triggers: [память, memory, MEMORY.md, knowledge bases]
    when: при проектировании памяти агента/офиса
  - path: architecture/routing-patterns.md
    triggers: [routing, handoff, Director, decomposition]
    when: при проектировании Director'а
```

**Антипаттерн:** «прочитай всё из knowledge/» в инструкции. Контекст разбухнет на первой же сборке.

---

## Compress — суммаризация и trimming

**Что значит:** сжимай результаты длинных операций до сути. Хранит дистиллированное знание, не сырые чаты.

**Когда применять:**
- После Researcher / Auditor: вернули отчёт 5K строк → Demiurg синтезирует в 30 строк tl;dr + ссылку на полный
- После Builder: сборка вернула 20 файлов → Demiurg показывает Хозяину список + score, не содержимое
- При >50% контекста → `compact` (встроенная фича Claude Code)
- При >70% → `checkpoint в state.json + /clear`, новая сессия с state.json

**Sleep-time consolidator** (см. `memory-architecture.md`) — асинхронный compress: buffer.md → archival/ → INDEX обновляется.

**Antipattern:** возвращать Хозяину весь сырой output subagent'а. Он не для этого.

---

## Isolate — subagent с собственным окном

**Что значит:** тяжёлая работа уходит в отдельный subagent с собственным context window. Главный агент не загружает её контент, только результат.

**Когда применять:**
- Knowledge Mining — отдельный subagent сканирует workspace, возвращает score + INDEX
- Builder — отдельный subagent создаёт CLAUDE.md, возвращает путь
- Validator — отдельный subagent проверяет, возвращает score + issues
- Research — параллельные Researcher + Auditor + Profiler

**Правило (Anthropic):** на каждой фазе где можно распараллелить — спавни **3-5 subagents одновременно**. Максимум **2 пула по 4**, не один пул из 8 (Anthropic C compiler case: 4×4 ВСЕГДА бьёт 1×8).

**Bounded depth:** агент не может спавнить агента, который спавнит агента — глубина 3 уровня = стоп. Иначе цепочка раскрутится в неконтролируемое.

**Антипаттерн:** делать всю фазу build в одном контексте. После 3-4 фаз контекст перегружен, качество падает.

---

## Мапа на файлы офиса

Из абстракции в конкретные файлы:

| Стратегия | Где живёт в офисе |
|-----------|-------------------|
| **Write** | `state.json` (per-session), `ops/log.md`, `memory.md` (per-agent), `failures.md`, `agent-summaries/` |
| **Select** | `knowledge/INDEX.md` (триггер-карта), Read-by-trigger, @-includes в CLAUDE.md |
| **Compress** | Sleep-time consolidator, Director synthesis rules, Agent Session Summary Protocol, `compact` команда |
| **Isolate** | Subagents (Knowledge Miner, Builder, Validator, Refiner), параллельный fan-out, `Task(subagent_type=X)` |

---

## Чеклист при создании нового агента (применить 4 стратегии)

- [ ] **Write:** есть ли `memory.md` + `failures.md` (append-only)? В обёртке `.claude/agents/` задан `memory: project`? В CLAUDE.md — «перед задачей grep failures.md» (запись гарантирует `memory:`/хук, не пункт промпта)?
- [ ] **Select:** в CLAUDE.md handle-паттерн (ссылки на файлы), не inline-копии. Triggers в knowledge/ INDEX.md.
- [ ] **Compress:** Output contract — что именно агент возвращает (не сырьё). Если задача > 30 мин — Agent Session Summary в `agent-summaries/`.
- [ ] **Isolate:** есть ли тяжёлая фаза которая может уйти в subagent? Если да — Direct/Demiurg вызывает Subagent через `Task(subagent_type=...)`.

---

## Размер контекста — что замерять

**Эмпирика практиков** (не официальный лимит Anthropic): после **30-40% заполнения окна** качество ответов начинает деградировать. Окно 1M — это потолок, не цель.

**Что трекать (в `state.json` или per-message):**
- Total tokens used in current session
- Files loaded (с размерами)
- Subagent calls (со средним usage)
- При > 50% — `compact`. При > 70% — `checkpoint + /clear`.

**Файл-«паразит»** = файл который грузится автоматически (через @-include или CLAUDE.md mention) и весит > 5K токенов. Если такой найден — выноси в Select (триггерная подгрузка).

---

## Anti-patterns в context engineering

| Анти-паттерн | Почему плохо | Стратегия лечения |
|--------------|--------------|------------------|
| CLAUDE.md > 200 строк с inline knowledge | Размытие фокуса | Split: CLAUDE.md ≤200 + handle-ссылки на knowledge/ (Select) |
| «Прочитай всё в knowledge/» в инструкции | Контекст разбухает | Triggers per file в INDEX.md (Select) |
| Director возвращает Хозяину сырой output specialist'а | Хозяин тонет в деталях | Synthesis rules: 1-2 строки tl;dr + ссылка (Compress) |
| Build целиком в одном контексте | После фазы 4 — контекст перегружен | Subagents per фаза (Isolate) |
| Каждая сессия с нуля, без памяти | Дрейф, повтор ошибок | memory.md + failures.md (Write) |
| 8 параллельных subagents в одном пуле | Координационный overhead, information withholding | 2 пула по 4 (Isolate, Anthropic) |
| Пихать в контекст «на всякий случай» | Signal-to-noise падает | Чёткие triggers, Read только при необходимости (Select) |

---

## Эталоны

**Внутренние:**
- `office/agents/mnemo/knowledge/principles.md` — фундаментальные принципы хранения
- `knowledge/architecture/context-patterns.md` — Handle / Summary / Specialist (старый файл, дополняется этим)
- `MASTER.md` Часть V. Подгрузка по запросу

**Внешние:**
- [LangChain — Context engineering for agents](https://www.langchain.com/blog/context-engineering-for-agents)
- [Karpathy — Context engineering tweet](https://x.com/karpathy/status/1937902205765607626)
- [Anthropic — Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) (orchestrator-worker, isolation)

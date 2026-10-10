# Routing Patterns — Как направляются задачи в офисе

Как задача от человека (или входящая) проходит через офис: классификация → маршрутизация → handoff → возврат. Без этого офис превращается в хаос даже при идеальных агентах. **Hub-and-spoke дефолт 2026** — error amplification 4.4× vs mesh 17.2×.

**Источники:** ext research S1+S4+S8 (Anthropic / LangGraph supervisor / OpenAI Swarm), `office/CLAUDE.md` (живой Director), `examples/client-office/office/agents/director/core.md` (clean Director), `office/protocols/DATA-ROUTING.md`.

---

## Hub-and-Spoke vs Peer-to-Peer

| Критерий | Hub-and-Spoke (Supervisor) | Peer-to-Peer (Swarm) |
|---|---|---|
| Error amplification | **4.4×** | 17.2× |
| Latency per step | 2-5 сек делегирования | ~1 сек direct handoff |
| Debuggability | Высокая (все решения через хаб) | Низкая (распределённый trace) |
| Security при prompt injection | Single point of control | Defense-in-depth (но трудно мониторить) |
| Сложность написания | Средняя (1 Director + N specialists) | Высокая (каждый знает каждого) |
| Дефолт 2026 | **Да** | Нет |

**Правило для Демиурга:** дефолт — hub-and-spoke. Mesh разрешён только если:
- 2 агента (не больше) с явным bidirectional handoff'ом (например, copywriter ↔ equalizer)
- В brief'е новой связи указано обоснование «mesh because X»

---

## Director — first-class агент с 5 обязательными секциями

Director — не «файл с роутингом», а полноценный агент. Если он галлюцинирует декомпозицию — весь офис неисправен независимо от качества specialists. У Director обязательно:

### 1. Roster awareness — кто в команде
Один источник правды — `office/AGENTS.md`. В CLAUDE.md Director'а **не дублировать список агентов**, только ссылка. Перед ответом «кто в команде» — Director **читает AGENTS.md**.

### 2. Decomposition rules — как разбивать входящую задачу
Algorithm (из office/CLAUDE.md):
```
1. QUESTION  — Кто потребовал? Почему именно так?
2. DELETE    — Что убрать? Лучшая деталь — отсутствующая.
3. SIMPLIFY  — Упрости выжившее.
4. ACCELERATE — Ускорь цикл.
5. AUTOMATE  — Автоматизируй ПОСЛЕДНИМ.
```

Плюс **Revenue Tier filter**:
- Tier 1 (revenue сейчас) — A+ Task всегда
- Tier 4 запрещён пока есть открытые Tier 1
- Revenue ratio ≥ 40%

### 3. Delegation protocol — формат task_brief
Все handoff проходят через единый yaml. Без `expected_output` и `boundaries` — handoff теряет 30-40% контекста (Anthropic). См. `handoff-library.md`.

### 4. Synthesis rules — как собирать результаты обратно
Когда несколько specialists вернулись — Director не пересказывает их выходы Хозяину дословно, а **синтезирует**:
- Что сделано (1-2 строки)
- Что готово, что ждёт ревью
- Какие вопросы нужны от человека
- Один следующий шаг

### 5. Escalation policy — когда Director отказывается и зовёт человека
- 2 фейла подряд → REWIND (не correctional prompts)
- Размытая задача → `/interview`
- Расходы > $20 → одобрение
- Деплой в прод → одобрение
- Удаление сервисов → одобрение
- Tier 1 при > 3 одновременных задач in_progress → «слишком много, что убрать?»

---

## 4 стратегии контекста (LangChain) — мапа на файлы офиса

При роутинге Director решает не только «кому», но и «что подгружается». 4 стратегии (Karpathy: «context engineering, не prompt engineering»):

| Стратегия | Что | В офисе |
|-----------|-----|---------|
| **Write** | Сохраняй вне контекста | `state.json`, `ops/log.md`, `memory.md` (агент пишет после) |
| **Select** | Подгружай точечно по триггеру | `knowledge/{domain}.md` через @-include или Read по ссылке |
| **Compress** | Суммаризация и trimming | Sleep-time consolidator, Agent Session Summaries |
| **Isolate** | Subagent с собственным окном | Параллельные Researcher/Auditor/Builder в фазе TEAM-build |

**Правило:** офис проваливается на **Isolate** (всё грузят в один контекст). Демиург обязан проектировать так, чтобы тяжёлая работа уходила в subagents с **task_brief** и возвращала **сжатые результаты**, не сырьё.

---

## Decomposition: как Director разбирает входящую

### Шаг 1: классификация (5 секунд)
```
Это задача → Tier 1/2/3/4
Это вопрос → ответь сразу, не роутишь
Это мозговой штурм → НЕ создавай Notion-задачу
Это размытая → /interview
Это «делай прямо сейчас» → делай
```

### Шаг 2: подбор агента
- Один явный домен → один агент
- > 1 домен → связка (последовательная или параллельная)
- Никто не подходит → честный fallback («такого помощника пока нет, для текущей задачи могу через X»)

### Шаг 3: проверка зависимостей
**Параллельные** (запускать одновременно): Intelligence + Copywriter, Designer + Copywriter, Producer + Intelligence.

**Последовательные** (один ждёт другого): Copywriter ждёт данные Intelligence, Equalizer ждёт оффер Producer.

### Шаг 4: формирование task_brief
yaml-шаблон с `objective / context / expected_output / boundaries`. См. `handoff-library.md`.

### Шаг 5: dashboard (если 2+ агента)
Таблица «# / задача / агент / статус» — обновляется при возврате каждого. См. office/CLAUDE.md секция «Коммуникация — Dashboard задач».

---

## Точки входа задач (entry points)

Откуда задачи прилетают в офис:

| Источник | Как обрабатывается |
|----------|-------------------|
| Прямой чат с Director (Claude Code) | Стандартный путь: classify → route → handoff |
| Telegram → my-assistant → Director | Director как live front-end → передаёт Director'у |
| Notion (вручную поставлено) | Director видит при `/triage` или старте `/morning` |
| Email (через MCP gmail) | Заявки клиентов → Hermes (продажи) |
| Web-форма (my-booking / my-form) | Через VPS API → Notion DB → Director видит |
| Cron (ночная команда) | Скрипты сами спавнят agents для batch-задач (Draft PR, не мерж) |

**Правило:** все entry points → **в один пайплайн** (классификация Director'а или эквивалент). Не дублируй логику классификации в каждом entry point.

---

## Handoff форматы — сводка

(полные шаблоны и примеры — в `handoff-library.md`)

### Director → Specialist
```yaml
from: Director
to: Copywriter
task: написать продающий пост про оффер v6
why: запуск через 2 недели, нужен прогрев
context:
  - offer: hub/product/offer-v6.md
  - audience: knowledge/audience/pains.md
  - brand_voice: knowledge/brand/voice.md
expected_output:
  format: markdown
  contains: [hook, story, mechanism, CTA]
  length: 800-1200 words
boundaries:
  - do_not: [упоминать конкурентов, использовать AI-слоп]
  - validation: пройти Equalizer
deadline: до конца дня
escalate_if: brand_voice file отсутствует
```

### Specialist → Specialist (через Director)
По умолчанию — **через Director**. Прямой handoff Specialist→Specialist разрешён для **2 связанных ролей** (copywriter→equalizer, designer→reviewer) с явной yaml-ссылкой в обоих CLAUDE.md.

### Specialist → Director (report-back)
```yaml
from: Copywriter
to: Director
task_id: <ссылка>
status: done | needs_review | blocked
deliverables:
  - hub/product/copy/post-v6.md
issues: []
next_step_suggestion: «передай Equalizer на проверку жирности»
```

### Human → Director (intake)
Свободный текст. Director классифицирует. Если задача размытая — запускает `/interview`.

---

## Anti-patterns (что НЕ делать)

| Анти-паттерн | Почему плохо | Как правильно |
|--------------|--------------|---------------|
| Director перечисляет всех агентов в своём CLAUDE.md | Дрейф (агенты добавляются/удаляются), 200+ строк, нарушение правила | Ссылка на `AGENTS.md`. Director читает его перед ответом «кто в команде». |
| Handoff без `expected_output` | Specialist додумывает формат, выдаёт не то | yaml с явным `expected_output.format` и `expected_output.contains` |
| Director сам делает работу | Перегруз, теряет контекст роутинга | Director = координатор, не исполнитель. Всегда предлагает агента. |
| Прямой Specialist → Specialist без записи в обоих CLAUDE.md | Хрупкая связь, не отлаживается | Bidirectional yaml-ссылка в обоих файлах + обоснование в brief |
| > 5 specialists на одного Director | Перегруз Director'а, information withholding | Pod-decomposition (см. `office-types/mixed.md`) |
| Один CLAUDE.md на 500 строк с inline knowledge | Размытие фокуса, нарушение Progressive Disclosure | CLAUDE.md ≤200 строк, knowledge через handle-паттерн (ссылки, не inline) |
| Mesh без обоснования | Error amplification 17.2× | Hub-and-spoke дефолт. Mesh — только с явным «mesh because X» |

---

## Iteration limits + escalation path (обязательны)

В каждом Director'е и крупном Specialist'е — секция `## Limits`:

```yaml
max_iterations: 3
max_subagent_depth: 2  # агент не может спавнить агента, который спавнит агента
escalation_rule: после 3 попыток или 2 fail подряд — стоп, эскалируй человеку
```

Без этого агент может залипнуть в бесконечном цикле или раскрутить цепочку subagents глубиной 5+.

Validator проверяет наличие.

---

## Search wide → narrow (для research-агентов)

Researcher, Intelligence, Scout — сначала **широкий поиск** (5-7 направлений параллельно), потом по результатам сужают. Противоположность — сразу узкий точечный запрос — теряет контекст поля.

```
Шаг 1: 5-7 широких направлений (параллельно subagents)
Шаг 2: остановка, синтез landscape
Шаг 3: «какое направление углубить?» — спрашивает оркестратора или сам решает по heuristic
Шаг 4: deep-dive в выбранное (ещё subagent)
```

---

## Эталоны

**Внутренние:**
- `office/CLAUDE.md` — живой Director на 17 агентов (с минусами: > 200 строк, дублирует AGENTS.md). Учит и тому что **не повторять**.
- `examples/client-office/office/agents/director/core.md` — чистый Director как Chief of Staff. Используй как target template.
- `office/protocols/DATA-ROUTING.md`, `office/protocols/GOVERNANCE.md` — действующие протоколы.

**Внешние:**
- [Anthropic — Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) (orchestrator-worker pattern)
- [Anthropic — Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (parallelism, decomposition)
- [LangGraph supervisor](https://docs.langchain.com/oss/python/langchain/multi-agent/handoffs)
- [OpenAI Swarm](https://github.com/openai/swarm) (handoff = tool_call)
- [Harrison Chase — Cognitive Architecture](https://blog.langchain.com/what-is-a-cognitive-architecture/)

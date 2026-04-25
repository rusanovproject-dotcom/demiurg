# Handoff Library — Готовые yaml-шаблоны передачи задач

Handoff = tool_call с task_brief, не «передача контекста». Без `expected_output` и `boundaries` теряется 30-40% контекста (Anthropic). Эта библиотека — **готовые шаблоны** для всех типов handoff'ов в офисе.

**Когда использовать:** при создании любого нового агента — Демиург выбирает 1-2 шаблона из этой библиотеки и встраивает в CLAUDE.md агента (раздел «Связки»).

**Источники:** ext research S8 (OpenAI Swarm / LangGraph / Anthropic «detailed task descriptions»), `office/protocols/DATA-ROUTING.md`.

---

## Базовая структура (минимум полей)

```yaml
handoff:
  from: {agent_id}
  to: {agent_id}
  objective: <1-2 sentence goal>
  context:
    - {fact or reference path}
  expected_output:
    format: <markdown | json | yaml | code | image>
    contains: [список обязательных элементов]
  boundaries:
    do_not: [список запретов]
  tools_guidance: <какие tools использовать, какие избегать>
  deadline: <optional>
  escalate_if: <условие → передать человеку>
```

**Обязательные поля:** `from`, `to`, `objective`, `expected_output.format`, `boundaries.do_not`.

**Все остальные** — опциональные, но **`expected_output.contains`** дополняет format и резко повышает качество.

---

## Шаблон 1: Director → Specialist (стандартный)

Самый частый случай. Director классифицировал задачу и передаёт одному specialist'у.

```yaml
from: Director
to: Copywriter
objective: написать продающий пост про оффер v6 для канала
context:
  - offer: hub/product/offer-v6.md
  - audience: knowledge/audience/pains.md
  - brand_voice: knowledge/brand/voice.md
  - past_examples: knowledge/case-studies/successful-posts/
expected_output:
  format: markdown
  contains:
    - hook (≤2 предложения)
    - story / personal moment
    - mechanism / why this works
    - CTA с конкретным действием
  length: 800-1200 words
boundaries:
  do_not:
    - упоминать конкурентов по имени
    - использовать AI-слоп (инновационный, революционный, синергия)
    - давать гарантий результата без оснований
  validation: пройти Equalizer (жирность оффера ≥ 8/10)
tools_guidance:
  use: [Read, WebSearch — для свежих данных по теме]
  avoid: [Bash, deploy tools]
deadline: до конца дня
escalate_if: brand_voice или audience pains файлы отсутствуют
```

---

## Шаблон 2: Director → Параллельный fan-out

Когда задача распадается на независимые куски.

```yaml
from: Director
parallel: true
tasks:
  - to: Intelligence
    objective: разведка конкурентов в нише X за последние 30 дней
    expected_output:
      format: markdown
      contains: [топ-5 конкурентов, их офферы, цены, отличия]
    boundaries:
      do_not: [плагиатить тексты]
  - to: Copywriter
    objective: первый драфт продающего поста
    context:
      - audience: knowledge/audience/pains.md
    expected_output:
      format: markdown
      contains: [hook, story, CTA]
  - to: Designer
    objective: 3 варианта обложки канала под кампанию
    context:
      - brand_book: knowledge/brand/brand-book.md
    expected_output:
      format: image_prompts | image_files
      contains: [3 варианта в едином стиле]
synthesis_by: Director
synthesis_rule: дождаться все 3 → собрать в `outputs/campaign-X/` → показать Хозяину
```

---

## Шаблон 3: Specialist → Specialist (peer-to-peer, разрешён только для 2 связанных)

Прямой handoff между двумя ролями где постоянная связка. Должен быть прописан **в обоих CLAUDE.md** с обоснованием.

```yaml
from: Copywriter
to: Equalizer
objective: ревью жирности оффера
context:
  - draft: outputs/offer-v6-draft.md
expected_output:
  format: markdown
  contains:
    - score по 12 критериям Hormozi
    - конкретные правки строка-в-строку
    - вердикт PASS/NEEDS WORK/FAIL
boundaries:
  do_not: [переписывать заново — только правки на драфт]
mesh_justification: copywriter и equalizer работают в постоянной связке writer/reviewer, прямой handoff экономит 1 цикл через Director
```

---

## Шаблон 4: Specialist → Director (report-back)

После завершения работы — отчёт обратно.

```yaml
from: Copywriter
to: Director
task_id: <task notion id или ссылка>
status: done | needs_review | blocked | failed
deliverables:
  - outputs/post-v6-draft.md
issues: []
metrics:
  time_spent: 25 min
  iterations: 1
next_step_suggestion: передай Equalizer на проверку жирности
```

Если `status: blocked`:
```yaml
status: blocked
blocker:
  type: missing_data | tool_failure | unclear_brief | escalation_needed
  detail: brand_voice.md отсутствует, не могу подобрать тон
  suggested_action: запустить /interview с Хозяином по tone-of-voice
```

---

## Шаблон 5: Human → Director (intake)

Свободный текст от Хозяина или клиента. Director классифицирует.

```
Хозяин: "надо переписать лендинг"
↓
Director: классификация
- Tier: 2 (контент)
- Проект: Project X
- Агент: Frontend Designer
- Статус: A+ Task ещё открыта → лендинг в бэклог
↓
Director: ответ + Notion entry
```

**Если задача размытая** (одно предложение, нет деталей) — Director запускает `/interview`.

---

## Шаблон 6: Director → Subagent (внутри одной фазы)

Демиург спавнит Researcher или Builder для тяжёлой изолированной работы.

```yaml
from: Demiurg
to: subagent_general_purpose
isolation: true  # subagent работает в собственном context window
prompt_inline: |
  Тебе передан промт от агента {researcher|builder|validator}.
  Прочитай этот файл: {path}
  Выполни задачу: {task}
  Верни результат в формате: {format}
expected_output:
  format: markdown_report
  saved_to: knowledge/{agent}/INDEX.md
context_pack:
  files:
    - knowledge/architecture/agent-design.md
    - knowledge/examples/{closest-type}.md
  scout_dossier_path: ~/workspace/knowledge/scout/{domain}-{date}.md
limits:
  max_tools_calls: 50
  max_duration_min: 15
  max_subagent_depth: 0  # этот subagent НЕ может спавнить ещё
```

---

## Шаблон 7: Cron / Background → Director

Ночная команда, scheduled tasks, Atlas notifications.

```yaml
from: cron-night-crew
to: Director
trigger: scheduled | event_based
event_data:
  type: notion_task_created | new_email | telegram_message
  payload: {...}
processing_rule:
  - if event.type == "notion_task_created" and tier == 1:
      action: notify_immediately
  - if event.type == "new_email" and from_known_lead:
      action: route_to_hermes
  - else:
      action: queue_for_morning_triage
```

---

## Шаблон 8: Demiurg → Validator (build pipeline)

Валидация после Build-фазы.

```yaml
from: Demiurg
to: Validator
objective: проверить нового агента {agent_name}
context:
  - agent_dir: office/agents/{name}/
  - brief: state.json brief
  - intake_answers: state.json intake
expected_output:
  format: validator_report.json
  contains:
    - score: 0-100
    - verdict: PASS | NEEDS_WORK | FAIL
    - issues: array of {severity, category, file, line, suggestion}
    - blocks_score: {claude_md, skills, knowledge, connections, character}
boundaries:
  do_not: [править файлы — только отчитываться]
escalate_if: validate-agent.sh не запускается
```

---

## Anti-patterns (как НЕ делать handoff)

| Анти-паттерн | Почему плохо |
|--------------|--------------|
| `objective: помоги с лендингом` | Vague. Specialist додумывает что именно. |
| Нет `expected_output.format` | Возврат в произвольной форме, Director не сможет синтезировать |
| Нет `boundaries.do_not` | Specialist может выйти за зону, дублировать другого |
| `context: [knowledge/]` без конкретных файлов | Specialist грузит всё подряд, контекст разбухает |
| Handoff в 5 разных мест по одной задаче | Дробление, координационный overhead. Нужно 1 главный handoff + параллельные подзадачи через synthesis_by |
| Specialist отправляет результат напрямую Хозяину минуя Director | Director теряет visibility, не может синтезировать |

---

## Validation: Demiurg при Wire-фазе

После создания нового агента Demiurg проверяет handoff'ы:

1. Все `from` / `to` ссылаются на существующих в `AGENTS.md` агентов
2. Все `context` файлы существуют (через расширенный validate-agent.sh)
3. Все `expected_output.format` принадлежат к допустимому набору (markdown / json / yaml / code / image / report)
4. Если handoff peer-to-peer — обоснование `mesh_justification` обязательно
5. Парный handoff: если в Copywriter есть → Equalizer, в Equalizer должен быть ← Copywriter

(вынести в `scripts/wire-check.sh` — phase 2 средний путь)

---

## Quick reference card

Для быстрого использования при сборке агента:

```
ВСЕГДА:    objective, expected_output.format, boundaries.do_not
ОБЫЧНО:    context, expected_output.contains, deadline
ИНОГДА:    tools_guidance, escalate_if, parallel
РЕДКО:     synthesis_by (для fan-out), mesh_justification (для peer-to-peer)
```

---

## Эталоны

- `office/CLAUDE.md` секция «Handoff» — короткая yaml-форма (from/to/task/why/output)
- `office/CLAUDE.md` секция «Sales Meetings» — handoff пример с параллельным fan-out (3 агента → синтез Director'ом)
- `examples/client-office/office/agents/director/core.md` секция «Output contract» — 5 типов ответа Director
- `office/protocols/DATA-ROUTING.md`

# Mixed-офис — пример структуры

Mixed-офис = **marketing + client + product одновременно**. Самый сложный паттерн. Главная опасность — **пересечение зон** между marketing- и sales-агентами. Главный спасатель — **pod-decomposition**: > 8 агентов разбивай на под-команды со своими Director-lite.

**Источники:** ext research A2 (Anthropic 4×4 > 1×8), B3 (hierarchical teams), обезличенный пример офиса с 17 агентами.

---

## Главная опасность: пересечение зон (role overlap)

Конкретные места где mixed-офис ломается:

### 1. Copywriter marketing vs copywriter sales
Пишут разное. Если **один и тот же агент** — на выходе:
- Продающий пост превращается в рекламу (формат marketing)
- Рекламный — в продающий (формат sales)
- Тон смешивается, CTR падает

**Решение:** разные агенты ИЛИ один агент + два скилла (`/post-marketing`, `/kp-sales`). У Хозяина сейчас Copywriter + скилл `/kp` (отдельный).

### 2. Intelligence market vs intelligence client
Разные задачи, разные источники, разный output:
- **Market intel** — тренды индустрии, конкурентный обзор, общие сигналы
- **Client intel** — конкретная компания/человек, news monitoring по аккаунту

Если один агент — контекст смешивается, качество падает.

**Решение:** один Intelligence-агент + два скилла, или два под-агента в разных pod'ах (marketing-pod / client-pod).

### 3. Director marketing vs Director client vs Director product
Если **один Director делает всё**, он перегружен, делегирует хаотично, теряет revenue tier фокус.

**Решение:** **Pod-структура.** 3-4 Director-lite (marketing-pod-lead, client-pod-lead, product-pod-lead, ops-pod-lead) под Top-Director'ом. Top = CEO-level (для Хозяина — Director).

### 4. Память — три разных namespace
- **Marketing memory** — что постили, что работало, brand evolution
- **Client memory** — что знаем о клиенте, deal history, contacts
- **Product memory** — архитектурные решения, deploy history

Одна общая память = mass confusion. Три разных `archival/` namespace минимум.

---

## Правило ≥ 8 агентов = pod-decomposition обязательна

Anthropic case (C compiler): 2 команды по 4 **ВСЕГДА** превосходили одну команду из 8.

```
> 8 агентов
       ↓
   3-4 pod'а
       ↓
[marketing-pod]  [client-pod]  [product-pod]  [ops-pod]
   pod-lead       pod-lead       pod-lead       pod-lead
   3-4 spec.      3-4 spec.      3-4 spec.      2-3 spec.
       ↓             ↓              ↓              ↓
              [Top-Director / CEO]
                       ↓
                  [Человек]
```

### Структура pod'а

```
office/pods/{name}/
  CLAUDE.md          # Pod-lead identity (Director-lite)
  AGENTS.md          # Список pod-specialists (3-5 max)
  context.md         # Pod-level state (ТОП-3 приоритета этого pod'а)
  ops/               # Pod-level логи
  agents/
    {pod-lead}/      # CLAUDE.md + memory + skills
    {specialist-1}/
    {specialist-2}/
  knowledge/         # Pod-specific (если есть)
```

### Связи между pod'ами

**Default — через Top-Director.** Прямые связи pod-to-pod (marketing-pod → client-pod handoff) разрешены только для **2 связанных pod'ов** с явной yaml-ссылкой в обоих pod-CLAUDE.md.

Пример прямой связи: launch campaign — marketing-pod закончил кампанию → client-pod получает warm leads → handoff с лидами и attribution.

---

## Пример: офис с 17 агентами

Текущие 17 агентов разбиваются на pod'ы по revenue tier:

| Pod | Агенты | Зона |
|-----|--------|------|
| **Top** | Director | Координация всех pod'ов, ритуалы дня |
| **Sales-pod** | Producer, Equalizer, Account Executive | Tier 1 — оффер, КП, закрытие сделок |
| **Marketing-pod** | Copywriter, Designer, Intelligence, SEO, Videographer | Tier 2 — контент, прогрев, каналы |
| **Product-pod** | Tech Lead, Frontend Designer, Vibe Coder | Tier 3 — клиентский продукт, платформа, AI-офис |
| **Ops-pod** | Methodologist, Data Architect, Knowledge Curator, Researcher, Demiurg | Tier 4 — методология, knowledge, архитектура |

Каждый pod имеет своего pod-lead (для marketing — Producer; для product — Tech Lead) или ad-hoc координацию.

### Что улучшить в этом офисе

Текущая ситуация: Director роутит на 17 агентов напрямую. Это нарушает **Anthropic 4×4 > 1×8**.

Будущее: Director роутит на 4 pod-leads, pod-leads — на специалистов внутри pod'а. Director видит **4 «отчёта»** в день, не 17.

---

## Главные риски в mixed-офисе

### Риск 1: Director'у скинули всё
Симптом: Director в context.md держит 17 параллельных задач, постоянно теряет фокус.
Лечение: pod-decomposition + правило «Top-Director видит только pod-level статусы, не индивидуальные».

### Риск 2: Дрейф зон между pod'ами
Симптом: copywriter в marketing-pod пишет КП (зона sales-pod) → дублирование.
Лечение: explicit boundaries в каждом pod-AGENTS.md + overlap-monitoring (Validator проверяет % similarity между описаниями).

### Риск 3: Один артефакт нужен 3 pod'ам
Симптом: «лендинг» — это marketing (содержание + дизайн) + sales (КП-блоки) + product (deploy).
Лечение: **главный pod-владелец** (для лендинга — marketing) + handoff'ы остальным.

### Риск 4: Kросс-pod scaling
Симптом: добавили 5-го агента в marketing-pod — pod-lead перегружен.
Лечение: правило «pod ≤ 4 specialists» строгое. Если больше — split на под-pod'ы (под-marketing → content + ads + design).

### Риск 5: Top-Director знает слишком мало
Симптом: Director принимает решения не зная контекст pod'а → плохой роутинг.
Лечение: pod-leads присылают Director weekly digest (что сделано / что в работе / что нужно от Top), не каждое движение.

---

## Cyborg / Centaur / Self-Automator (тип владельца офиса)

[Mollick HBS 2024](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4921696): три паттерна работы человека с AI.

| Паттерн | Описание | Mixed-офис как |
|---------|----------|----------------|
| **Centaur** | Делегирует пачками (чёткая граница) | Pod-leads автономны, weekly check-in |
| **Cyborg** | Переплетает действия ход-в-ход | Top-Director всегда в петле, pod-leads просят approval часто |
| **Self-automator** | Отдаёт полностью | Не подходит для mixed (теряется контроль) |

**Хозяин — между Cyborg и Centaur** (по моим наблюдениям). Mixed-офис должен поддерживать оба режима: pod-leads автономны (centaur), но Top-Director всегда видит pulse (cyborg).

---

## Memory особенности mixed-офиса

### Top-level memory (CEO / Director)
```
office/
  context.md              # Pulse дня по всем pod'ам (≤50 строк)
  ops/
    weekly-digests/       # Pod-level отчёты
    decisions/            # Cross-pod решения
  agents/director/
    memory.md             # Решения Director как координатора
    failures.md           # Ошибки роутинга на pod-level
```

### Pod-level memory
Каждый pod имеет **своё** `context.md` + `ops/` + по-агенту memory. Pod-lead агрегирует в weekly digest для Top.

### Cross-pod знания
- `office/knowledge/` — общая база (brand, audience, methodology)
- `office/protocols/` — правила взаимодействия pod'ов
- `office/registry/` — реестр всех pod'ов и агентов с ссылками

---

## Pipeline и Skills для mixed-офиса

Кросс-pod скиллы которые есть у Хозяина:

- `/morning` — Top-Director начинает день, агрегирует pod-level планы
- `/evening` — Top-Director закрывает день, агрегирует pod-level итоги
- `/triage` — разбор inbox через Revenue Filter (pod-aware)
- `/sales-debrief` — кросс-pod (sales + marketing для follow-up content)
- `/diagnostic-pitch` — кросс-pod (sales-pod готовит, marketing-pod упаковывает визуал)

Эти скиллы **обязательны** для mixed-офиса — без них Top-Director превращается в человека-маршрутизатора.

---

## Decision tree: какой тип офиса строить?

```
Один домен? (только marketing / только sales / только dev)
  → ОДНОТИПНЫЙ ОФИС (см. office-types/{marketing,client}.md или dev pattern)

Два домена + ≤ 5 агентов?
  → SIMPLE MIXED (один Top-Director + flat структура)

Два-три домена + > 5 агентов?
  → POD-DECOMPOSED MIXED (Top-Director + 2-3 pod'а)
  
Все три домена + > 8 агентов?
  → ENTERPRISE MIXED (Top-Director + 3-4 pod'а + cross-pod скиллы)
```

---

## Anti-patterns в mixed-офисах

| Анти-паттерн | Почему плохо |
|--------------|--------------|
| Один Director роутит на 10+ агентов | Anthropic case: 2×4 > 1×8 всегда |
| Universal copywriter (marketing + sales) | Тон смешивается, CTR падает |
| Общая память для marketing + client + product | Confusion, неправильные фактики |
| Pod без своего context.md | Top-Director несёт всё, перегруз |
| Прямой handoff pod-to-pod без yaml-ссылок в обоих | Хрупкие связи, не отлаживается |
| Все pod-leads — копии Director (без специализации) | Бесполезный слой иерархии |
| > 4 specialists в одном pod | Перегруз pod-lead, нужен под-pod |

---

## Эталоны

**Внутренние:**
- Этот обезличенный пример показывает mixed-офис на 17 агентов, которому нужна pod-decomposition
- Top-Director в примере превышает 200 строк; при разделении на pod его нужно сжать

**Внешние:**
- [Anthropic — 2 команды по 4 > 1 команды из 8](https://www.anthropic.com/engineering/multi-agent-research-system)
- [LangGraph hierarchical teams](https://langgraphjs.guide/multi-agent/)
- [Mollick — Cyborgs, Centaurs, Self-Automators](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4921696)

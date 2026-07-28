# Паттерны командной работы агентов

> Из: CrewAI docs, LangGraph tutorials, Anthropic case studies, Cole Medin, Habr
> Март 2026

---

## Паттерн 1: Pipeline (Конвейер)

```
Agent 1 → Agent 2 → Agent 3 → Agent 4 → Output
(Research)  (Plan)   (Execute)  (Review)
```

**Когда:** Задача с чёткими последовательными фазами.
**Примеры:** Контент (research → write → edit → publish), код (plan → implement → test → review).
**Плюсы:** Простой, предсказуемый, легко отладить.
**Минусы:** Нет параллелизма, ошибка одного ломает весь pipeline.
**Оптимально:** 3-6 шагов в pipeline.

**Ключевое правило:** Между фазами передавай не просто результат, но и контекст решений.

---

## Паттерн 2: Parallel (Параллельный)

```
        ┌── Agent A ──┐
Input ──├── Agent B ──├── Aggregator → Output
        └── Agent C ──┘
```

**Когда:** Независимые подзадачи.
**Примеры:** Исследование (3 источника параллельно), мультиканальный контент (LinkedIn + X + Instagram).
**Плюсы:** Быстро (3x speedup), эффективно для независимых задач.
**Минусы:** Нужен хороший aggregator, результаты могут конфликтовать.
**Оптимально:** 2-5 параллельных агентов.

**Ключевое правило:** Используй ТОЛЬКО если задачи полностью независимы.

---

## Паттерн 3: Orchestrator-Worker (Оркестратор)

```
         Orchestrator
        / |  |  |  \
      W1  W2  W3  W4  W5
        \ |  |  |  /
         Aggregator
```

**Когда:** Сложные задачи с динамическим распределением.
**Примеры:** Разработка фичи (orchestrator разбивает на backend, frontend, tests, docs).
**Плюсы:** Масштабируется, параллелизм, fault tolerance.
**Минусы:** Orchestrator = single point of failure, сложнее настроить.
**Оптимально:** 3-8 workers.

**Enterprise standard по данным Hatchworks (март 2026).**

---

## Паттерн 4: Dispatcher (Маршрутизатор)

```
Input → Router → Agent 1 (billing)
              → Agent 2 (tech support)
              → Agent 3 (sales)
```

**Когда:** Разные типы запросов → разные специалисты.
**Примеры:** Customer support, task routing, multi-domain processing.
**Плюсы:** Специализация, быстрое выполнение (один агент на задачу).
**Минусы:** Router может ошибиться в классификации.
**Оптимально:** 3-7 категорий.

---

## Паттерн 5: Hierarchical (Иерархический)

```
         Supervisor
         /       \
    Team Lead A   Team Lead B
    / | \          / | \
  W1 W2 W3      W4 W5 W6
```

**Когда:** Большие команды (8+ агентов), разные доменные области.
**Примеры:** Enterprise: Engineering Lab + Content Lab + Operations Lab.
**Плюсы:** Масштабируется, каждый уровень контролирует свой scope.
**Минусы:** Overhead координации, latency.
**Оптимально:** 2-3 уровня максимум.

**LangGraph официально поддерживает через Hierarchical Agent Teams.**

---

## Паттерн 6: Swarm (Рой)

```
A ←→ B
↑    ↓
D ←→ C
```

**Когда:** Творческие задачи, brainstorm, исследования.
**Примеры:** Debate между агентами, генерация идей, multi-perspective analysis.
**Плюсы:** Emergent coordination, разнообразие точек зрения.
**Минусы:** Непредсказуемо, может быть дорого по токенам.
**Оптимально:** 3-5 агентов, с ограничением на число раундов.

---

## Выбор паттерна: Decision Matrix

| Характеристика задачи | Паттерн |
|------------------------|---------|
| Последовательные шаги | Pipeline |
| Независимые подзадачи | Parallel |
| Сложная, нужна декомпозиция | Orchestrator-Worker |
| Разные типы запросов | Dispatcher |
| Большая команда, разные домены | Hierarchical |
| Творческая, нужны идеи | Swarm |
| Простая (<30 мин) | Один агент, без паттерна |

---

## Готовые команды по задачам

### Команда: Software Development
```
Architect Agent → проектирует архитектуру, API contracts
Backend Agent → пишет основной код
Frontend Agent → если нужен UI
Test Agent → пишет тесты
DevOps Agent → настраивает deployment
Reviewer Agent → финальная проверка
```
**Паттерн:** Pipeline (Architect → Backend/Frontend parallel → Test → Review)
**Время:** 30-90 минут от идеи до deploy-ready code
**ROI:** 3-4x speedup vs single agent

### Команда: Content Creation
```
Research Agent → поиск информации, тренды, статистика
Strategy Agent → структура, tone, angle
Writer Agents × 3 → параллельно пишут разный контент
Fact Checker → проверяет данные
Editor → стиль, читаемость
```
**Паттерн:** Research → Strategy → Parallel Writers → Editor
**Время:** 1 неделя контента за 15-60 минут
**ROI:** Стоимость ~$8, экономия 20+ часов

### Команда: Research & Analysis
```
Web Researcher → поиск в открытых источниках
Data Analyst → работа с данными, статистикой
Pattern Recognizer → связывает инсайты, находит patterns
Synthesizer → пишет итоговый report
```
**Паттерн:** Parallel (Web + Data + Pattern) → Synthesizer
**Время:** 1-3 часа для глубокого анализа
**ROI:** Качество инсайтов значительно выше чем от одного агента

### Команда: AI Office (Operations)
```
AI Director → координация всех отделов
Task Router → маршрутизация задач
Code Agent → coding tasks
Content Agent → writing tasks
Operations Agent → automation tasks
Quality Reviewer → проверка результатов
```
**Паттерн:** Dispatcher (Director → Router → Specialists) + Reviewer
**Время:** Постоянно работает
**ROI:** 3-5x productivity для рутинных задач

---

## Фреймворки: когда какой

| Задача | CrewAI | LangGraph | Claude Code Teams |
|--------|--------|-----------|-------------------|
| Быстрый MVP | Best | OK | OK |
| Production с контролем | OK | Best | Good |
| Role-based абстракция | Best | OK | Good |
| Compliance/Enterprise | OK | Best | Good |
| Coding tasks | OK | Good | Best |
| Content tasks | Best | OK | Good |

**CrewAI:** 45.9k ⭐ GitHub, 100K+ разработчиков. Быстрый старт, YAML-first.
**LangGraph:** 26.3k ⭐, v1.1.2 март 2026. Максимальный контроль, graph-based.
**Claude Code Teams:** Нативно в Claude Code. Лучший для coding задач.

---

## Масштабирование: от 1 до 50+ агентов

### Level 1: Solo (1-3 агента)
```
You → Task → Code Agent → Result
              Test Agent ↗
```
Setup: 1-2 дня. ROI: +160% productivity.

### Level 2: Team (5-10 агентов)
```
Slack → Router → Backend Team (3)
              → Frontend Team (3)
              → Support (2)
```
Setup: 2-4 недели. ROI: +3x productivity, -60% cost per feature.

### Level 3: Enterprise (50+ агентов)
```
Director → Engineering Lab → Code, Test, Deploy, Monitor
        → Content Lab → Write, Design, Marketing
        → Operations Lab → Automation, Reporting
        → Governance → Security, Compliance, Audit
```
Setup: 2-3 месяца. ROI: +3.5x productivity, -20% cost, +quality.

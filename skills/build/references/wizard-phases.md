# Wizard Phases — TEAM режим (7+2 фаз)

Детали каждой фазы для режима TEAM. Ядро: `../SKILL.md`

## Прогресс-бар (показывай перед КАЖДОЙ фазой)

```
[=>        ] Фаза 1/7: Intake
[==>       ] Фаза 2/7: Blueprint
[===>      ] Фаза 3/7: Team Design
[====>     ] Фаза 3.5/7: Data Audit (Knowledge Mining)
[=====>    ] Фаза 4/7: Agent Creation (Build + Validate per agent)
[======>   ] Фаза 5/7: Wiring + Grand Reveal
[=======>  ] Фаза 5.5/7: Soul Layer (Creator)
[========> ] Фаза 6/7: Onboarding
[==========] Готово!
```

## Фаза 1 — INTAKE

Цель: понять что строим, для кого, какие ресурсы.

1. Проверь `demiurg-state.json` — есть checkpoint? Предложи продолжить.
2. Сканируй workspace: `find <ws> -name "CLAUDE.md" | head -20`
3. Задай 3-5 вопросов:
   - Какие проекты активные?
   - Кто работает? (solo / команда / клиенты)
   - Стек и деплой?
   - Что НЕ трогать?
   - Планируются ли агенты-боты в Telegram? (нет ответа → рантайм всех агентов
     по умолчанию = субагент Claude Code)

4. Checkpoint → `demiurg-state.json`

## Фаза 2 — BLUEPRINT

Цель: физическая структура папок.

1. Прочитай `knowledge/architecture/folder-patterns.md`
2. Выбери паттерн (solo / small-team / full-office)
3. Покажи дерево → жди ОК
4. `bash scripts/scaffold.sh <target-dir> <pattern>`

## Фаза 3 — TEAM DESIGN

Цель: состав, роли, зоны ответственности.

Составь таблицу:
| Агент | Роль | Читает | НЕ читает | Решает сам | Эскалирует |

Определи связи (кто → кому). Нет циклов!

## Фаза 3.5 — KNOWLEDGE MINING (НОВОЕ!)

**Заменяет старый Data Audit.** Теперь не просто оцениваем — СОБИРАЕМ знания.

Для КАЖДОГО агента из Фазы 3:
1. Запусти Knowledge Miner (`agents/knowledge-miner.md`)
2. Miner сканирует workspace → создаёт `knowledge/{agent}/`
3. Score < 5 = БЛОКЕР → собери данные (интервью, анализ текстов, веб)
4. Score ≥ 5 → агент готов к сборке

Это КЛЮЧЕВОЕ отличие от старого процесса. Без знаний = пустышка.

## Фаза 4 — AGENT CREATION

Для каждого агента ИЗ ТАБЛИЦЫ Фазы 3 (порядок: Director → основные → вспомогательные):

1. Brief из таблицы
2. Knowledge уже собраны (Фаза 3.5)
3. Builder создаёт CLAUDE.md + skills/
4. validate-agent.sh → Validator
5. Score < 80 → Refiner → re-validate (макс 2 раунда)
6. Behavior-eval (smoke + discovery + recall, `references/behavior-eval.md`) + обёртка
   `.claude/agents/<name>.md` — цикл на агента тот же, что в SINGLE (scout/adopt — Фаза 3.5)

## Фаза 5 — WIRING + GRAND REVEAL

1. AGENTS.md — карта агентов
2. context.md — текущий snapshot (≤50 строк)
3. knowledge/INDEX.md — навигация
4. DRY-RUN: 3 сценария из проектов пользователя
5. Grand Reveal: красивый финал с таблицей и примерами

## Фаза 5.5 — SOUL LAYER

Creator (внешний спец Хозяина; в паке нет — фаза Soul опциональна без него) добавляет:
- `office-identity/philosophy.md` — миссия + ценности
- `office-identity/voice-guide.md` — тон офиса
- `## Характер` в каждый CLAUDE.md (5-8 строк)
- Проверка антиклона: все архетипы уникальны

Можно пропустить если пользователь скажет "без характеров".

## Фаза 6 — ONBOARDING

1. `quick-start.md` (≤20 строк, 3 шага)
2. `user-guide.md` (5 сценариев "Хочу X → скажи Y")
3. First Contact в Director
4. Office Tour

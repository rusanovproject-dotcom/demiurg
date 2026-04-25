# Quality Gates — Критерии перехода

## Ядро процесса (каждый агент)

| Этап | Условие перехода | Блокер? |
|------|-----------------|---------|
| Brief → Knowledge | Brief: роль + задачи + связи | Да |
| Knowledge → Build | Miner score ≥ 5 по 5 критериям | Да (score < 5 = СТОП) |
| Build → Validate | validate-agent.sh PASS (0 errors) | Да |
| Validate → Done | Validator score ≥ 80/100 | Нет (iterate) |
| Iterate | Макс 2 раунда, delta < 5 → стоп | Hardcoded |

## Knowledge Miner scoring

| Критерий | 0-10 |
|----------|------|
| Объём | ≥3 реальных источника |
| Глубина | Содержательные, не пустые |
| Примеры | ≥2 реальных примера работы |
| Специфичность | Для ЭТОГО агента, не общие |
| Актуальность | Данные актуальны |

**Avg < 5 = БЛОКЕР.** Нужно: интервью (15 мин), анализ текстов, веб-поиск.

## Validator scoring (5 блоков, 100 баллов)

| Блок | Макс | Что проверяем |
|------|------|---------------|
| CLAUDE.md | 30 | Существует, ≤150 строк, identity ≤300 tok, frontmatter, зоны, self-check, output contract, примеры, нет слопа |
| Скиллы | 20 | SKILL.md, triggers, вход→шаги→выход, ≤100 строк |
| Knowledge | 20 | Ссылки валидны, реальный контент, INDEX.md |
| Связность | 15 | Нет дублей, handoff корректны, нет circular |
| Характер | 15 | Архетип, фразы-маркеры, "никогда не скажет" |

| Score | Вердикт |
|-------|---------|
| ≥ 80 | PASS |
| 60-79 | NEEDS WORK → Refiner |
| < 60 | FAIL → пересобрать |

## TEAM mode — системные проверки

| Переход | Условие |
|---------|---------|
| Intake → Blueprint | ≥3 ответа, паттерн определён |
| Blueprint → Team | scaffold выполнен, tree показан |
| Team → Knowledge Mining | Таблица утверждена, нет пересечений |
| Knowledge → Build | ВСЕ агенты Miner score ≥ 5 |
| Build → Wiring | Все агенты Validator ≥ 80 |
| Wiring → Soul | DRY-RUN 3/3 pass |
| Soul → Onboarding | Антиклон pass, характеры утверждены |
| Onboarding → Complete | quick-start + user-guide + First Contact |

## Judge scoring (система целиком, 5 осей 0-10)

| Ось | Что оцениваем |
|-----|--------------|
| Навигация | Агент найдёт файл за ≤2 шага? |
| Экономия | Нет лишнего? Identity ≤300 tok? |
| Связность | Все ссылки валидны? |
| Единственность | Один факт = одно место? |
| Ясность | Понятно с первого прочтения? |

Score ≥ 8 → PASS. Score < 8 → Refiner. Макс 3 раунда.

## Стоп-краны

- Макс 10 агентов (>7 warning)
- Макс 2 iterate на агента
- Макс 3 review-refine на систему
- Delta < 0.5 между раундами → стоп
- >70% контекста → checkpoint + /clear

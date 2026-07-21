# Demiurg Knowledge Base — Индекс

## architecture/ — Архитектура систем
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `agent-design.md` | Шаблон CLAUDE.md + обёртка-регистрация `.claude/agents/` + антипаттерны | Создание агента (self-trigger) |
| `memory-architecture.md` | Канон памяти 2026-07-20: рантайм → трёхконтурная модель → лимиты | Проектирование памяти (self-trigger) |
| `ideal-agent-anatomy.md` | Эталон готового агента: 5 слоёв, уникальность, финальный чеклист | ПЕРЕД каждой сборкой |
| `agent-lifecycle.md` | Добавить/изменить/удалить агента, обёртка + gate вызова, масштабирование | При изменении команды |
| `office-blueprint.md` | Проектирование офиса целиком, слои файлов агента | Проектирование офиса (self-trigger) |
| `office-types/{client,marketing,mixed}.md` | Специфика 3 типов офисов | Вместе с office-blueprint |
| `director-cookbook.md` | Проектирование Director'а | Проектирование Director (self-trigger) |
| `handoff-library.md` | 8 yaml-шаблонов передачи + протокол исполнения/эскалации + anti-patterns | Handoff между агентами (self-trigger) |
| `routing-patterns.md` | Классификация → маршрутизация → возврат, hub-and-spoke | Проектирование роутинга |
| `context-strategies.md` | Write/Select/Compress + чеклист контекста агента | Дизайн контекста |
| `context-patterns.md` | Handle, Summary, Specialist, Progressive Disclosure | Дизайн команды |
| `knowledge-ownership.md` | Общий vs частный knowledge, decision tree | При создании knowledge/ |
| `data-packs.md` | Наборы данных для 8 типов агентов | ПЕРЕД сборкой агента |
| `component-checklists.md` | Глубокая проверка по слоям | Фаза Review |
| `checklist-state.md` | Формат demiurg-state.json по фазам | Начало wizard'а |
| `folder-patterns.md` | 3 паттерна: solo / small-team / full-office | Выбор структуры |
| `migration-protocol.md` | Миграция между паттернами | При масштабировании офиса |

## skill-mastery/ — Библия скиллов
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `anatomy.md` | Структура скилла: SKILL.md, frontmatter, 3 уровня загрузки | Создание скилла |
| `writing-guide.md` | Как писать: Why>MUST, примеры>правила, lean | Написание скилла |
| `advanced-patterns.md` | Негация→позитив, worktree, hooks, золотые правила | Фаза Research |
| `evaluation.md` | Оценка качества: 5 осей, рубрика 0-10, флаги | Фаза Review |

## Корневые файлы knowledge/
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `cheat-sheet.md` | ВСЕ правила на одной странице | Вместо загрузки 5 файлов |
| `offer-principles.md` | Принципы офферов | Перед работой с офферами |

## tactics/ — Фишки и тактики
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `context-economy.md` | 8 техник экономии контекста | Оптимизация |
| `debug-playbook.md` | Диагностика + цикл самоотладки | При ошибках |
| `stream-insights.md` | Environment engineering, model routing | Фаза Research |
| `validation.md` | LLM-as-Judge протокол, тесты | Фаза Review |
| `guardrails.md` | Безопасность, лимиты, запреты | При сборке |

## evolving/ — Пополняемое
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `audit-lessons.md` | Уроки прошлых аудитов — ошибки НЕ повторять | ПЕРЕД каждой сборкой |

## examples/ — Живые примеры (few-shot для Builder)
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `copywriter-v1.md` | Контент-агент: стиль inline, anti-slop | BUILD — ближайший по типу |
| `tech-lead-v1.md` | Процессный агент: ТЗ-формат, шаги | BUILD — ближайший по типу |
| `offer-architect-v1.md` | Методология-агент: Хормози, формулы | BUILD — ближайший по типу |
| `wizard-walkthrough.md` | Полный walk-through wizard-сессии | Перед первым wizard'ом |
| `example-solo.md` | Готовый Solo-офис | Показать «как будет» |
| `example-small-team.md` | Готовый Small Team офис | Показать «как будет» |

## templates/ — Шаблоны deliverables
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `office-map.md` | Карта офиса | Фаза 5 (Grand Reveal) |
| `quick-start.md` | 3 шага к первому результату | Фаза 6 (Onboarding) |
| `user-guide.md` | 5 сценариев «Хочу X → скажи Y» | Фаза 6 (Onboarding) |
| `office-passport.md` | Паспорт офиса | Фаза 5 (Grand Reveal) |
| `director-first-contact.md` | Welcome для Director | Фаза 6 (Onboarding) |
| `office-tour.md` | Экскурсия по офису | Фаза 6 (Onboarding) |

## scout/ — Досье внешней разведки
`<домен>-YYYY-MM-DD.md` — выход фазы SCOUT, вход ADOPT (свежесть ≤30 дней).

---

Разгрузка 2026-07-21: `handoff-protocol.md` влит в `handoff-library.md`;
`evolving/{learnings,failures,discoveries}.md` (пустые шаблоны) в архиве
архиве репо-источника (в пак не входят) — канон памяти Демиурга =
корневые `memory.md` / `failures.md`.

_Обновлено: 2026-07-21_

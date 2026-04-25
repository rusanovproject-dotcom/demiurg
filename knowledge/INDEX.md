# Demiurg Knowledge Base — Индекс

## skill-mastery/ — Библия скиллов
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `anatomy.md` | Структура скилла: SKILL.md, frontmatter, 3 уровня загрузки | Создание скилла |
| `writing-guide.md` | Как писать: Why>MUST, примеры>правила, lean, цикл разработки | Написание скилла |
| `advanced-patterns.md` | Лайфхаки: негация→позитив, worktree, hooks, золотые правила | Фаза Research |
| `evaluation.md` | Как оценить качество: 5 осей, рубрика 0-10, красные/зелёные флаги | Фаза Review |

## architecture/ — Архитектура систем
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `folder-patterns.md` | 3 паттерна: solo / small-team / full-office | Выбор структуры |
| `context-patterns.md` | Handle, Summary, Specialist, Progressive Disclosure, Memory | Дизайн команды |
| `agent-design.md` | Шаблон CLAUDE.md + примеры + антипаттерны | Создание агента |
| `checklist-state.md` | Формат demiurg-state.json, схема по фазам | Начало wizard'а |
| `ideal-agent-anatomy.md` | Эталон готового агента: 5 слоёв, уникальность, финальный чеклист | ПЕРЕД каждой сборкой |
| `component-checklists.md` | Глубокая проверка по слоям: CLAUDE(12) Skills(10) Knowledge(8) Связи(7) Memory(5) | Фаза Review |
| `data-packs.md` | Наборы данных для 8 типов агентов (копирайтер, маркетолог, дизайнер...) | ПЕРЕД сборкой агента |
| `handoff-protocol.md` | Формат передачи задач (Task Brief), эскалация, cross-agent | При проектировании связей |
| `knowledge-ownership.md` | Общий vs частный knowledge, decision tree, матрица владения | При создании knowledge/ |
| `agent-lifecycle.md` | Добавить/изменить/удалить/архивировать агента, масштабирование | При изменении команды |
| `migration-protocol.md` | Миграция между паттернами: Solo→Small→Full→Hierarchical | При масштабировании офиса |

## Корневые файлы knowledge/
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `cheat-sheet.md` | ВСЕ правила на одной странице (30 строк) | Вместо загрузки 5 файлов |
| `offer-principles.md` | Принципы офферов: формула, чеклист, антипаттерны, примеры | Перед работой с офферами |

## tactics/ — Фишки и тактики
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `context-economy.md` | 8 техник экономии контекста | Оптимизация |
| `debug-playbook.md` | Диагностика + цикл самоотладки + memory | При ошибках |
| `stream-insights.md` | Environment engineering, model routing, skills-first | Фаза Research |
| `validation.md` | LLM-as-Judge протокол, тесты, Self-Refine | Фаза Review |
| `guardrails.md` | Безопасность, лимиты, запрещённые действия | При сборке |

## evolving/ — Пополняемое (агент дописывает сам)
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `learnings.md` | Что выучил из каждой сборки | Перед новой сборкой |
| `failures.md` | Что НЕ сработало и почему | Перед новой сборкой |
| `discoveries.md` | Новые находки (скиллы, паттерны, инструменты) | Перед новой сборкой |

## examples/ — Живые примеры
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `wizard-walkthrough.md` | Полный walk-through wizard-сессии (коуч, 3 проекта) | Перед первым запуском wizard'а |
| `example-solo.md` | Готовый пример Solo-офиса (разработчик, 3 проекта) | Показать клиенту "как будет" |
| `example-small-team.md` | Готовый пример Small Team офиса (эксперт, 4 проекта) | Показать клиенту "как будет" |

## templates/ — Шаблоны deliverables
| Файл | Описание | Когда загружать |
|------|----------|-----------------|
| `office-map.md` | Карта офиса (схема + таблица "агент / зона / скажи ему") | Фаза 5 (Grand Reveal) |
| `quick-start.md` | 3 шага к первому результату (20 строк) | Фаза 6 (Onboarding) |
| `user-guide.md` | 5 сценариев "Хочу X → скажи Y → получишь Z" | Фаза 6 (Onboarding) |
| `office-passport.md` | Паспорт офиса (метаданные, score, версия) | Фаза 5 (Grand Reveal) |
| `director-first-contact.md` | Welcome-сообщение + Session Start для Director | Фаза 6 (Onboarding) |
| `office-tour.md` | Интерактивная экскурсия по офису (скилл для Director) | Фаза 6 (Onboarding) |

_Обновлено: 2026-03-23_

# Knowledge Routing — Что загружать когда

## ВСЕГДА (перед любой сборкой)

1. `knowledge/architecture/ideal-agent-anatomy.md` — эталон агента
2. `knowledge/evolving/audit-lessons.md` — 8 ошибок НЕ повторять
3. `knowledge/examples/` — реальные работающие агенты (few-shot)

## По этапу

| Этап | Загрузи |
|------|---------|
| Knowledge Mining | `knowledge/architecture/data-packs.md` (по типу агента) |
| Build | `knowledge/architecture/agent-design.md` + `knowledge/skill-mastery/anatomy.md` |
| Validate | `knowledge/architecture/component-checklists.md` + `knowledge/tactics/validation.md` |
| Скилл | `knowledge/skill-mastery/writing-guide.md` + `knowledge/skill-mastery/advanced-patterns.md` |
| Ошибки | `knowledge/tactics/debug-playbook.md` |

## По фазе (TEAM mode)

| Фаза | Загрузи |
|------|---------|
| Intake | `knowledge/architecture/checklist-state.md` |
| Blueprint | `knowledge/architecture/folder-patterns.md` |
| Team Design | `knowledge/architecture/context-patterns.md` |
| Knowledge Mining | `knowledge/architecture/data-packs.md` |
| Wiring | `knowledge/tactics/validation.md` + `knowledge/architecture/component-checklists.md` |
| Soul Layer | Creator: `~/workspace/knowledge/agents/strategic/creator.md` |
| Onboarding | `knowledge/templates/` + `knowledge/architecture/handoff-protocol.md` |

## Examples (few-shot)

```
knowledge/examples/
  copywriter-v1.md      — 562 строки, полная ДНК стиля + anti-slop
  tech-lead-v1.md        — 279 строк, ТЗ для вайбкодера
  offer-architect-v1.md  — 336 строк, Хормози $100M Offers
```

Builder ОБЯЗАН прочитать минимум 1 example перед созданием агента.
Паттерн: найди example ближайший по типу → используй как образец.

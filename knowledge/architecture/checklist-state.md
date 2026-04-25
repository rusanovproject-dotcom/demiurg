# Формат demiurg-state.json

Файл трекинга прогресса wizard'а. Создаётся в рабочей директории
(рядом с папкой куда строим систему).

---

## Полная схема

```json
{
  "version": "1.0",
  "created_at": "2026-03-22T14:00:00Z",
  "updated_at": "2026-03-22T16:30:00Z",

  "current_phase": 3,
  "completed_phases": [1, 2],
  "status": "in_progress",

  "target_dir": "my-office",
  "folder_pattern": "full-office",

  "decisions": {
    "projects": [
      {"name": "my-app", "stack": "Python/FastAPI", "status": "active"},
      {"name": "my-assistant", "stack": "Node.js", "status": "active"},
      {"name": "my-booking", "stack": "Next.js", "status": "keep"}
    ],
    "team_mode": "solo",
    "entry_points": ["telegram", "github", "cowork"],
    "keep_as_is": ["my-booking"],
    "language": "ru"
  },

  "team": [
    {
      "name": "Director",
      "file": "CLAUDE.md",
      "role": "координация, роутинг",
      "reads": ["context.md", "AGENTS.md"],
      "ignores": ["projects/*/src/"],
      "status": "created"
    },
    {
      "name": "CTO",
      "file": "agents/cto.md",
      "role": "код, архитектура, деплой",
      "reads": ["projects/*", "ops/log.md"],
      "ignores": ["knowledge/brand/"],
      "status": "pending"
    }
  ],

  "created_files": [
    "CLAUDE.md",
    "context.md",
    "AGENTS.md",
    "knowledge/INDEX.md"
  ],

  "dry_run_results": {
    "test_1": {"scenario": "обновить лендинг", "result": "pass", "steps": 2},
    "test_2": {"scenario": "пост про мастер-группу", "result": "pass", "steps": 3},
    "test_3": {"scenario": "отчёт за неделю", "result": "fail", "issue": "log.md пуст"}
  },

  "metrics": {
    "start_time": "2026-03-22T14:00:00Z",
    "end_time": "2026-03-22T15:30:00Z",
    "total_files_created": 15,
    "review_rounds": 2,
    "final_score": 8.4
  }
}
```

---

## Поля по фазам

### Фаза 1 (Intake)
Заполняется: `decisions`, `target_dir`
```json
{
  "current_phase": 1,
  "decisions": { "projects": [...], "team_mode": "...", ... }
}
```

### Фаза 2 (Blueprint)
Добавляется: `folder_pattern`, `created_files` (папки и заглушки)
```json
{
  "current_phase": 2,
  "folder_pattern": "small-team",
  "created_files": ["knowledge/INDEX.md", ...]
}
```

### Фаза 3 (Team Design)
Добавляется: `team` (массив агентов)
```json
{
  "current_phase": 3,
  "team": [{ "name": "Director", "role": "...", ... }]
}
```

### Фаза 4 (Agent Creation)
Обновляется: `team[].status` ("pending" → "created"), `created_files`
```json
{
  "current_phase": 4,
  "team": [{ "name": "CTO", "status": "created", ... }]
}
```

### Фаза 5 (Wiring + Verify)
Добавляется: `dry_run_results`, `status: "complete"`
```json
{
  "current_phase": 5,
  "completed_phases": [1, 2, 3, 4, 5],
  "status": "complete",
  "dry_run_results": { ... }
}
```

---

## Правила работы с state

1. **Читай state в начале каждой фазы** — убедись что не потерял контекст
2. **Пиши state в конце каждой фазы** — checkpoint обязателен
3. **Показывай пользователю** "мы на фазе N" при каждом checkpoint'е
4. **Не удаляй данные** из предыдущих фаз — только дополняй
5. **При конфликте** (пользователь хочет вернуться на фазу назад) —
   обнови `current_phase`, но сохрани всё что было создано

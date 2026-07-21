# Субагенты Demiurg — Индекс

Одна строка на файл. Канон «кто когда с какой моделью» — таблица в `skills/build/SKILL.md`
§ Субагенты; детальные спеки — `skills/build/references/subagent-specs.md`.

- `knowledge-miner.md` — сбор знаний из workspace до сборки
- `builder.md` — создание CLAUDE.md + обёртки `.claude/agents/` + skills/
- `validator.md` — проверка агента, score 0-100, блокеры памяти/регистрации
- `refiner.md` — фиксы по issues Validator'а (Iterate)
- `researcher.md` — best practices (TEAM, разведка)
- `auditor.md` — аудит workspace (TEAM, разведка)
- `judge.md` — оценка системы целиком (TEAM, финал)
- `persona-builder.md` — характер/душа агента (пара с interviewer)
- `interviewer.md` — CustDev-интервью Хозяина (пара с persona-builder)

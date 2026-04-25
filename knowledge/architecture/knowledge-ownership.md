# Knowledge Ownership — общий vs частный

Куда класть файл — в общий knowledge или в папку агента?

---

## Правило: один факт = одно место

Если файл нужен 2+ агентам — он ОБЩИЙ (workspace/knowledge/).
Если файл нужен только одному — он ЧАСТНЫЙ (agent/knowledge/).

## Decision Tree

```
Этот файл нужен нескольким агентам?
  ДА → workspace/knowledge/ (общий)
  НЕТ → Это данные специфичные для домена агента?
    ДА → agent/knowledge/domain/ (частный)
    НЕТ → workspace/knowledge/ (общий, на будущее)
```

## Матрица владения

| Тип данных | Уровень | Пример пути |
|-----------|---------|-------------|
| Бренд, позиционирование | Общий | `knowledge/brand/positioning.md` |
| Аудитория, аватары | Общий | `knowledge/audience/avatars.md` |
| Продукт, тарифы | Общий | `knowledge/product/pricing.md` |
| Методология | Общий | `knowledge/methodology/core.md` |
| Конкуренты, тренды | Общий | `knowledge/intel/competitors.md` |
| Style DNA копирайтера | Частный | `copywriter/knowledge/domain/style-dna.md` |
| Стек и архитектура CTO | Частный | `cto/knowledge/domain/stack.md` |
| Брендбук дизайнера | Частный | `designer/knowledge/domain/brandbook.md` |
| Шаблоны скиллов | Частный | `agent/skills/*/references/` |
| Самообучение (learnings) | Частный | `agent/knowledge/evolving/` |

## Частные ссылаются на общие

Агент НЕ копирует общие файлы к себе. Он ССЫЛАЕТСЯ:

```markdown
## Контекст
- Аудитория: `../../knowledge/audience/avatars.md`
- Бренд: `../../knowledge/brand/positioning.md`
- Мой стиль: `knowledge/domain/style-dna.md` (свой)
```

## При сборке (чеклист Demiurg)

1. Определи какие файлы нужны агенту
2. Общие → ссылка из CLAUDE.md, НЕ копия
3. Частные → создай в agent/knowledge/domain/
4. Проверь: `grep` по ключевым фразам — нет ли дубля в workspace/knowledge/
5. Обнови INDEX.md агента

## Кто обновляет

| Файл | Кто обновляет | Триггер |
|------|--------------|---------|
| Общий knowledge | Director или ответственный агент | Новые данные от пользователя |
| INDEX.md | Тот кто добавил файл | Сразу после создания |
| Частный knowledge | Сам агент (evolving/) | После каждой задачи |
| Устаревший файл | Director | Еженедельная ревизия |

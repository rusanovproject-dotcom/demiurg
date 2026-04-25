# Marketing-офис — Best practices состав и особенности

Marketing-офис **не = dev-офис с другими агентами**. У него свои паттерны: brand guidelines как validator, tone-of-voice как linter, performance data как test suite. Creative iteration loops длиннее («brief → draft → critique → polish → publish → measure → learn»).

**Источники:** ext research office-types секция (Jasper / HubSpot / Writer.com), Хозяина практика (Copywriter + Designer + Intelligence уже есть как живые агенты в `office/`), `examples/client-office/office/agents/designer/`.

---

## Стандартный состав (6 ролей)

### 1. Campaign Strategist (Director-lite)
- **Роль:** анализ аудитории, позиционирование, GTM-план, держит карту кампании
- **Output:** campaign brief, audience map, channel mix
- **Аналог в офисе Хозяина:** Producer (частично) + Director'ская функция в marketing-pod

### 2. Copywriter
- **Роль:** тексты, hook'и, заголовки, продающий контент
- **Output:** посты, лонгриды, рассылки, ads, лендинг-copy
- **Уже есть:** `office/agents/copywriter/` — живой
- **Skills:** /hot-trail, /matthew-dicks, /stephen-king, /hormozi (full pipeline)

### 3. Designer
- **Роль:** визуалы, layouts, brand consistency
- **Output:** обложки, баннеры, лендинги (Claude Code артефакты), презентации, dashboards
- **Уже есть:** `office/agents/designer/` + `examples/client-office/office/agents/designer/` (clean version)
- **Инструменты:** Claude Code артефакт (для интерактива), Claude Design (для статики)

### 4. Content Strategist / Planner
- **Роль:** контент-план, SEO-keywords, схема воронки
- **Отличается от Copywriter:** планирует **что** и **когда**, не пишет
- **Output:** content calendar, SEO map, funnel structure
- **Аналог:** SEO + частично Methodologist в нынешнем офисе

### 5. Performance / Analyst agent
- **Роль:** метрики, что работает / что нет, предложения по оптимизации
- **Output:** weekly performance report, A/B test results, iteration recommendations
- **Аналог:** частично Intelligence (для marketing-данных)
- **Замечание:** для marketing-офиса ОБЯЗАТЕЛЕН — без него нет петли обучения

### 6. Intelligence (competitive / market)
- **Роль:** trend watching, competitor tracking, market signals
- **Output:** weekly market digest, competitor moves, emerging trends
- **Уже есть:** `office/agents/intelligence/` — живой

---

## Чем marketing-офис отличается от dev

| Свойство | Dev-офис | Marketing-офис |
|----------|----------|----------------|
| **Validator** | Tests / linter / type-check | Brand guidelines / tone-of-voice |
| **Linter** | ESLint / Prettier | tone-of-voice rules, AI-slop list, банлист фраз |
| **Test suite** | Unit / integration / e2e | A/B test results, CTR, engagement metrics |
| **CI/CD** | GitHub Actions, deploy | Content calendar publishing, scheduled posts |
| **Code review** | PR review | Writer/Reviewer (другой контекст) + Equalizer для офферов |
| **Fail mode** | Bug в проде | Слабый CTR, тон не попадает в ЦА, brand-нарушение |
| **Iteration loop** | Bug → fix → ship | Brief → draft → critique → polish → publish → measure → learn (длиннее) |
| **Артефакт** | Code | Текст / визуал / кампания |

**Ключевое:** в dev «правильно/неправильно» однозначно (тест прошёл / нет). В marketing — субъективно + замеряется уже после публикации. Поэтому **Writer/Reviewer обязательны** + brand guidelines как hard rule.

---

## Brand-as-Validator

Аналог testing pyramid для marketing:

```
1. Self-check (внутри агента — checklist перед отдачей)
   - Tone-of-voice compliance
   - Banlist слов (AI-slop)
   - Brand colors / fonts (для визуала)

2. Peer review (Equalizer / другой Copywriter / Reviewer)
   - Оценка по 12 критериям Hormozi (для оффера)
   - Score жирности
   - Замечания строка-в-строку

3. Brand approval (Дизайнер / Designer-Senior / Хозяин)
   - Соответствие brand book
   - Один раз в начале (после brand-onboarding) — закон

4. Performance gate (Performance agent после публикации)
   - CTR / engagement vs baseline
   - A/B тест результат
   - Iteration recommendation
```

---

## Memory особенности marketing-офиса

Дополнительно к layered memory (`memory-architecture.md`):

```
office/agents/copywriter/
  memory/
    archival/
      brand-voice/        # Что работало по тону
      hooks/              # Удачные хуки с метриками
      story-bank/         # Готовые истории для постов
      banlist.md          # Слова и фразы которые не используем
office/agents/designer/
  memory/
    archival/
      brand-evolution/    # Как менялся стиль
      successful-layouts/ # Лендинги/обложки которые сработали
      moodboards/         # По проектам клиентов
office/agents/performance/
  memory/
    archival/
      experiments/        # Все A/B тесты с результатами
      patterns/           # Что стабильно работает в нише
      seasonality/        # Когда что лучше залетает
```

**Critical:** в marketing **не выбрасывай старые драфты**. Иногда возвращаешься к идее через 6 месяцев, переупаковываешь в другом контексте — и стреляет.

---

## Pipeline-skills (кросс-агентные)

В marketing-офисе много стандартных пайплайнов которые лучше делать **скиллами**, не оркестрацией Director'а:

- `/hot-trail` — горячий след, виральный контент (7 шагов)
- `/copywriting` — оркестратор контент-пайплайна (Hot Trail → Matthew Dicks → Stephen King → Hormozi → fact-check)
- `/storyteller` — живой пост-история
- `/write-longread` — продающая статья / лонгрид
- `/diagnostic-pitch` — презентация после диагностики
- `/publish` — упаковка к публикации (LSI ключи, CTA, описание)

Все уже есть у Хозяина. **Marketing-офис без скилл-пайплайнов = долго и неэффективно** (каждый пост — ручная оркестрация Director'ом).

---

## Connections (типичные handoff-ы в marketing)

| Сценарий | Цепочка | Параллельно? |
|----------|---------|--------------|
| Продающий пост | Copywriter → Equalizer → Designer (визуал) → Хозяин | Designer параллельно с Equalizer |
| Лонгрид/presell | Copywriter → review-longread → Equalizer | Последовательно |
| Запуск кампании | Strategist → Copywriter + Designer + Intelligence (parallel) → Director synthesis → Performance baseline | Параллельный fan-out |
| Иссл. конкурентов | Intelligence → Copywriter (анализ tone) → Strategist (positioning) | Sequential |
| Performance review | Performance → Strategist (next iteration plan) → Copywriter/Designer (changes) | Sequential |

См. полные шаблоны handoff'ов в `handoff-library.md`.

---

## ROI-чек: marketing-офис или один Copywriter?

Marketing-офис стоит ~15× токенов vs один Copywriter со скиллами. Когда полный офис оправдан:

| Условие | Решение |
|---------|---------|
| Запускаешь канал с нуля + ведёшь 3+ направления (контент + ads + лендинг) | Полный офис (5-6 ролей) |
| Один основной канал, < 5 артефактов в неделю | Один Copywriter + пайплайн-скиллы + Designer on-demand |
| Только тексты (нет визуала, нет аналитики) | Один Copywriter + Equalizer для критики |
| Нужна eval-петля (A/B тесты, CTR, итерации) | Минимум: Copywriter + Performance agent |

Для Хозяина сейчас: 1 продукт, основной канал — Telegram. Полный 6-ролевой офис — overkill. Достаточно текущего: Copywriter + Equalizer + Designer + Intelligence.

---

## Anti-patterns в marketing-офисе

| Анти-паттерн | Почему плохо |
|--------------|--------------|
| Universal Copywriter (marketing + sales + product одновременно) | Тон смешивается, CTR падает. Разделить или скиллы по типу. |
| Designer без brand book | Каждая обложка в новом стиле. **brand-onboarding ОБЯЗАТЕЛЬНО первым.** |
| Без Performance agent | Нет петли обучения. Артефакт уходит, метрики не возвращаются → копипастишь то что не работало. |
| Brand book только в голове Хозяина | После /clear — потеряно. **Brand book = файл `knowledge/brand/brand-book.md` (закон).** |
| AI-slop в промтах генерации | Стоковая глянцевая фигня. Banlist в Designer + DISTILLED_AESTHETICS_PROMPT в каждом промте. |

---

## Эталоны

**Внутренние:**
- `office/agents/copywriter/` — живой Copywriter с пайплайн-скиллами
- `office/agents/designer/` — живой Designer
- `office/agents/intelligence/` — живой Intelligence
- `examples/client-office/office/agents/designer/core.md` — clean Designer для клиента (с brand-onboarding pattern)

**Внешние:**
- [HubSpot — Multi-agent marketing systems](https://blog.hubspot.com/marketing/multi-agent-system-ai)
- [Jasper — 100+ marketing agents](https://www.jasper.ai/)
- [Writer.com agentic AI](https://writer.com/agents/)

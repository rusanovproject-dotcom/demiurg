# Client-офис — Best practices состав и особенности

Client-офис = ведение клиентов: лидогенерация, продажи, account management, customer success. Главное отличие от dev/marketing: **long-running state** (агент живёт с клиентом месяцы-годы) + **trust boundary** (нужен human-in-the-loop на критичных решениях) + **proактивность** (агенты сами инициируют касания).

**Источники:** ext research office-types секция (Salesforce Einstein / Landbase AI SDR / CS tools), `examples/client-office/` (живой пример), `office/agents/hermes/` (нынешний sales-агент Хозяина).

---

## Стандартный состав (7 ролей)

### 1. Client Director (Account Manager agent)
- **Роль:** главный по клиенту, контекст всей истории, решает кто и когда встревает
- **Output:** account plan, weekly summary, escalations to human
- **Особенность:** читает per-client `clients/{id}/CLAUDE.md` + memory клиента

### 2. BDR / SDR agent (лидогенерация)
- **Роль:** outbound, холодные касания, квалификация лидов
- **Output:** qualified leads, first-touch sequences
- **Замечание:** требует human approval перед отправкой (особенно cold email)

### 3. AE (Account Executive) agent
- **Роль:** демо, переговоры, закрытие сделки
- **Output:** demo notes, proposal context, deal status
- **Принимает warm handoff** от SDR (не cold leads)

### 4. Proposal / Contract agent
- **Роль:** КП, офферы, контракты
- **Output:** КП-документы, proposals, contracts
- **Аналог в офисе Хозяина:** скилл `/kp` (как агент в client-офисе для клиента)
- **Trust boundary:** цены и юридический язык — human approval

### 5. Customer Success / Health-Score agent
- **Роль:** мониторинг usage, раннее предупреждение оттока, proactive outreach
- **Output:** health scores, churn risk alerts, engagement reports
- **Проактивность:** **сам инициирует** check-in email через N дней простоя

### 6. Support Triage agent
- **Роль:** входящие запросы, routing, escalation
- **Output:** classified tickets, response templates, escalations
- **Связка:** входящее письмо → triage → AE/CS/Director (по типу)

### 7. Intelligence (client-facing)
- **Роль:** research по клиенту/компании перед звонком, news monitoring
- **Output:** pre-call brief, account intel updates
- **Отличается от market intel:** конкретная компания/человек, не индустрия

---

## Чем client-офис отличается от dev / marketing

| Свойство | Dev-офис | Marketing-офис | Client-офис |
|----------|----------|----------------|-------------|
| **Время жизни задачи** | Часы-дни | Дни-недели | **Месяцы-годы** |
| **Память** | Code = state | Brand book + content history | **Long-running per-client memory CRITICAL** |
| **Trust boundary** | Tests + code review | Brand approval | **Human-in-the-loop на любой контакт от имени бренда** |
| **Проактивность** | Reactive (на запрос) | Scheduled (контент-план) | **Proactive (агент сам инициирует касания)** |
| **Failure mode** | Bug | Слабый CTR | **Потеря клиента / репутационный удар** |
| **Артефакт** | Code | Текст / визуал | **Отношения** (контекст копится) |

---

## Long-running memory (CRITICAL для client-офисов)

Vector DB **недостаточно** — факты устаревают (клиент сменил тариф, контакт ушёл, сделка порвалась). Нужна **bi-temporal memory** (Graphiti / Zep paper):

Каждый факт о клиенте имеет 4 timestamp:
- `t_valid` — с какого момента факт верен
- `t_invalid` — с какого момента перестал быть верен
- `t_created` — когда добавлена запись
- `t_expired` — когда удалена / помечена устаревшей

### Структура памяти client-офиса

```
clients/
  {client_id}/
    CLAUDE.md                  # per-client контекст (≤100 строк)
    brief.md                   # ЦА, цели, бюджет, ограничения
    memory/
      core.md                  # Editable blocks (key facts) — агент сам правит
      buffer.md                # Recent interactions (last 20-30)
      archival/
        INDEX.md
        timeline/              # Хронология взаимодействий
          2026-04-24-discovery-call.md
          2026-05-01-proposal-sent.md
        decisions/             # Что и почему решили
        contacts/              # Кто-есть-кто на стороне клиента
          {person}.md          # с frontmatter valid_until
        deal/                  # Текущий deal stage + история
        usage/                 # (для CS) что используют, когда
    communications/            # Полная переписка (raw)
    meetings/                  # Транскрипты + summaries
```

### Правила работы с client memory

1. **Перед каждым касанием:** Director / Account Manager читает `clients/{id}/CLAUDE.md` + последние 5 записей из `timeline/`. Это перед любым ответом.
2. **После каждого касания:** агент append в `timeline/{date}-{type}.md` (что обсуждали, что решили, next step).
3. **Изменился факт:** не правь старую запись — добавь новую с пометкой «X стало Y, см. запись от <дата>». Старая остаётся (история обучения).
4. **Каждые 7 дней:** consolidator проверяет `valid_until` — если факт устарел, помечает `invalidated_at: YYYY-MM-DD` (не удаляет).
5. **Privacy:** чувствительные данные клиента (paspoort, health, etc.) НЕ хранятся в `archival/` — только в защищённом enterprise-storage.

---

## Trust boundaries — где обязательно human-in-the-loop

Client-офис не отправляет ничего клиенту без human review **на этих границах:**

| Граница | Почему | Action |
|---------|--------|--------|
| Cold outreach (первое касание) | Репутационный риск | Human approves text перед отправкой |
| Контракт / proposal | Юридический риск | Human подписывает |
| Цены и скидки | Финансовый риск | Human approves любое отклонение от прайса |
| Escalation после жалобы | Эмоциональный риск | Human ведёт разговор |
| Любая отправка email/sms от имени бренда | Брендовый риск | Default human approval, exception — explicit auto-approval rules |
| Изменение тарифа клиента | Финансовый риск | Human подтверждает |
| Удаление данных клиента | Compliance | Human approves + audit trail |

**Lethal Trifecta** (Simon Willison): private data + untrusted content + exfiltration vector = гарантированная утечка. Архитектурно cut одну ногу:
- Private data есть (клиентские)
- Untrusted content есть (входящие email от клиентов могут содержать prompt injection)
- **Exfiltration vector — резать.** Email send только через human approval. Web search — изолированный subagent без доступа к client data.

---

## Proactivity — агенты сами инициируют

Отличие client-офиса: агенты **не ждут запроса**. Customer Success agent **сам** замечает что клиент простаивает и пишет:

```yaml
trigger: usage_drop
condition: clients/{id}/usage/last_login > 14 days
action:
  - draft check-in email
  - human approval (Хозяин читает draft, отправляет / правит / отклоняет)
  - if approved → log в timeline/, schedule next check-in
```

Другие проактивные триггеры:
- **Renewal upcoming** (60 дней до конца контракта) → Account Manager готовит retention pitch
- **Health score drop** → CS уведомляет Account Manager
- **Trigger event** (клиент опубликовал важное) → Intelligence обогащает контекст
- **Anniversary** → Account Manager personal touch

---

## Pipeline и Skills (cross-agent)

Готовые скиллы для client-pipeline (есть у Хозяина):

- `/sales-debrief` — разбор продающего созвона (transcript → analysis → card → КП → follow-up)
- `/kp` — генерация КП по карточке клиента
- `/follow-up` — догон после созвона / КП
- `/diagnostic-pitch` — презентация после диагностики
- `/custdev` — синтетический CustDev (валидация идей)

В client-офисе **обязательно использовать**, не оркестрировать каждый раз вручную через Director.

---

## ROI-чек: full client-офис или solo agent?

| Условие | Решение |
|---------|---------|
| < 5 активных клиентов, всё веду сам | Solo agent (Hermes) + memory paterns |
| 5-20 клиентов, регулярные касания | Account Manager + Hermes + Customer Success (3 роли) |
| 20+ клиентов, B2B SaaS | Полный офис 7 ролей |
| Outbound campaigns + inbound + retention одновременно | Полный офис обязательно |

---

## Connections (типичные handoff-ы в client-офисе)

| Сценарий | Цепочка |
|----------|---------|
| Новый лид → квалификация | SDR → AE (если qualified) → Director |
| После discovery call | AE → Intelligence (research) → Proposal agent (draft КП) → Хозяин (approval) → Hermes (отправка) |
| После КП | Hermes → follow-up scheduled → если closed-won → Account Manager onboarding |
| Усталость клиента | CS detect → Account Manager warning → Хозяин (решение по retention plan) |
| Renewal | Account Manager prepare → Хозяин approval → Hermes execute |

---

## Anti-patterns в client-офисах

| Анти-паттерн | Почему плохо |
|--------------|--------------|
| Vector-only memory без bi-temporal | Факты устаревают молча, агент оперирует ложью |
| Auto-send email без human approval | Один промпт-injection и репутация в труху |
| Один Account Manager на 50 клиентов | Не помнит контекст, путает клиентов |
| Сообщения без per-client memory load | Каждое касание — с нуля, клиент чувствует холод |
| BDR без Brand voice (от лица компании) | Холодные касания не попадают в стиль, конверсия падает |
| Отсутствие escalation rules | Агент сам решает финансовые вопросы → катастрофа |
| Sales и Marketing copy от одного агента | Разные регистры, перемешивается |

---

## Эталоны

**Внутренние:**
- `office/agents/hermes/` — нынешний sales/follow-up агент (живой)
- `examples/client-office/office/agents/{director,strategist}/core.md` — clean roles
- `office/protocols/CUSTDEV-EXTRACTOR.md` — извлечение болей/возражений из созвонов

**Внешние:**
- [Salesforce Einstein SDR/Coach](https://www.salesforce.com/news/stories/einstein-sales-agents-announcement/)
- [Landbase — AI SDR dream teams](https://www.landbase.com/blog/the-ai-sdr-dream-team-multi-agent-systems)
- [Zep / Graphiti — bi-temporal memory paper](https://arxiv.org/abs/2501.13956)
- [Simon Willison — Lethal Trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)

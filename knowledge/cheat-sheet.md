# Cheat Sheet — все правила на одной странице

> Краткая выжимка. Детали — `architecture/agent-design.md`.

## Агент
- Identity ≤ 300 токенов, уникальный принцип (не "делай хорошо")
- CLAUDE.md = 60-150 строк, handle-ссылки (не inline)
- "НЕ отвечает за" с redirect путями обязательна

## Скилл
- Description: pushy + MANDATORY TRIGGERS + DO NOT use when
- ≥ 2 примера Input → Output (конкретные)
- Один скилл = одна задача, ≤ 500 строк

## Knowledge
- Один факт = одно место (grep перед созданием)
- INDEX.md обязателен если > 3 файлов, с колонкой "Когда загружать"
- Файлы ≤ 300 строк, evolving/ для самообучения

## Связи
- reports_to обязателен, redirect пути валидны
- Прописан в AGENTS.md, нет пересечений зон
- Handoff через Structured Handoff (см. agent-design.md)

## Проверка
- validate-agent.sh после каждой сборки
- DRY-RUN: 2-3 сценария за ≤ 3 шага

## Запрещено
- Клонировать шаблон без уникального identity
- Inline контент вместо ссылок
- Knowledge score < 5 → сборка заблокирована

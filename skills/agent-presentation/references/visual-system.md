# Visual System — дизайн-система презентации агента

Ниже — **рабочий пример** дизайн-системы, на которой скилл обкатан: тёмно-синяя глубина, синий glow `#1A6BFF`, 3D-объекты, минимализм с одним смысловым акцентом.

⚠️ **Есть свой брендбук — подставляй его палитру и шрифты, а структуру системы бери отсюда.** Ценность этого файла не в конкретных hex'ах, а в том, ЧТО должно быть определено: фон двух регистров, один акцентный цвет, glow-система, бордеры карточек, типографическая шкала, сетка. Своего бренда нет — бери как есть, работает.

---

## Палитра

| Hex | Роль | Где |
|-----|------|-----|
| `#070B17` | Фон brand-слайдов — тёмно-синяя ночь | Слайды 3-16 |
| `#F5F5F5` | Фон AI-слоп слайдов | Слайды 1-2 |
| `#1A6BFF` | Синий glow — главный акцент | Команды, имена файлов, hover, имена методологов, имя агента |
| `#0F2060` | Глубокий синий — radial glow центра | Атмосферный фон brand-слайдов |
| `#FFFFFF` | Основной текст | H1, H2, body на тёмном |
| `#6B7280` | Второстепенный текст | Подписи, italic, labels |
| `#111827` | Подложки карточек | Квадраты схем, blocks |
| `#1E2A45` | Border карточек (НЕ `#222222`) | Все card-borders |
| `#334155` | Разделители | Горизонтальные линии внутри блоков |
| `#111111` | Текст AI-слоп слайдов | Слайды 1-2 |
| `#444444` | Body AI-слоп слайдов | Слайды 1-2 |

⚠️ **Не используй `#000000`.** На абсолютном чёрном glow не работает — нет глубины, теряется атмосфера. Пример бренда — `#070B17` (близко к `#080A0F` у Life OS).

---

## Типографика

### Brand-слайды (3-16)

| Уровень | Шрифт | Размер | Вес | line-height |
|---------|-------|--------|-----|-------------|
| H1 (главные удары) | Space Grotesk | 72-96px | 700 | 1.0-1.1 |
| H2 (заголовки) | Space Grotesk | 40-48px | 600 | 1.15 |
| Body | Space Grotesk | 18-20px | 400 | 1.6 |
| Caption / label | Space Grotesk | 13-14px | 400 | 1.4 |
| Code / команды | JetBrains Mono | 16-20px | 400-700 | 1.5 |

Letter-spacing:
- H1: `-0.02em`
- code: `0`
- caption / labels: `0.05em` (uppercase для labels)

### AI-слоп слайды (1-2)

| Уровень | Шрифт | Размер | Вес |
|---------|-------|--------|-----|
| H1 | Inter | 36-40px | 700 |
| Body | Inter | 16px | 400 |
| Bullets | Inter | 16px | 400 |

Inter здесь не плохой шрифт — он «корпоративный нейтральный», узнаваемый бессознательно как ChatGPT/Notion. Срабатывает у ученика автоматически.

---

## Glow-система

### На brand-слайдах — фоновый glow

Горизонтальный луч в центре slide:
```css
.slide.brand::before {
  content: '';
  position: absolute;
  left: 0; right: 0;
  top: 50%;
  height: 1px;
  background: linear-gradient(90deg,
    transparent 0%,
    rgba(26, 107, 255, 0.15) 20%,
    rgba(26, 107, 255, 0.35) 50%,
    rgba(26, 107, 255, 0.15) 80%,
    transparent 100%
  );
  transform: translateY(-50%);
  pointer-events: none;
  z-index: 0;
}
```

Атмосферный radial:
```css
.slide.brand::after {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 80% 60% at 50% 50%,
    rgba(15, 32, 96, 0.4) 0%,
    transparent 70%
  );
  pointer-events: none;
  z-index: 0;
}
```

### Интенсивность glow по типу слайда

| Тип слайда | Intensity | Где |
|------------|-----------|-----|
| Ударные (3, 5, 9.5, 8.5, 6) | `0.5` | Слайды-пики |
| Концептуальные (4, 7, 8, 13) | `0.35` (default) | Основные слайды |
| Технические (9, 10, 12, 14, 15) | `0.2` | Тише, не отвлекает |
| CTA (16) | `0.15` | Самый тихий — пространство работает |

### Точечный glow на элементах

Только на:
- Именах команд: `box-shadow: 0 0 20px rgba(26,107,255,0.3)` на JetBrains Mono тексте
- Имени агента (слайд 6): `text-shadow: 0 0 40px rgba(26,107,255,0.3)`
- Финальной фразе CTA: `text-shadow: 0 0 32px rgba(26,107,255,0.5)`
- При hover на интерактивных элементах: `box-shadow: 0 0 16px rgba(26,107,255,0.25)`

⚠️ **НЕ размазывай glow по всему слайду.** Glow точечный, прицельный.

---

## Карточки и контейнеры

```css
/* Стандартная карточка-схема */
.card {
  background: #111827;
  border: 1px solid #1E2A45;
  border-radius: 8px;
  padding: 24px 28px;
}

/* Карточка скилла со glow */
.skill-card {
  /* + остальное */
  box-shadow: 0 0 24px rgba(26, 107, 255, 0.25);
}

/* Hover на интерактивной карточке */
.card:hover {
  border-color: #1A6BFF;
  box-shadow: 0 0 16px rgba(26, 107, 255, 0.25);
  transition: 200ms;
}
```

Border-radius:
- Стандарт: 8px
- Большие модалки: 16px
- Маленькие квадраты-кнопки: 10px

---

## Иконки и иллюстрации

**Иконки — НЕ использовать.** Никаких feather, emoji, fluent, lucide. Они делают из презы шаблон.

Вместо иконок:
- Типографика
- Стрелки символьные: `→ ▼ ─ ↓ ◄`
- Пространство

**3D-объекты:**
- Один полноразмерный портрет на слайде 6 (35-40% ширины)
- Опционально 3D-акценты на ключевых слайдах: 5 (Поворот), 11 (Запомни), 15 (Методология). Размер 160-240px, opacity 0.4-0.6, `mix-blend-mode: screen` или `lighten`

**Дерево файлов (слайд 9):** рендерится как `<pre>` в JetBrains Mono, не SVG, не картинка.

---

## Сетка и отступы

Viewport: 1440×900 (desktop-first, мобильная адаптация не нужна — это самостоятельная преза).

- 12 колонок, gutter 24px, margin 80px по бокам
- Контентная зона: max-width 900px, центрирована
- Схемы и квадраты: до 1100px при необходимости

Вертикальные отступы:
- H2 → body: 32px
- Между блоками/карточками: 20px
- Padding внутри карточки: 24×28px
- От края слайда до контента: 80px top, 80px bottom

Baseline grid: 8px. Все значения кратны 8.

---

## Переходы между слайдами

### Переход 2→3 (AI-слоп → Brand)

**Cut с чёрной вспышкой 80ms.** НЕ fade. Это нарративный момент — резкий разрыв.

```css
@keyframes flash-cut {
  0% { background: #F5F5F5; }
  20% { background: #000000; }
  100% { background: #070B17; }
}
```

### Стандартный переход

Fade + translateY(8px → 0), duration 350-500ms ease-out.

### Переход 9→9.5 (карта папок → Динамическая память)

Слайд 9 уходит fade + translateY(0 → -6px) — «оседает». Слайд 9.5 появляется из темноты — fade-in 350ms с задержкой 80ms. Потом 200ms тишины перед началом анимации фразы. Итого: ощущение паузы перед ударом.

---

## Анимации входа элементов

Используй stagger: каждый следующий элемент появляется с задержкой 60-300ms.

Пример (слайд 6):
- Портрет: fade-in 800ms, ease — первый
- «Здравствуй, я» + «Логос»: delay 300ms, fade + translateX(-16px → 0), 500ms
- Представление: delay 700ms, fade
- Имена методологов: delay 1000ms, fade
- Финальная фраза: delay 1300ms + underline нарастает слева направо за 400ms

---

## Интерактивность — карта папок (слайд 9)

### Hover на строке файла

```css
.row.clickable:hover {
  background: rgba(26, 107, 255, 0.08);
  cursor: pointer;
  transition: 150ms;
}
.row.clickable:hover .file,
.row.clickable:hover .folder {
  color: #1A6BFF;
}
```

При hover — справа sticky-панель показывает short-описание (250-400 символов).

### Click → модалка

```css
.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(7, 11, 23, 0.92);
  backdrop-filter: blur(8px);
  z-index: 100;
}
.modal-card {
  max-width: 560px;
  background: #111827;
  border: 1px solid #1E2A45;
  border-radius: 16px;
  padding: 40px;
}
```

Закрытие: клик на overlay / `✕` / Escape.

Анимация открытия: overlay fade-in 150ms, карточка scale(0.95→1.0) + fade, 200ms ease-out.

### 5 кнопок развилки (слайд 13)

```css
.btn-square {
  width: 96px;
  height: 96px;
  background: #111827;
  border: 1px solid #1E2A45;
  border-radius: 10px;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  transition: 150ms;
}
.btn-square:hover {
  border-color: #1A6BFF;
  box-shadow: 0 0 16px rgba(26, 107, 255, 0.25);
}
.btn-square .icon {
  font-size: 22px;
  color: #1A6BFF;
  font-weight: 700;
}
.btn-square .label {
  font-size: 12px;
  color: #CCCCCC;
  text-align: center;
  line-height: 1.3;
}
```

5 квадратов flex-row, gap 12px, justify-content: center.

---

## 3D-портреты — посадка

Промт-шаблон для генерации (Replicate `nano-banana-pro`):

```
Hyperrealistic 3D render, waist-up portrait of [persona description].
[Character details: age, build, clothing, pose, expression].
[Distinctive feature: glowing element, prop, gesture].

Lighting: primary soft blue glow (#1A6BFF) from below-left, casting cool light.
Secondary cold rim light from the right separating subject from background.
Background: deep near-black (#070B17), no architecture, pure depth.
[Glowing element] is the brightest point.

Style: cinematic hyperrealistic 3D render, MetaHuman-quality skin texture,
fabric with visible thread detail, cold shadows, neutral midtones,
near-white specular highlights. Dramatic but intimate mood.

Aspect ratio 3:4, waist-up crop, subject centered.
```

Размер на слайде:
- Width: 35-40% контейнера
- max-width: 480px
- object-fit: contain
- object-position: top center
- Опционально: `filter: drop-shadow(0 0 24px rgba(26,107,255,0.4))` для усиления glow

---

## CSS-переменные (рекомендованный набор)

```css
:root {
  --bg-dark: #070B17;
  --bg-light: #F5F5F5;
  --accent-blue: #1A6BFF;
  --deep-blue: #0F2060;
  --text-primary: #FFFFFF;
  --text-secondary: #6B7280;
  --card-bg: #111827;
  --card-border: #1E2A45;
  --divider: #334155;
  --glow-shadow: 0 0 32px rgba(26, 107, 255, 0.5);
  --glow-shadow-soft: 0 0 16px rgba(26, 107, 255, 0.25);
}
```

---

## Что НЕ делать (антипаттерны визуала)

1. **Glow на всём подряд** — теряется акцент. Только на ключевых элементах
2. **`#000000` фон** — на абсолютном чёрном нет глубины. Только `#070B17`
3. **Иконки feather/emoji/lucide** — превращают презу в шаблон
4. **Tailwind utility classes в HTML** — ручной CSS чище и быстрее для одной презы
5. **Framer Motion / большие animation libraries** — overkill, vanilla CSS transitions достаточно
6. **Bullet-points в стиле презентаций** — везде кроме слайдов 1-2 (там нарочно)
7. **Border `#222222`** — стандартный AI-design. Используй `#1E2A45` — синеватый, в атмосфере
8. **Симметричная сетка карточек одинакового размера** — добавляй один акцент-блок (broader, brighter)
9. **3D-портрет на нескольких слайдах** — пик-момент только на слайде 6. Иначе теряется
10. **Прямоугольники-колонны вместо квадратиков на слайде 13** — Хозяин заворачивал. ТОЛЬКО квадраты 96×96 в один ряд

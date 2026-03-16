# HACCP Mobile — Полное состояние проекта

> Обновлено: 2026-03-16

## Обзор

Flutter-приложение для управления пищевой безопасностью (SFBB/HACCP), подключённое к общему Supabase-бэкенду с веб-версией. Развёрнуто на GitHub Pages для тестирования в Chrome и запускается на iOS-симуляторе.

- **Репозиторий:** https://github.com/KNSTNTN24/haccp-mobile
- **GitHub Pages:** https://knstntn24.github.io/haccp-mobile/
- **Веб-версия (Vercel):** https://haccp-app-nine.vercel.app
- **Supabase проект:** `rszrggreuarvodcqeqrj`

## Стек технологий

| Компонент | Технология |
|-----------|-----------|
| Фреймворк | Flutter (Dart 3.11+) |
| State Management | Riverpod 3.x (Notifier, NOT StateNotifier) |
| Навигация | GoRouter 17.x |
| Бэкенд | Supabase (PostgreSQL + Auth + RLS) |
| UI | Material Design 3, Google Fonts (Inter, Outfit) |
| Деплой | GitHub Pages (web), iOS Simulator |

## Дизайн (обновлён Марией)

- Зелёно-белая тема с Material 3
- Анимированные пустые состояния
- Обновлённый навбар с иконками

---

## Структура файлов

```
lib/
├── main.dart                          # Точка входа
├── app.dart                           # HACCPApp + MaterialApp.router
├── config/
│   ├── supabase.dart                  # Supabase init (ключи захардкожены)
│   ├── router.dart                    # GoRouter с redirect-логикой
│   └── theme.dart                     # AppColors + AppTheme (Material 3)
├── models/
│   ├── profile.dart                   # UserRole enum + Profile
│   ├── business.dart                  # Business
│   ├── checklist.dart                 # ChecklistTemplate, Item, Completion, Response
│   ├── recipe.dart                    # Recipe, Ingredient, RecipeIngredient
│   ├── menu_item.dart                 # MenuItem
│   ├── incident.dart                  # Incident
│   ├── supplier.dart                  # Supplier
│   ├── notification.dart              # AppNotification
│   ├── diary_entry.dart               # DiaryEntry
│   └── document.dart                  # Document, DocumentAccess, AccessLevel
├── providers/
│   ├── auth_provider.dart             # Auth + Profile + Business providers
│   ├── dashboard_provider.dart        # DashboardStats aggregation
│   └── documents_provider.dart        # Documents CRUD + Storage upload
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart          # Email/password login
│   │   ├── register_screen.dart       # Регистрация (+ invite token)
│   │   └── setup_screen.dart          # Создание бизнеса / Join Team
│   ├── dashboard/
│   │   └── dashboard_screen.dart      # Статистика + quick actions
│   ├── checklists/
│   │   ├── checklists_screen.dart     # Список шаблонов
│   │   ├── checklist_detail_screen.dart # Заполнение чеклиста
│   │   └── checklist_manage_screen.dart # Создание шаблона
│   ├── recipes/
│   │   ├── recipes_screen.dart        # Список рецептов по категориям
│   │   ├── recipe_detail_screen.dart  # Детальный просмотр
│   │   └── recipe_new_screen.dart     # Создание рецепта
│   ├── menu/
│   │   └── allergen_matrix_screen.dart # Матрица аллергенов
│   ├── diary/
│   │   └── diary_screen.dart          # Ежедневный дневник SFBB
│   ├── incidents/
│   │   └── incidents_screen.dart      # Инциденты и жалобы
│   ├── suppliers/
│   │   └── suppliers_screen.dart      # Поставщики
│   ├── team/
│   │   └── team_screen.dart           # Команда + приглашения
│   ├── documents/
│   │   ├── documents_screen.dart      # Список документов + фильтр
│   │   ├── document_upload_screen.dart # Загрузка документа
│   │   └── document_detail_screen.dart # Просмотр + управление доступом
│   ├── notifications/
│   │   └── notifications_screen.dart  # Уведомления
│   └── ai_import/
│       └── ai_import_screen.dart      # Заглушка "Coming Soon"
└── widgets/
    ├── allergen_badge.dart            # Бейдж аллергена с эмодзи
    └── app_scaffold.dart              # Bottom nav + shell
```

---

## Маршрутизация (GoRouter)

```
/login                    → LoginScreen
/register?token=XXX       → RegisterScreen
/setup                    → SetupScreen (Create Business / Join Team)

ShellRoute (AppScaffold — bottom navigation):
  /dashboard              → DashboardScreen
  /checklists             → ChecklistsScreen
    /checklists/new       → ChecklistManageScreen (manager/owner)
    /checklists/:id       → ChecklistDetailScreen
  /recipes                → RecipesScreen
    /recipes/new          → RecipeNewScreen
    /recipes/:id          → RecipeDetailScreen
  /menu                   → AllergenMatrixScreen
  /diary                  → DiaryScreen
  /incidents              → IncidentsScreen
  /suppliers              → SuppliersScreen
  /documents              → DocumentsScreen
    /documents/upload     → DocumentUploadScreen (manager/owner)
    /documents/:id        → DocumentDetailScreen
  /team                   → TeamScreen
  /notifications          → NotificationsScreen
```

**Redirect-логика:**
- Не залогинен → `/login`
- Залогинен без профиля → `/setup`
- Залогинен с профилем → `/dashboard`

---

## Провайдеры (State Management)

| Провайдер | Тип | Описание |
|-----------|-----|----------|
| `authStateProvider` | `StreamProvider<AuthState>` | Стрим auth-событий Supabase |
| `currentUserProvider` | `Provider<User?>` | Текущий auth user |
| `profileProvider` | `FutureProvider<Profile?>` | Профиль из таблицы profiles |
| `businessProvider` | `FutureProvider<Business?>` | Бизнес текущего пользователя |
| `authNotifierProvider` | `NotifierProvider<AuthNotifier>` | signIn/signUp/signOut/setupBusiness/joinWithInvite |
| `dashboardStatsProvider` | `FutureProvider<DashboardStats>` | Агрегация статистики для дашборда |
| `checklistsProvider` | `FutureProvider` (в экране) | Шаблоны чеклистов с items |
| `recipesProvider` | `FutureProvider` (в экране) | Рецепты с ингредиентами |
| `diaryProvider` | `FutureProvider.family<..., String>` | Дневник по дате |
| `incidentsProvider` | `FutureProvider` (в экране) | Инциденты |
| `suppliersProvider` | `FutureProvider` (в экране) | Поставщики |
| `teamProvider` | `FutureProvider` (в экране) | Члены команды |
| `notificationsProvider` | `FutureProvider` (в экране) | Уведомления (50 макс) |

---

## База данных (Supabase PostgreSQL)

### Таблицы

#### 1. `businesses`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | gen_random_uuid() |
| name | TEXT NOT NULL | Название бизнеса |
| address | TEXT | Адрес |
| registration_number | TEXT | Регистрационный номер |
| created_at | TIMESTAMPTZ | NOW() |
| updated_at | TIMESTAMPTZ | Авто-обновление через триггер |

#### 2. `profiles`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | FK → auth.users(id), CASCADE |
| email | TEXT NOT NULL | Email |
| full_name | TEXT | Полное имя |
| role | TEXT NOT NULL | owner/manager/chef/kitchen_staff/front_of_house |
| business_id | UUID NOT NULL | FK → businesses(id), CASCADE |
| avatar_url | TEXT | URL аватара |
| created_at / updated_at | TIMESTAMPTZ | Автоматически |

#### 3. `invites`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| email | TEXT NOT NULL | Email приглашённого |
| role | TEXT NOT NULL | Роль |
| business_id | UUID NOT NULL | FK → businesses |
| invited_by | UUID NOT NULL | FK → profiles |
| token | TEXT UNIQUE | gen_random_bytes(32) hex |
| expires_at | TIMESTAMPTZ | NOW() + 7 days |
| used_at | TIMESTAMPTZ | NULL если не использован |

#### 4. `checklist_templates`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| name | TEXT NOT NULL | Название |
| description | TEXT | Описание |
| frequency | TEXT NOT NULL | daily/weekly/monthly/four_weekly/custom |
| assigned_roles | TEXT[] | Массив ролей |
| business_id | UUID NOT NULL | FK |
| sfbb_section | TEXT | Секция SFBB |
| is_default | BOOLEAN | Дефолтный ли |
| active | BOOLEAN | Активен ли |

#### 5. `checklist_template_items`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| template_id | UUID NOT NULL | FK → checklist_templates, CASCADE |
| name | TEXT NOT NULL | Название пункта |
| item_type | TEXT NOT NULL | tick/temperature/text/yes_no |
| required | BOOLEAN | Обязательный ли |
| sort_order | INT | Порядок |
| min_value / max_value | NUMERIC | Для температуры |
| unit | TEXT | °C, °F и т.д. |

#### 6. `checklist_completions`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| template_id | UUID NOT NULL | FK |
| completed_by | UUID NOT NULL | FK → profiles |
| completed_at | TIMESTAMPTZ | NOW() |
| signed_off_by | UUID | FK → profiles |
| notes | TEXT | |
| business_id | UUID NOT NULL | FK |

#### 7. `checklist_responses`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| completion_id | UUID NOT NULL | FK → completions, CASCADE |
| item_id | UUID NOT NULL | FK → template_items, CASCADE |
| value | TEXT NOT NULL | Ответ |
| notes | TEXT | |
| flagged | BOOLEAN | Выход за пределы |

#### 8. `ingredients`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| name | TEXT NOT NULL | Название |
| allergens | TEXT[] | Массив аллергенов (14 типов) |
| business_id | UUID | FK, nullable = глобальный |

#### 9. `recipes`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| name | TEXT NOT NULL | Название |
| description | TEXT | |
| category | TEXT NOT NULL | starter/main/dessert/side/sauce/drink/other |
| instructions | TEXT | Инструкции |
| cooking_method | TEXT | Метод готовки |
| cooking_temp | NUMERIC | Температура |
| cooking_time | NUMERIC | Время |
| cooking_time_unit | TEXT | minutes/hours |
| sfbb_check_method | TEXT | |
| extra_care_flags | TEXT[] | eggs/rice/pulses/shellfish |
| reheating_instructions | TEXT | |
| hot_holding_required | BOOLEAN | |
| chilling_method | TEXT | |
| photo_url | TEXT | URL фото |
| source_video_url | TEXT | URL видео (AI import) |
| business_id | UUID NOT NULL | FK |
| created_by | UUID NOT NULL | FK → profiles |
| active | BOOLEAN | |

#### 10. `recipe_ingredients`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| recipe_id | UUID NOT NULL | FK → recipes, CASCADE |
| ingredient_id | UUID NOT NULL | FK → ingredients, CASCADE |
| quantity | TEXT | Количество |
| unit | TEXT | Единица |

#### 11. `menu_items`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| recipe_id | UUID NOT NULL | FK → recipes, CASCADE |
| category | TEXT NOT NULL | Категория меню |
| active | BOOLEAN | |
| display_order | INT | Порядок |
| business_id | UUID NOT NULL | FK |

#### 12. `diary_entries`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| date | DATE NOT NULL | Дата |
| business_id | UUID NOT NULL | FK |
| signed_by | UUID | FK → profiles |
| notes | TEXT | |
| opening_done | BOOLEAN | |
| closing_done | BOOLEAN | |
| UNIQUE(date, business_id) | | |

#### 13. `notifications`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| user_id | UUID NOT NULL | FK → profiles, CASCADE |
| type | TEXT NOT NULL | Тип |
| title | TEXT NOT NULL | Заголовок |
| message | TEXT NOT NULL | Сообщение |
| read | BOOLEAN | |
| link | TEXT | Ссылка навигации |

#### 14. `suppliers`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| name | TEXT NOT NULL | Компания |
| contact_name | TEXT | Контактное лицо |
| phone | TEXT | Телефон |
| address | TEXT | Адрес |
| goods_supplied | TEXT | Поставляемые товары |
| delivery_days | TEXT[] | Дни доставки |
| business_id | UUID NOT NULL | FK |

#### 15. `incidents`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| type | TEXT NOT NULL | complaint/incident |
| description | TEXT NOT NULL | Описание |
| action_taken | TEXT | Предпринятые действия |
| follow_up | TEXT | Как предотвратить |
| reported_by | UUID NOT NULL | FK → profiles |
| date | DATE NOT NULL | |
| business_id | UUID NOT NULL | FK |

#### 16. `documents`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | gen_random_uuid() |
| title | TEXT NOT NULL | Название документа |
| description | TEXT | Описание |
| category | TEXT NOT NULL | certificate/license/policy/instruction/contract/inspection/training/other |
| file_url | TEXT NOT NULL | Путь в Supabase Storage |
| file_name | TEXT NOT NULL | Оригинальное имя файла |
| file_size | BIGINT | Размер в байтах |
| file_type | TEXT | MIME-тип |
| uploaded_by | UUID NOT NULL | FK → profiles, CASCADE |
| business_id | UUID NOT NULL | FK → businesses, CASCADE |
| access_level | TEXT NOT NULL | all/managers_only/owner_only/custom |
| expires_at | DATE | Срок действия |
| created_at / updated_at | TIMESTAMPTZ | Автоматически |

#### 17. `document_access` (для access_level = 'custom')
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| document_id | UUID NOT NULL | FK → documents, CASCADE |
| profile_id | UUID NOT NULL | FK → profiles, CASCADE |
| granted_by | UUID NOT NULL | FK → profiles |
| created_at | TIMESTAMPTZ | NOW() |
| UNIQUE(document_id, profile_id) | | |

#### 18. `training_records` (не используется в мобильном)
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| profile_id | UUID NOT NULL | FK → profiles |
| safe_method | TEXT NOT NULL | Метод безопасности |
| trained_at | DATE | Дата обучения |
| trained_by | UUID | FK → profiles |
| notes | TEXT | |
| business_id | UUID NOT NULL | FK |

#### 17. `four_weekly_reviews` (не используется в мобильном)
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| business_id | UUID NOT NULL | FK |
| period_start / period_end | DATE | Период |
| summary | TEXT | |
| action_items | JSONB | Список действий |
| reviewed_by | UUID | FK → profiles |
| reviewed_at | TIMESTAMPTZ | |

#### 18. `notification_rules` (не используется в мобильном)
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| business_id | UUID NOT NULL | FK |
| trigger_type | TEXT NOT NULL | Тип триггера |
| trigger_config | JSONB | Конфигурация |
| recipient_roles | TEXT[] | Кому |
| channels | TEXT[] | in_app и т.д. |
| active | BOOLEAN | |

### RLS-политики (краткое описание)

| Таблица | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| businesses | Свой бизнес (get_my_business_id) | Любой auth user | — | — |
| profiles | Свой бизнес + свой профиль | Свой id (auth.uid) | Свой профиль | — |
| invites | Manager/Owner своего бизнеса | Manager/Owner | Manager/Owner | Manager/Owner |
| checklist_templates | Свой бизнес | Manager/Owner | Manager/Owner | Manager/Owner |
| checklist_completions | Свой бизнес | Свой (completed_by) | — | — |
| recipes | Свой бизнес | Chef/Manager/Owner | Chef/Manager/Owner | Chef/Manager/Owner |
| ingredients | Свой бизнес + глобальные | Chef/Manager/Owner | Chef/Manager/Owner | Chef/Manager/Owner |
| suppliers | Свой бизнес | Manager/Owner | Manager/Owner | Manager/Owner |
| incidents | Свой бизнес | Свой (reported_by) | — | — |
| diary_entries | Свой бизнес | Свой бизнес | Свой бизнес | Свой бизнес |
| documents | По access_level + role | Manager/Owner | Owner + uploaded_by | Owner |
| document_access | Свой бизнес | Manager/Owner | — | Owner |
| notifications | Свои (user_id) | — | Свои | — |

### RPC-функции (SECURITY DEFINER)

1. **`setup_business(business_name, owner_name, business_address)`**
   - Создаёт бизнес + профиль owner в одной транзакции
   - Обходит RLS для новых пользователей

2. **`join_with_invite(invite_token, member_name)`**
   - Находит инвайт по токену, создаёт профиль, отмечает инвайт как использованный
   - Обходит RLS для новых пользователей

3. **`get_my_business_id()`** — SECURITY DEFINER helper для RLS
4. **`get_my_role()`** — SECURITY DEFINER helper для RLS

---

## Роли и права

| Действие | Owner | Manager | Chef | Kitchen Staff | Front of House |
|----------|-------|---------|------|---------------|----------------|
| Создать чеклист | ✅ | ✅ | ❌ | ❌ | ❌ |
| Заполнить чеклист | ✅ | ✅ | ✅ | ✅ | ✅ |
| Создать рецепт | ✅ | ✅ | ✅ | ❌ | ❌ |
| Управлять поставщиками | ✅ | ✅ | ❌ | ❌ | ❌ |
| Пригласить в команду | ✅ | ✅ | ❌ | ❌ | ❌ |
| Создать инцидент | ✅ | ✅ | ✅ | ✅ | ✅ |
| Вести дневник | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Статус функций

### ✅ Реализовано

1. **Auth** — Login, Register, Setup (Create Business / Join Team)
2. **Dashboard** — Статистика, прогресс-кольцо, quick actions
3. **Чеклисты** — Список, заполнение (tick/temp/text/yes_no), создание шаблона
4. **Рецепты** — Список по категориям, детальный просмотр, создание с ингредиентами
5. **Аллергены** — Матрица 14 аллергенов × рецепты, бейджи с эмодзи
6. **Дневник** — Открытие/закрытие, подпись, заметки, навигация по датам
7. **Инциденты** — Список, создание (тип + описание + действия)
8. **Поставщики** — Список, добавление (контакт, телефон, товары, дни доставки)
9. **Команда** — Список участников, приглашение по токену
10. **Уведомления** — Список, прочитано/не прочитано, отметка как прочитанное
11. **Документы** — Загрузка файлов (PDF, JPG, DOCX, XLSX), категории, поиск, управление доступом (all/managers/owner/custom), срок действия, Supabase Storage

### 🟡 Частично

- **Инциденты** — поле `follow_up` есть в БД, но не в UI
- **Меню** — матрица аллергенов есть, но нет управления menu_items
- **Уведомления** — отображение есть, но нет автоматической генерации

### ❌ Не реализовано

#### Высокий приоритет
- [ ] **Edit/Delete рецептов** — нет кнопок редактирования/удаления
- [ ] **Edit/Delete чеклистов** — нет редактирования шаблонов
- [ ] **Edit/Delete поставщиков** — нет редактирования/удаления
- [ ] **История чеклистов** — нет просмотра прошлых заполнений
- [ ] **Инцидент follow-up** — поле `follow_up` не показано в UI
- [ ] **Статус инцидента** — нет open/resolved трекинга

#### Средний приоритет
- [ ] **Menu Builder** — активация/деактивация блюд в меню, категории
- [ ] **Редактирование профиля** — смена имени, аватара
- [ ] **Настройки бизнеса** — редактирование адреса, названия
- [ ] **Staff Training Records** — обучение сотрудников (таблица есть в БД)
- [ ] **4-Weekly Review** — ревью за 4 недели (таблица есть в БД)
- [ ] **PDF экспорт** — дневник, чеклисты, отчёты
- [ ] **Quick Allergen Lookup** — поиск аллергенов по блюду

#### Низкий приоритет
- [ ] **AI Import рецептов** — загрузка видео → транскрипция → рецепт
- [ ] **Push уведомления** — FCM, email, авто-напоминания
- [ ] **Notification Rules** — настройка правил уведомлений
- [ ] **Фото рецептов** — загрузка в Supabase Storage
- [ ] **Cleaning Schedule** — расписание уборки
- [ ] **Pest Control** — контроль вредителей
- [ ] **Recipe Versioning** — версионирование рецептов
- [ ] **Supplier Approval** — утверждение поставщиков
- [ ] **Logout** — кнопка выхода из аккаунта

---

## Ключевые решения и заметки

### Supabase
- **Anon key захардкожен** в `supabase.dart` (публичный ключ, безопасно)
- **Email confirmation отключен** (`mailer_autoconfirm: true`) — не нужен для тестирования
- **RPC-функции** (`setup_business`, `join_with_invite`) обходят RLS для setup-потока
- **RLS-хелперы** (`get_my_business_id()`, `get_my_role()`) — SECURITY DEFINER функции
- **Storage bucket** `documents` — private, max 10 MB, PDF/JPG/PNG/DOCX/XLSX

### Flutter
- **Riverpod 3.x** — используем `Notifier`, НЕ `StateNotifier`; `.value` НЕ `.valueOrNull`
- **GoRouter** — используем `context.go()` для навигации
- **AnimatedBuilder** в setup_screen — работает с TabController
- **flutter_dotenv удалён** — ключи захардкожены (GitHub Pages блокирует .env файлы)

### Деплой
- **GitHub Pages** — gh-pages branch содержит ТОЛЬКО `build/web/` contents
- **Base href** — `flutter build web --base-href "/haccp-mobile/"`
- **iOS Simulator** — `flutter run` запускает на подключённом симуляторе
- **Apple Developer Account** — ожидает регистрации для TestFlight/App Store

### Дизайн (обновлён Марией)
- Зелёно-белая тема на дашборде
- Обновлённый навбар с Material 3
- Анимированные пустые состояния на чеклистах

---

## Команды для разработки

```bash
# Запуск на iOS-симуляторе
cd /Users/knstntn/HACCP/haccp-mobile
flutter run

# Сборка для веба
flutter build web --release --base-href "/haccp-mobile/"

# Деплой на GitHub Pages
cp -r build/web /tmp/haccp-deploy
git checkout gh-pages
git rm -rf .
find . -not -path './.git/*' -not -path './.git' -delete
cp -r /tmp/haccp-deploy/* .
git add -A
git commit -m "Deploy update"
git push origin gh-pages
git checkout main
rm -rf /tmp/haccp-deploy

# Подтянуть изменения
git fetch origin && git pull origin main
```

# HACCP Mobile — Полное состояние проекта

> Обновлено: 2026-03-17
> Версия: HACCP 1.0 (тег `v1.0`)

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
| Бэкенд | Supabase (PostgreSQL + Auth + RLS + Storage) |
| UI | Material Design 3, GoogleFonts.inter |
| PDF генерация | pdf ^3.11.3 |
| CSV генерация | csv ^6.0.0 |
| File sharing (mobile) | share_plus ^10.1.4, path_provider ^2.1.5 |
| Деплой | GitHub Pages (web), iOS Simulator |

## Дизайн (обновлён Марией)

- Зелёно-белая тема с Material 3
- primary = `#0B8457` (emerald), primaryLight = `#10B981`
- Шрифт: Inter (GoogleFonts.inter)
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
│   ├── profile.dart                   # UserRole enum + Profile (isManager, canManageRecipes)
│   ├── business.dart                  # Business
│   ├── checklist.dart                 # ChecklistTemplate, Item, Completion, Response
│   ├── recipe.dart                    # Recipe (+dietary getters: isVegetarian/isVegan/isGlutenFree/isDairyFree/dietaryLabels), Ingredient, RecipeIngredient
│   ├── menu_item.dart                 # MenuItem
│   ├── incident.dart                  # Incident (status, resolvedBy, resolvedAt, resolvedNotes)
│   ├── supplier.dart                  # Supplier
│   ├── notification.dart              # AppNotification
│   ├── diary_entry.dart               # DiaryEntry (legacy, не используется)
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
│   │   ├── checklists_screen.dart     # Список шаблонов + edit/delete (manager)
│   │   ├── checklist_detail_screen.dart # Заполнение + activate/deactivate/delete/history
│   │   ├── checklist_manage_screen.dart # Создание шаблона
│   │   └── checklist_history_screen.dart # История заполнений (expandable cards)
│   ├── recipes/
│   │   ├── recipes_screen.dart        # Список (active + inactive section)
│   │   ├── recipe_detail_screen.dart  # Просмотр + edit/deactivate/delete
│   │   ├── recipe_new_screen.dart     # Создание рецепта
│   │   └── recipe_edit_screen.dart    # Редактирование рецепта
│   ├── menu/
│   │   └── allergen_matrix_screen.dart # Матрица аллергенов
│   ├── diary/
│   │   └── diary_screen.dart          # Daily Diary — агрегатор событий за день + экспорт
│   ├── incidents/
│   │   └── incidents_screen.dart      # Инциденты: filter tabs, status, resolve, edit/delete
│   ├── suppliers/
│   │   └── suppliers_screen.dart      # Поставщики: add/edit/delete (manager)
│   ├── team/
│   │   └── team_screen.dart           # Команда + приглашения
│   ├── documents/
│   │   ├── documents_screen.dart      # Список документов + фильтр
│   │   ├── document_upload_screen.dart # Загрузка документа
│   │   └── document_detail_screen.dart # Просмотр + управление доступом
│   ├── notifications/
│   │   └── notifications_screen.dart  # Уведомления
│   └── ai_import/
│       └── ai_import_screen.dart      # AI Recipe Import (text/PDF → Claude API → structured recipe)
├── utils/
│   ├── diary_export.dart              # PDF/CSV генерация дневника + кроссплатформенный download/share
│   ├── menu_export.dart               # PDF/CSV экспорт меню с dietary labels и аллергенами
│   ├── file_saver_stub.dart           # Stub для conditional import
│   ├── file_saver_web.dart            # Web: dart:html Blob + AnchorElement download
│   └── file_saver_mobile.dart         # Mobile: path_provider + share_plus
└── widgets/
    ├── allergen_badge.dart            # Бейдж аллергена с эмодзи
    └── app_scaffold.dart              # Bottom nav + shell

supabase/
└── functions/
    └── import-recipe/
        └── index.ts                   # Edge Function: text/PDF → Claude API → structured recipe JSON
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
    /checklists/:id/history → ChecklistHistoryScreen
  /recipes                → RecipesScreen
    /recipes/new          → RecipeNewScreen
    /recipes/edit/:id     → RecipeEditScreen
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
  /ai-import              → AiImportScreen
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
| `checklistCompletionsProvider` | `FutureProvider` (в checklists_screen) | Все последние completions для статусов |
| `completionHistoryProvider` | `FutureProvider.family<CompletionHistoryData, String>` | История заполнений чеклиста |
| `recipesProvider` | `FutureProvider` (в экране) | Рецепты с ингредиентами |
| `diaryChecklistsProvider` | `FutureProvider.family<List<ChecklistCompletion>, String>` | Чеклисты завершённые за дату |
| `diaryIncidentsProvider` | `FutureProvider.family<List<Incident>, String>` | Инциденты за дату |
| `incidentsProvider` | `FutureProvider` (в экране) | Инциденты с joined profiles |
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
| supervisor_role | TEXT | Роль супервайзера для sign-off (NULL = не требуется) |

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
| signed_off_at | TIMESTAMPTZ | Когда подписано |
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
| active | BOOLEAN | Деактивированные скрыты из меню |

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
| follow_up | TEXT | Что сделать для предотвращения |
| reported_by | UUID NOT NULL | FK → profiles |
| date | DATE NOT NULL | |
| business_id | UUID NOT NULL | FK |
| status | TEXT DEFAULT 'open' | open/resolved |
| resolved_by | UUID | FK → profiles — кто закрыл |
| resolved_at | TIMESTAMPTZ | Когда закрыт |
| resolved_notes | TEXT | Как был решён |
| updated_at | TIMESTAMPTZ | Последнее обновление |

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

#### 19. `four_weekly_reviews` (не используется в мобильном)
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID PK | |
| business_id | UUID NOT NULL | FK |
| period_start / period_end | DATE | Период |
| summary | TEXT | |
| action_items | JSONB | Список действий |
| reviewed_by | UUID | FK → profiles |
| reviewed_at | TIMESTAMPTZ | |

#### 20. `notification_rules` (не используется в мобильном)
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
| checklist_completions | Свой бизнес | Свой (completed_by) | Sign-off (supervisor) | — |
| checklist_responses | Через completions (subquery) | Свой бизнес | — | — |
| recipes | Свой бизнес | Chef/Manager/Owner | Chef/Manager/Owner | Chef/Manager/Owner |
| ingredients | Свой бизнес + глобальные | Chef/Manager/Owner | Chef/Manager/Owner | Chef/Manager/Owner |
| suppliers | Свой бизнес | Manager/Owner | Manager/Owner | Manager/Owner |
| incidents | Свой бизнес | Свой (reported_by) | Manager/Owner (для resolve) | Manager/Owner |
| diary_entries | Свой бизнес | Свой бизнес | Свой бизнес | Свой бизнес |
| documents | По access_level + role | Manager/Owner | Owner + uploaded_by | Owner |
| document_access | Открытый SELECT (данные scoped) | Manager/Owner | — | Owner |
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
| Просмотр истории чеклистов | ✅ | ✅ | ❌ | ❌ | ❌ |
| Создать/edit рецепт | ✅ | ✅ | ✅ | ❌ | ❌ |
| Деактивировать/удалить рецепт | ✅ | ✅ | ✅ | ❌ | ❌ |
| Управлять поставщиками | ✅ | ✅ | ❌ | ❌ | ❌ |
| Пригласить в команду | ✅ | ✅ | ❌ | ❌ | ❌ |
| Создать инцидент | ✅ | ✅ | ✅ | ✅ | ✅ |
| Resolve/reopen инцидент | ✅ | ✅ | ❌ | ❌ | ❌ |
| Edit/delete инцидент | ✅ | ✅ | ❌ | ❌ | ❌ |
| Вести дневник | ✅ | ✅ | ✅ | ✅ | ✅ |
| Загружать документы | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## Статус функций

### ✅ Полностью реализовано

1. **Auth** — Login, Register, Setup (Create Business / Join Team)
2. **Dashboard** — Статистика (overview grid), quick actions
3. **Чеклисты** — Список со статусами (Pending/Completed/Awaiting Sign-off/Signed Off), visibility по ролям (owner=все, остальные=assigned+supervised), создание с supervisor role, заполнение (tick/temp/text/yes_no), sign-off workflow, activate/deactivate, delete
4. **История чеклистов** — Expandable cards с ответами, sign-off status chips, flagged items
5. **Рецепты** — Список (active/inactive sections), создание, edit, deactivate, delete, dietary badges (Vegetarian/Vegan/GF/DF)
6. **Аллергены** — Матрица 14 аллергенов × рецепты, бейджи с эмодзи, dietary classification
7. **Экспорт меню** — PDF/CSV с группировкой по категориям, dietary labels, опциональные аллергены (menu_export.dart)
8. **Дневник (Daily Diary)** — Агрегатор событий за день: чеклисты + инциденты с карточками, навигация по датам, экспорт отчёта (PDF/CSV) за период с выбором включаемых секций
9. **Инциденты** — Список с фильтрами (All/Open/Resolved), создание, edit, delete, resolve/reopen, follow-up, timestamps, resolution info
10. **Поставщики** — Список, add/edit/delete (manager only)
11. **Команда** — Список участников, приглашение по токену
12. **Уведомления** — Список, прочитано/не прочитано, отметка как прочитанное
13. **Документы** — Загрузка файлов (PDF, JPG, DOCX, XLSX), категории, поиск, управление доступом (all/managers/owner/custom), срок действия

### 🟡 Частично

- **Меню** — матрица аллергенов + экспорт есть, но нет управления menu_items
- **Уведомления** — отображение есть, но нет автоматической генерации
- **AI Import рецептов** — ✅ Работает! Три режима ввода: текст, PDF, фото. Edge Function задеплоена с `--no-verify-jwt`. Опциональный video URL сохраняется.

### ❌ Не реализовано

#### Средний приоритет
- [ ] **Menu Builder** — активация/деактивация блюд в меню, категории
- [ ] **Редактирование профиля** — смена имени, аватара
- [ ] **Настройки бизнеса** — редактирование адреса, названия
- [ ] **Staff Training Records** — обучение сотрудников (таблица есть в БД)
- [ ] **4-Weekly Review** — ревью за 4 недели (таблица есть в БД)
- [x] **PDF/CSV экспорт дневника** — реализовано в diary_export.dart
- [x] **PDF/CSV экспорт меню** — реализовано в menu_export.dart
- [ ] **PDF экспорт чеклистов** — отдельный экспорт чеклистов
- [ ] **Quick Allergen Lookup** — поиск аллергенов по блюду
- [ ] **Редактирование шаблона чеклиста** — edit существующего (кнопка есть, показывает "Coming soon")
- [ ] **Logout** — кнопка выхода из аккаунта

#### Низкий приоритет
- [ ] **Push уведомления** — FCM, email, авто-напоминания
- [ ] **Notification Rules** — настройка правил уведомлений
- [ ] **Фото рецептов** — загрузка в Supabase Storage
- [ ] **Cleaning Schedule** — расписание уборки
- [ ] **Pest Control** — контроль вредителей
- [ ] **Recipe Versioning** — версионирование рецептов
- [ ] **Supplier Approval** — утверждение поставщиков

---

## Ключевые решения и заметки

### Supabase
- **Anon key захардкожен** в `supabase.dart` (публичный ключ, безопасно)
- **Service role key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzenJnZ3JldWFydm9kY3FlcXJqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzU3NjY3NiwiZXhwIjoyMDg5MTUyNjc2fQ.gcQOi5ifm_pZc-4Onu_qsC36xnWPisCrZnyIuCfVROY`
- **Management API token:** `sbp_6d5c5011c0cdbb2f558a4bf2268609f8da2ec0f0`
- **Email confirmation отключен** (`mailer_autoconfirm: true`) — для тестирования
- **RPC-функции** (`setup_business`, `join_with_invite`) обходят RLS
- **RLS-хелперы** (`get_my_business_id()`, `get_my_role()`) — SECURITY DEFINER
- **Storage bucket** `documents` — private, max 10 MB, PDF/JPG/PNG/DOCX/XLSX
- **Edge Functions** — `import-recipe` (Deno.serve, Claude API для анализа рецептов)
- **Anthropic API key** — сохранён как Supabase secret `ANTHROPIC_API_KEY`
- **Supabase project ref:** `rszrggreuarvodcqeqrj`
- **RLS gotcha:** `.eq()` ДОЛЖЕН быть ДО `.order()` в цепочке Supabase запросов
- **RLS gotcha:** Circular policies (A → B → A) вызывают infinite recursion. Решение: сделать одну из них открытой (`USING (true)`)
- **PostgreSQL:** `CREATE POLICY IF NOT EXISTS` не работает. Используй `DROP POLICY IF EXISTS` + `CREATE POLICY`

### Flutter
- **ВАЖНО: Язык интерфейса — ТОЛЬКО АНГЛИЙСКИЙ!** Все labels, buttons, messages, placeholders — на английском. Без русского текста в UI!
- **Riverpod 3.x** — используем `Notifier`, НЕ `StateNotifier`; `.value` НЕ `.valueOrNull`
- **GoRouter** — используем `context.go()` для навигации
- **FutureProvider.family** — НЕ использовать Dart Record types как generic. Используй обычный класс (пример: `CompletionHistoryData`)
- **GoogleFonts.inter** — основной шрифт после редизайна Марии (НЕ Outfit)
- **flutter_dotenv удалён** — ключи захардкожены (GitHub Pages блокирует .env файлы)
- **Inactive recipes** — показываются внизу списка с 55% opacity, видны только chef/manager/owner
- **Checklist visibility** — Owner видит все; остальные видят чеклисты по assigned_roles + supervisor_role + неназначенные
- **Checklist sign-off** — если у чеклиста задан supervisor_role, после заполнения показывается "Awaiting Sign-off"; пользователь с этой ролью может подписать
- **Diary screen** — больше НЕ использует diary_entries, opening/closing checks убраны; агрегирует checklist_completions + incidents за день
- **PDF/CSV export** — conditional import (dart:html для web, share_plus для mobile); файлы file_saver_*.dart
- **Dashboard** — Today's Tasks плашка убрана (opening/closing checks перенесены в чеклисты)
- **Dietary labels** — Автоматическая классификация рецептов (Vegetarian, Vegan, GF, DF) на основе EU 14 аллергенов. Цветные бейджи на карточках и в detail view.
- **Menu export** — PDF/CSV с группировкой по категории, dietary labels, опциональные аллергены. Экспорт через FAB на allergen_matrix_screen.
- **AI Import** — Три режима: Text / PDF / Photo → Supabase Edge Function → Claude API (claude-sonnet-4-20250514) → structured recipe JSON. Опциональный video URL сохраняется в source_video_url. Фото (JPG/PNG/WebP до 10 MB) отправляется как `type: "image"`, PDF как `type: "document"`.
- **Edge Functions** — используем `Deno.serve()` (НЕ старый `import { serve }`), `anthropic-version: "2023-06-01"`, `anthropic-beta: "pdfs-2024-09-25"`. Деплой с `--no-verify-jwt`.

### Деплой
- **GitHub Pages** — gh-pages branch содержит ТОЛЬКО `build/web/` contents
- **Base href** — `flutter build web --release --base-href "/haccp-mobile/"` (ОБЯЗАТЕЛЬНО!)
- **Деплой web:** Использовать ОТДЕЛЬНЫЙ клон для gh-pages (НЕ checkout в том же рабочем каталоге — иначе untracked файлы Flutter попадут в gh-pages)
- **Деплой Edge Functions:** `supabase functions deploy import-recipe --project-ref rszrggreuarvodcqeqrj --no-verify-jwt`
- **iOS Simulator** — `flutter run` запускает на подключённом симуляторе
- **Apple Developer Account** — ожидает регистрации для TestFlight/App Store
- **Flutter service worker** — агрессивно кеширует; для проверки обновлений нужен Clear site data в DevTools

---

## Команды для разработки

```bash
# Запуск на iOS-симуляторе
cd /Users/knstntn/HACCP/haccp-mobile
flutter run

# Сборка для веба
flutter build web --release --base-href "/haccp-mobile/"

# Деплой на GitHub Pages (через отдельный клон — ВАЖНО!)
rm -rf /tmp/haccp-web-build /tmp/haccp-gh-pages
cp -r build/web /tmp/haccp-web-build
git clone --branch gh-pages --single-branch https://github.com/KNSTNTN24/haccp-mobile.git /tmp/haccp-gh-pages
cd /tmp/haccp-gh-pages
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} +
cp -r /tmp/haccp-web-build/* .
git add -A && git commit -m "Deploy: описание" && git push origin gh-pages

# Деплой Edge Functions
supabase functions deploy import-recipe --project-ref rszrggreuarvodcqeqrj

# Подтянуть изменения
git fetch origin && git pull origin main

# SQL запрос к Supabase через Management API
curl -s -X POST \
  "https://api.supabase.com/v1/projects/rszrggreuarvodcqeqrj/database/query" \
  -H "Authorization: Bearer sbp_6d5c5011c0cdbb2f558a4bf2268609f8da2ec0f0" \
  -H "Content-Type: application/json" \
  --data '{"query": "SELECT ..."}'
```

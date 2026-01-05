# Finance Assistant - Project Context

## Overview

**Finance Assistant** is an AI-Powered Personal Finance Assistant mobile application built with Flutter. It showcases practical AI integration, solves real-world financial management problems, and demonstrates full-stack mobile development skills.

## Purpose

Help users manage their personal finances through:
- Intelligent expense tracking and categorization
- AI-powered insights and recommendations
- Visual analytics and budget management
- Offline-first architecture with cloud sync

## Target Users

- Individuals seeking better control over personal finances
- Users who want automated expense categorization
- People who prefer conversational interfaces for data queries
- Users who need receipt scanning for expense tracking

---

## Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile development |
| **Dart** | Programming language |
| **BLoC** | State management pattern |
| **Drift** | Local SQLite database |

### Backend
| Technology | Purpose |
|------------|---------|
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Remote database & sync |
| **Cloud Functions** | AI processing, serverless backend |
| **Firebase ML** | On-device ML capabilities |

### AI/ML Services
| Service | Use Case |
|---------|----------|
| **Google Gemini API** | Conversational AI, insights generation |
| **OpenAI GPT-4** | Alternative chat & analysis |
| **Google ML Kit** | On-device OCR for receipts |
| **TensorFlow Lite** | On-device expense categorization |

---

## Core Features

### AI-Powered Features
1. **Smart Expense Categorization** - Auto-categorize transactions using NLP
2. **Spending Pattern Analysis** - ML-based insights on spending habits
3. **Budget Recommendations** - AI suggests personalized budgets
4. **Receipt Scanner (OCR)** - Extract data from receipts
5. **Conversational Interface** - Natural language queries
6. **Anomaly Detection** - Alert unusual spending patterns

### Standard Features
1. Manual expense/income tracking
2. Visual dashboards with charts
3. Multiple account support
4. Recurring transactions
5. Export reports (PDF/CSV)
6. Dark/Light theme
7. Biometric authentication

---

## Architecture Overview

The app follows **Clean Architecture** principles with three main layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (UI, Widgets, Screens, BLoC)                               │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  (Entities, Use Cases, Repository Interfaces)               │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  (Models, Repositories, DataSources, Services)              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow
```
UI → BLoC → UseCase → Repository → DataSource → Database/API
```

### Offline-First Strategy
1. All data writes go to local Drift database first
2. Changes are queued in `sync_queue` table
3. Background sync pushes changes to Firestore
4. Conflict resolution uses timestamp-based strategy
5. UI always reads from local database for instant response

---

## Database Schema

### Core Tables
- **Users** - User profile and settings
- **Accounts** - Bank accounts, wallets, cards
- **Categories** - Expense/income categories (system + custom)
- **Transactions** - All financial transactions
- **Budgets** - Budget limits per category/period
- **RecurringRules** - Recurring transaction definitions
- **Receipts** - OCR-scanned receipt data
- **ChatHistory** - AI conversation logs
- **SyncQueue** - Offline sync queue

### Sync Status Values
- `synced` - Synchronized with remote
- `pending` - Local changes awaiting sync
- `failed` - Sync failed, needs retry
- `syncing` - Currently being synced
- `conflict` - Requires conflict resolution

---

## Project Structure

```
lib/
├── core/                      # Shared utilities & config
│   ├── constants/             # App-wide constants
│   │   ├── app_constants.dart
│   │   ├── database_constants.dart
│   │   └── icon_constants.dart    # Centralized icon mapping (140+ icons)
│   ├── errors/                # Error handling
│   │   ├── failures.dart      # Failure types (Either Left)
│   │   ├── exceptions.dart    # Exception classes
│   │   └── errors.dart        # Barrel export
│   ├── sync/                  # Offline-first sync system
│   │   ├── sync_manager.dart
│   │   ├── sync_queue_processor.dart
│   │   ├── conflict_resolver.dart
│   │   ├── connectivity_service.dart
│   │   ├── sync_status_notifier.dart
│   │   ├── sync_repository.dart
│   │   ├── sync_trigger.dart
│   │   └── sync.dart          # Barrel export
│   ├── themes/                # Theme configuration
│   │   └── app_theme.dart
│   ├── utils/                 # Helper functions
│   └── di/                    # Dependency injection
│       └── injection_container.dart  # GetIt service locator setup
│
├── data/                      # Data layer
│   ├── models/                # Data models (JSON serializable)
│   │   ├── user_model.dart
│   │   ├── account_model.dart
│   │   ├── category_model.dart
│   │   ├── transaction_model.dart
│   │   ├── budget_model.dart
│   │   ├── recurring_rule_model.dart
│   │   ├── receipt_model.dart
│   │   ├── chat_message_model.dart
│   │   └── models.dart        # Barrel export
│   ├── repositories/          # Repository implementations (ALL COMPLETE)
│   │   ├── account_repository_impl.dart
│   │   ├── auth_repository_impl.dart
│   │   ├── budget_repository_impl.dart
│   │   ├── category_repository_impl.dart
│   │   ├── chat_repository_impl.dart
│   │   ├── mock_auth_repository.dart   # Mock for UI testing
│   │   ├── receipt_repository_impl.dart
│   │   ├── recurring_rule_repository_impl.dart
│   │   ├── sync_repository_impl.dart
│   │   ├── transaction_repository_impl.dart
│   │   └── user_repository_impl.dart
│   ├── datasources/
│   │   ├── local/             # Drift database
│   │   │   ├── app_database.dart        # Main database class
│   │   │   ├── app_database.g.dart      # Generated code
│   │   │   ├── tables/
│   │   │   │   └── tables.dart          # All 11 table definitions
│   │   │   └── daos/                    # Data Access Objects
│   │   │       ├── daos.dart            # Barrel export
│   │   │       ├── users_dao.dart
│   │   │       ├── accounts_dao.dart
│   │   │       ├── categories_dao.dart
│   │   │       ├── transactions_dao.dart
│   │   │       ├── budgets_dao.dart
│   │   │       ├── recurring_rules_dao.dart
│   │   │       ├── receipts_dao.dart
│   │   │       ├── chat_dao.dart
│   │   │       └── sync_queue_dao.dart
│   │   └── remote/            # Firebase remote datasources
│   │       ├── remote.dart              # Barrel export
│   │       ├── firebase_service.dart    # Core Firebase service
│   │       ├── user_remote_datasource.dart
│   │       ├── account_remote_datasource.dart
│   │       ├── category_remote_datasource.dart
│   │       ├── transaction_remote_datasource.dart
│   │       ├── budget_remote_datasource.dart
│   │       ├── recurring_rule_remote_datasource.dart
│   │       ├── receipt_remote_datasource.dart
│   │       └── chat_remote_datasource.dart
│   └── services/
│       └── ai_service.dart    # AI service integrations
│
├── domain/                    # Domain layer (pure Dart)
│   ├── entities/              # Business entities
│   │   ├── user.dart
│   │   ├── account.dart
│   │   ├── category.dart
│   │   ├── transaction.dart
│   │   ├── budget.dart
│   │   ├── recurring_rule.dart
│   │   ├── receipt.dart
│   │   ├── chat_message.dart
│   │   └── entities.dart      # Barrel export
│   ├── repositories/          # Repository interfaces
│   │   ├── user_repository.dart
│   │   ├── account_repository.dart
│   │   ├── category_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── budget_repository.dart
│   │   ├── recurring_rule_repository.dart
│   │   ├── receipt_repository.dart
│   │   ├── chat_repository.dart
│   │   ├── auth_repository.dart
│   │   └── repositories.dart  # Barrel export
│   └── usecases/              # Business logic (109 USE CASES COMPLETE)
│       ├── usecase.dart           # Base UseCase class
│       ├── usecases.dart          # Barrel export
│       ├── transaction/           # 5 use cases
│       │   ├── transaction_usecases.dart
│       │   ├── create_transaction.dart
│       │   ├── get_transactions_by_date_range.dart
│       │   ├── get_spending_summary.dart
│       │   └── watch_recent_transactions.dart
│       ├── account/               # 7 use cases
│       │   ├── account_usecases.dart
│       │   ├── create_account.dart
│       │   ├── delete_account.dart
│       │   ├── get_accounts.dart
│       │   ├── get_net_worth.dart
│       │   ├── update_account_balance.dart
│       │   └── watch_accounts.dart
│       ├── auth/                  # 20 use cases
│       │   ├── auth_usecases.dart
│       │   ├── sign_in_with_email.dart
│       │   ├── sign_in_with_social.dart
│       │   ├── register_with_email.dart
│       │   ├── password_management.dart
│       │   ├── auth_state.dart
│       │   ├── biometric_auth.dart
│       │   └── account_management.dart
│       ├── budget/                # 9 use cases
│       │   ├── budget_usecases.dart
│       │   ├── create_budget.dart
│       │   ├── get_budgets.dart
│       │   ├── get_budgets_with_relations.dart  # Use Case Composition
│       │   ├── get_budget_summary.dart
│       │   ├── update_budget.dart
│       │   ├── watch_budgets.dart
│       │   └── check_budget_status.dart
│       ├── category/              # 6 use cases
│       │   ├── category_usecases.dart
│       │   ├── create_category.dart
│       │   ├── get_categories.dart
│       │   ├── update_category.dart
│       │   ├── search_categories.dart
│       │   └── initialize_categories.dart
│       ├── user/                  # 1 use case
│       │   ├── user_usecases.dart
│       │   └── ensure_user_exists.dart
│       ├── receipt/               # 7 use cases
│       │   ├── receipt_usecases.dart
│       │   ├── scan_receipt.dart
│       │   ├── process_receipt_ocr.dart
│       │   ├── get_receipts.dart
│       │   ├── link_receipt.dart
│       │   └── delete_receipt.dart
│       └── chat/                  # 56 use cases
│           ├── chat_usecases.dart
│           ├── send_chat_message.dart
│           ├── manage_sessions.dart
│           ├── manage_messages.dart
│           ├── watch_chat.dart
│           ├── search_messages.dart
│           ├── clear_chat_history.dart
│           └── chat_analytics.dart
│
├── presentation/              # Presentation layer
│   ├── screens/               # Feature screens
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   ├── auth/                          # AUTH SCREENS (COMPLETE)
│   │   │   ├── auth_screens.dart          # Barrel export
│   │   │   ├── login_screen.dart          # Login UI with BLoC
│   │   │   ├── register_screen.dart       # Registration with password strength
│   │   │   ├── forgot_password_screen.dart # Password reset flow
│   │   │   └── widgets/
│   │   │       ├── auth_widgets.dart      # Barrel export
│   │   │       ├── auth_text_field.dart   # Custom styled text field
│   │   │       ├── social_sign_in_button.dart # Google/Apple buttons
│   │   │       └── password_strength_indicator.dart
│   │   ├── splash/                        # SPLASH SCREEN (COMPLETE)
│   │   │   ├── splash.dart                # Barrel export
│   │   │   └── splash_screen.dart         # Animated splash with auth check
│   │   ├── main/                          # MAIN SCREEN (COMPLETE)
│   │   │   ├── main.dart                  # Barrel export
│   │   │   ├── main_screen.dart           # Bottom nav container (4 tabs)
│   │   │   └── widgets/
│   │   │       ├── main_widgets.dart      # Barrel export
│   │   │       └── main_bottom_nav.dart   # Custom bottom nav with FAB notch
│   │   ├── budget/                        # BUDGET SCREENS (COMPLETE)
│   │   │   ├── budget.dart                # Barrel export
│   │   │   ├── budget_list_screen.dart    # Main list with summary & alerts
│   │   │   ├── budget_detail_screen.dart  # Detail view with stats
│   │   │   └── widgets/
│   │   │       ├── budget_widgets.dart    # Barrel export
│   │   │       ├── budget_item_card.dart  # Individual budget card with category icon
│   │   │       ├── budget_summary_card.dart # Summary with circular progress
│   │   │       └── create_budget_sheet.dart # Create/Edit with CategorySelector
│   │   ├── transactions/
│   │   ├── analytics/
│   │   ├── chat/
│   │   └── settings/
│   ├── widgets/               # Reusable widgets
│   │   ├── glass_card.dart
│   │   ├── category_selector.dart         # Reusable category picker widget
│   │   ├── icon_picker.dart               # Icon picker with search & grid
│   │   └── create_category_sheet.dart     # Custom category creation form
│   └── bloc/                  # State management
│       ├── auth/                          # AUTH BLOC (COMPLETE)
│       │   ├── auth_bloc_exports.dart     # Barrel export
│       │   ├── auth_event.dart            # 11 auth events
│       │   ├── auth_state.dart            # 8 auth states + AuthErrorType
│       │   └── auth_bloc.dart             # Full BLoC with all handlers
│       ├── budget/                        # BUDGET BLOC (COMPLETE)
│       │   ├── budget_bloc_exports.dart   # Barrel export
│       │   ├── budget_event.dart          # 16 budget events
│       │   ├── budget_state.dart          # 7 states + BudgetOperationType, BudgetErrorType
│       │   └── budget_bloc.dart           # Full BLoC with Use Case Composition
│       ├── category/                      # CATEGORY BLOC (COMPLETE)
│       │   ├── category_bloc_exports.dart # Barrel export
│       │   ├── category_event.dart        # 18 category events
│       │   ├── category_state.dart        # 5 category states + CategoryErrorType
│       │   └── category_bloc.dart         # Full BLoC with watch and search
│       └── sync/                          # SYNC BLOC (COMPLETE)
│           ├── sync_bloc_exports.dart     # Barrel export
│           ├── sync_event.dart            # 7 sync events (SyncStatus enum)
│           ├── sync_state.dart            # 6 sync states + SyncErrorType
│           └── sync_bloc.dart             # Full BLoC with SyncManager integration
│
└── main.dart                  # App entry point with BlocProvider
```

---

## Current Implementation Status

### ✅ Completed
- [x] Project structure setup
- [x] Core constants (`app_constants.dart`, `database_constants.dart`)
- [x] Core errors module (`failures.dart`, `exceptions.dart`)
- [x] Theme system (`app_theme.dart` - Light/Dark)
- [x] Sync manager (`sync_manager.dart`, queue, conflict resolver, etc.)
- [x] Dashboard UI (`dashboard_screen.dart` + widgets)
- [x] Domain entities (User, Account, Category, Transaction, Budget, RecurringRule, Receipt, ChatMessage)
- [x] Domain repository interfaces (9 repositories)
- [x] Asset folders structure
- [x] **Data layer models** (8 JSON-serializable models with Firestore support)
- [x] **Drift database setup** (`app_database.dart` with migrations)
- [x] **Drift tables** (11 tables defined in `tables.dart`)
- [x] **DAOs** (9 Data Access Objects with full CRUD operations)
- [x] **Remote Datasources** (8 Firebase/Firestore datasources + FirebaseService)
- [x] **Sync Repository Implementation** (`sync_repository_impl.dart` - bridges local & remote)
- [x] **All Repository Implementations** (10 complete repository implementations including mock)
- [x] **Domain Use Cases** (108 use cases across 7 features - ALL COMPLETE)
- [x] **Auth BLoC** (Events, States, BLoC with all auth handlers)
- [x] **Auth Screens** (Login, Register, Forgot Password with custom widgets)
- [x] **Dependency Injection** (`injection_container.dart` with GetIt - FULLY CONFIGURED)
- [x] **Firebase Auth Repository** (`auth_repository_impl.dart` with Google/Apple Sign-In)
- [x] **Splash Screen** (`splash_screen.dart` with animations and auth state check)
- [x] **Main Screen** (`main_screen.dart` with bottom navigation and 4 tabs)
- [x] **Budget BLoC** (16 events, 7 states, full BLoC with Use Case Composition)
- [x] **Budget Screens** (BudgetListScreen, BudgetDetailScreen with glassmorphism UI)
- [x] **Budget Widgets** (BudgetItemCard with category icon, BudgetSummaryCard, CreateBudgetSheet with CategorySelector)
- [x] **Category BLoC** (18 events, 5 states, full BLoC with watch and search)
- [x] **Sync BLoC** (7 events, 6 states, full BLoC with SyncManager and ConnectivityService integration)
- [x] **CategorySelector Widget** (Reusable category picker with icon grid)
- [x] **Use Case Composition** (GetBudgetsWithRelationsUseCase - joins Budget + Category)

### ✅ Repository Implementations (All Complete)

| Repository | Lines | Key Features |
|------------|-------|--------------|
| `account_repository_impl.dart` | ~450 | CRUD, balance updates, account types, net worth calculation, sync |
| `auth_repository_impl.dart` | ~650 | Firebase Auth, email/Google/Apple sign-in, password reset, biometrics, nonce generation |
| `budget_repository_impl.dart` | ~600 | CRUD, period-based queries, spending tracking, utilization, alerts |
| `category_repository_impl.dart` | ~600 | CRUD, type filtering, default categories, search, icons, sync |
| `chat_repository_impl.dart` | ~1000 | Sessions, messages, Gemini AI integration, streaming, analytics |
| `receipt_repository_impl.dart` | ~1230 | CRUD, image upload, ML Kit OCR, text parsing, transaction linking |
| `recurring_rule_repository_impl.dart` | ~650 | CRUD, rule management, processing, projections, scheduling |
| `transaction_repository_impl.dart` | ~995 | CRUD, filtering, search, aggregations, recurring, analytics |
| `user_repository_impl.dart` | ~450 | CRUD, preferences, theme, biometrics, current user, sync |
| `mock_auth_repository.dart` | ~160 | Mock implementation for UI testing without Firebase |

### ✅ Domain Use Cases (109 Total - All Complete)

| Feature | Use Cases | Files |
|---------|-----------|-------|
| **Transaction** | 5 | `create_transaction`, `get_transactions_by_date_range`, `get_spending_summary`, `watch_recent_transactions` |
| **Account** | 7 | `create_account`, `delete_account`, `get_accounts`, `get_net_worth`, `update_account_balance`, `watch_accounts` |
| **Auth** | 20 | `sign_in_with_email`, `sign_in_with_social` (Google, Apple), `register_with_email`, `password_management` (reset, update, confirm), `auth_state` (check, getCurrentUser, isAuthenticated, watch), `biometric_auth` (isAvailable, authenticate, getAvailable), `account_management` (updateEmail, deleteAccount, reauthenticate, sendVerification, isVerified, reload) |
| **Budget** | 9 | `create_budget`, `get_budgets`, `get_budgets_with_relations`, `watch_budgets_with_relations`, `get_budget_summary`, `update_budget`, `watch_budgets`, `check_budget_status` |
| **Category** | 6 | `create_category`, `get_categories`, `update_category`, `search_categories`, `initialize_categories` |
| **User** | 1 | `ensure_user_exists` (ensures user exists in local DB for FK constraints) |
| **Receipt** | 7 | `scan_receipt`, `process_receipt_ocr`, `get_receipts`, `link_receipt`, `delete_receipt` |
| **Chat** | 56 | `send_chat_message` (send, stream), `manage_sessions` (create, get, getAll, update, delete), `manage_messages` (add, update, delete, getBySession), `watch_chat` (messages, sessions, unread), `search_messages`, `clear_chat_history`, `chat_analytics` (getStats, getMostUsed, exportHistory) |

### ✅ Auth Presentation Layer (Complete)

| Component | Description |
|-----------|-------------|
| **AuthBloc** | Full BLoC with 11 events, 8 states, AuthErrorType enum for user-friendly messages |
| **LoginScreen** | Email/password form, Google/Apple sign-in buttons, forgot password link |
| **RegisterScreen** | Email/password form with password strength indicator, terms checkbox |
| **ForgotPasswordScreen** | Email input, success state UI after email sent |
| **AuthTextField** | Custom styled text field with icons and validation |
| **SocialSignInButton** | Styled buttons for Google and Apple sign-in |
| **PasswordStrengthIndicator** | Visual password strength meter with criteria checklist |

### ✅ Navigation System (Complete)

| Component | Description |
|-----------|-------------|
| **SplashScreen** | Animated logo + tagline, checks auth state, routes to /main or /login |
| **MainScreen** | Bottom navigation container with IndexedStack for 4 tabs |
| **MainBottomNav** | Custom BottomAppBar with CircularNotchedRectangle for FAB |
| **FAB** | Floating action button with quick add menu (Expense, Income, Transfer, Scan) |

### Navigation Flow
```
App Start → SplashScreen
                ↓
        Auth Check (AuthBloc)
        ↓               ↓
    Authenticated    Unauthenticated
        ↓                   ↓
    MainScreen           LoginScreen
    (4 tabs)                 ↓
    ├─ Dashboard       RegisterScreen
    ├─ Transactions        ↓
    ├─ Budgets        ForgotPassword
    └─ Chat
```

### App Routes (main.dart)
| Route | Screen | Description |
|-------|--------|-------------|
| `/` | SplashScreen | Initial route, auth check |
| `/login` | LoginScreen | Email/password + social sign-in |
| `/register` | RegisterScreen | New user registration |
| `/forgot-password` | ForgotPasswordScreen | Password reset flow |
| `/main` | MainScreen | Main app with bottom navigation |

### ✅ Dependency Injection (Complete)

| Component | Registration Type |
|-----------|------------------|
| `AppDatabase` | `LazySingleton` (Drift local database) |
| `FirebaseService` | `LazySingleton` (shared Firebase service) |
| `BudgetRemoteDataSource` | `LazySingleton` (Firestore datasource) |
| `CategoryRemoteDataSource` | `LazySingleton` (Firestore datasource) |
| `UserRemoteDataSource` | `LazySingleton` (Firestore datasource) |
| `TransactionRemoteDataSource` | `LazySingleton` (Firestore datasource) |
| `AuthRepository` | `LazySingleton` (Firebase Auth) |
| `UserRepository` | `LazySingleton` (offline-first with sync) |
| `BudgetRepository` | `LazySingleton` (offline-first with sync) |
| `CategoryRepository` | `LazySingleton` (offline-first with sync, depends on UserRepository) |
| `TransactionRepository` | `LazySingleton` (offline-first with sync) |
| Auth Use Cases (13) | `LazySingleton` |
| User Use Cases (1) | `LazySingleton` (`EnsureUserExistsUseCase`) |
| Budget Use Cases (10) | `LazySingleton` (includes composed use cases) |
| Category Use Cases (9) | `LazySingleton` |
| Transaction Use Cases (4) | `LazySingleton` (`CreateTransaction`, `GetByDateRange`, `GetSpendingSummary`, `WatchRecent`) |
| `AuthBloc` | `Factory` (includes `EnsureUserExistsUseCase` for FK constraint handling) |
| `BudgetBloc` | `Factory` (uses GetBudgetsWithRelationsUseCase) |
| `CategoryBloc` | `Factory` (new instance per screen) |
| `TransactionBloc` | `Factory` (uses 4 transaction use cases) |
| `SyncBloc` | `Factory` (uses SyncManager and ConnectivityService) |

### ✅ Budget Presentation Layer (Complete)

| Component | Description |
|-----------|-------------|
| **BudgetBloc** | Full BLoC with 16 events, 7 states, uses Use Case Composition for category relations |
| **BudgetListScreen** | Main list with summary card, alert section, all budgets grid |
| **BudgetDetailScreen** | Expandable app bar with status color, progress, stats, period info |
| **BudgetItemCard** | Individual budget card with progress bar, category icon/color, alert badges |
| **BudgetSummaryCard** | Large circular progress indicator with stats row |
| **CreateBudgetSheet** | Bottom sheet form with CategorySelector, amount, period, alerts |
| **EditBudgetSheet** | Bottom sheet form for editing existing budgets |

### ✅ Category Presentation Layer (Complete)

| Component | Description |
|-----------|-------------|
| **CategoryBloc** | Full BLoC with 18 events, 5 states, CategoryErrorType enum |
| **CategorySelector** | Reusable widget with icon grid, search, and "+ Create New Category" option |
| **CreateCategorySheet** | Bottom sheet form for custom category creation with name, type, icon picker, color palette |
| **IconPickerBottomSheet** | Full-screen icon picker with search and grouped icons (10 categories, 140+ icons) |
| **IconPickerField** | Inline form field for selecting icons |
| **IconConstants** | Centralized icon mapping (`getIcon()`, `groupedIcons`) used across the app |

### ✅ Transaction Presentation Layer (Complete)

| Component | Description |
|-----------|-------------|
| **TransactionBloc** | Full BLoC with 4 use cases registered in DI |
| **TransactionListScreen** | Main list with filter bar, search, bulk actions, AI suggestions |
| **TransactionItemCard** | Individual transaction card with category icon, amount, merchant |
| **TransactionSummaryCard** | Summary showing income/expenses/net for period |
| **TransactionFilterBar** | Filter chips for type, date range, category |
| **CreateTransactionSheet** | Bottom sheet form for new transactions |
| **EditTransactionSheet** | Bottom sheet form for editing existing transactions |
| **TransactionDateHeader** | Grouped date headers with day totals |
| **TransactionChartCard** | Visual spending breakdown chart |
| **TransactionReceiptPreview** | Receipt image preview with OCR data |
| **TransactionQuickStatsRow** | Quick stats row for dashboard |
| **TransactionSkeletonLoader** | Loading skeleton animation |
| **TransactionEmptyState** | Empty state with illustration |
| **TransactionAiSuggestionCard** | AI-powered categorization suggestions |
| **TransactionRecurringBadge** | Badge for recurring transactions |
| **TransactionExportSheet** | Export options (CSV, PDF) |
| **TransactionBulkActionsBar** | Bulk selection actions (delete, categorize, export) |
| **TransactionSplitSheet** | Split transaction between categories |

### ✅ Sync Presentation Layer (Complete)

| Component | Description |
|-----------|-------------|
| **SyncBloc** | Full BLoC with 7 events, 6 states, SyncManager and ConnectivityService integration |
| **SyncEvent** | Events: `SyncInitialized`, `SyncAllRequested`, `SyncPushRequested`, `SyncPullRequested`, `SyncTableRequested`, `SyncRetryFailedRequested`, `SyncStateUpdated`, `SyncPendingCountRequested` |
| **SyncState** | States: `SyncInitial`, `SyncOffline`, `SyncInProgress`, `SyncCompleted`, `SyncPartialSuccess`, `SyncError` |
| **SyncErrorType** | Error types: `noConnection`, `serverError`, `authRequired`, `conflictError`, `unknown` |
| **DashboardScreen Sync UI** | Sync status indicator in app bar, sync button in popup menu, snackbar feedback for sync states |

### 🚧 In Progress
- [ ] Chat screens UI (placeholder in MainScreen)

### 📋 Planned
- [ ] Account BLoC state management
- [ ] Receipt BLoC state management
- [ ] Chat BLoC state management
- [ ] AI service integration refinement
- [ ] Chat interface UI (replace placeholder)
- [ ] Analytics charts
- [ ] Settings screen
- [ ] Account screens UI
- [ ] Profile/Account management screens
- [ ] Extend Use Case Composition with Transaction and Account relations

---

## Key Files Reference

### Core Layer
| File | Purpose |
|------|---------|
| `lib/core/constants/app_constants.dart` | App configuration, API endpoints, validation rules |
| `lib/core/constants/database_constants.dart` | Table names, column names, sync status values || `lib/core/constants/icon_constants.dart` | Centralized icon mapping (140+ Material icons in 10 categories) || `lib/core/errors/failures.dart` | Failure types for functional error handling |
| `lib/core/errors/exceptions.dart` | Exception classes for data layer |
| `lib/core/themes/app_theme.dart` | Light/dark themes, colors, text styles |
| `lib/core/sync/sync_manager.dart` | Orchestrates offline-first sync operations |
| `lib/core/sync/conflict_resolver.dart` | Handles sync conflicts resolution |

### Domain Layer
| File | Purpose |
|------|---------|
| `lib/domain/entities/entities.dart` | Barrel export for all entities |
| `lib/domain/entities/transaction.dart` | Transaction entity with type enum |
| `lib/domain/entities/account.dart` | Account entity with account types |
| `lib/domain/repositories/repositories.dart` | Barrel export for all repository interfaces |
| `lib/domain/repositories/transaction_repository.dart` | Transaction CRUD + analytics methods |

### Data Layer
| File | Purpose |
|------|---------|
| `lib/data/models/models.dart` | Barrel export for all data models |
| `lib/data/models/transaction_model.dart` | Transaction model with JSON/Firestore serialization |
| `lib/data/datasources/local/app_database.dart` | Main Drift database class with all tables and DAOs |
| `lib/data/datasources/local/tables/tables.dart` | All 11 Drift table definitions |
| `lib/data/datasources/local/daos/daos.dart` | Barrel export for all DAOs |
| `lib/data/datasources/local/daos/transactions_dao.dart` | Transaction CRUD + filtering methods |
| `lib/data/datasources/local/daos/sync_queue_dao.dart` | Sync queue management for offline-first |
| `lib/data/datasources/remote/remote.dart` | Barrel export for all remote datasources |
| `lib/data/datasources/remote/firebase_service.dart` | Core Firebase service with collection refs & error handling |
| `lib/data/datasources/remote/account_remote_datasource.dart` | Account Firestore CRUD operations |
| `lib/data/repositories/sync_repository_impl.dart` | SyncRepository implementation bridging local & remote |
| `lib/data/repositories/account_repository_impl.dart` | Account CRUD, balance, net worth with offline-first sync |
| `lib/data/repositories/auth_repository_impl.dart` | Firebase Auth, email/Google sign-in, biometrics |
| `lib/data/repositories/budget_repository_impl.dart` | Budget CRUD, spending tracking, utilization alerts |
| `lib/data/repositories/category_repository_impl.dart` | Category CRUD, defaults, search with sync |
| `lib/data/repositories/chat_repository_impl.dart` | Chat sessions, messages, Gemini AI streaming |
| `lib/data/repositories/receipt_repository_impl.dart` | Receipt CRUD, image upload, ML Kit OCR parsing |
| `lib/data/repositories/recurring_rule_repository_impl.dart` | Recurring rules, processing, projections |
| `lib/data/repositories/transaction_repository_impl.dart` | Transaction CRUD, filtering, aggregations |
| `lib/data/repositories/user_repository_impl.dart` | User profile, preferences, theme management |
### Presentation Layer
| File | Purpose |
|------|---------|
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Main dashboard UI with metrics, charts, transactions |
| `lib/presentation/widgets/glass_card.dart` | Glassmorphism card component |
| `lib/presentation/widgets/category_selector.dart` | Reusable category picker widget with icon grid |
| `lib/presentation/screens/auth/login_screen.dart` | Login screen with email/password + social sign-in |
| `lib/presentation/screens/auth/register_screen.dart` | Registration screen with password strength |
| `lib/presentation/screens/auth/forgot_password_screen.dart` | Password reset flow |
| `lib/presentation/screens/auth/widgets/auth_text_field.dart` | Custom styled auth input field |
| `lib/presentation/screens/auth/widgets/social_sign_in_button.dart` | Google/Apple sign-in buttons |
| `lib/presentation/screens/auth/widgets/password_strength_indicator.dart` | Password strength meter |
| `lib/presentation/screens/splash/splash_screen.dart` | Animated splash with auth state check, routes to /main or /login |
| `lib/presentation/screens/main/main_screen.dart` | Bottom navigation container with 4 tabs, FAB, and primary account loading |
| `lib/presentation/screens/main/widgets/main_bottom_nav.dart` | Custom BottomAppBar with FAB notch |
| `lib/presentation/screens/budget/budget_list_screen.dart` | Budget list with summary card, alerts, and all budgets |
| `lib/presentation/screens/budget/budget_detail_screen.dart` | Budget detail with expandable app bar and stats |
| `lib/presentation/screens/budget/widgets/budget_item_card.dart` | Individual budget card with category icon/color |
| `lib/presentation/screens/budget/widgets/budget_summary_card.dart` | Summary card with circular progress indicator |
| `lib/presentation/screens/budget/widgets/create_budget_sheet.dart` | Create/Edit budget with CategorySelector |
| `lib/presentation/screens/transaction/transaction_list_screen.dart` | Transaction list with filter, search, bulk actions |
| `lib/presentation/screens/transaction/widgets/transaction_item_card.dart` | Individual transaction card |
| `lib/presentation/screens/transaction/widgets/transaction_summary_card.dart` | Summary with income/expense/net |
| `lib/presentation/screens/transaction/widgets/transaction_filter_bar.dart` | Filter chips for type, date, category |
| `lib/presentation/screens/transaction/widgets/create_transaction_sheet.dart` | Create transaction bottom sheet |
| `lib/presentation/screens/transaction/widgets/edit_transaction_sheet.dart` | Edit transaction bottom sheet |
| `lib/presentation/screens/transaction/widgets/transaction_date_header.dart` | Date section headers |
| `lib/presentation/screens/transaction/widgets/transaction_chart_card.dart` | Spending breakdown chart |
| `lib/presentation/screens/transaction/widgets/transaction_receipt_preview.dart` | Receipt OCR preview |
| `lib/presentation/screens/transaction/widgets/transaction_quick_stats_row.dart` | Quick stats row |
| `lib/presentation/screens/transaction/widgets/transaction_skeleton_loader.dart` | Loading skeleton |
| `lib/presentation/screens/transaction/widgets/transaction_empty_state.dart` | Empty state UI |
| `lib/presentation/screens/transaction/widgets/transaction_ai_suggestion_card.dart` | AI categorization suggestions |
| `lib/presentation/screens/transaction/widgets/transaction_recurring_badge.dart` | Recurring transaction badge |
| `lib/presentation/screens/transaction/widgets/transaction_export_sheet.dart` | Export options sheet |
| `lib/presentation/screens/transaction/widgets/transaction_bulk_actions_bar.dart` | Bulk selection actions |
| `lib/presentation/screens/transaction/widgets/transaction_split_sheet.dart` | Split transaction sheet |
| `lib/presentation/bloc/auth/auth_bloc.dart` | Auth BLoC with all auth handlers |
| `lib/presentation/bloc/auth/auth_event.dart` | 11 auth events |
| `lib/presentation/bloc/auth/auth_state.dart` | 8 auth states + AuthErrorType enum |
| `lib/presentation/bloc/budget/budget_bloc.dart` | Budget BLoC with Use Case Composition for relations |
| `lib/presentation/bloc/budget/budget_event.dart` | 16 budget events (Load, CRUD, Status, Internal) |
| `lib/presentation/bloc/budget/budget_state.dart` | 7 budget states + BudgetOperationType, BudgetErrorType enums |
| `lib/presentation/bloc/category/category_bloc.dart` | Category BLoC with watch, search, and CRUD handlers |
| `lib/presentation/bloc/category/category_event.dart` | 18 category events |
| `lib/presentation/bloc/category/category_state.dart` | 5 category states + CategoryErrorType enum |
| `lib/presentation/bloc/transaction/transaction_bloc.dart` | Transaction BLoC with filtering, bulk actions |
| `lib/presentation/bloc/transaction/transaction_event.dart` | Transaction events (Load, Filter, CRUD, Bulk) |
| `lib/presentation/bloc/transaction/transaction_state.dart` | Transaction states + error handling |
| `lib/presentation/bloc/sync/sync_bloc.dart` | Sync BLoC with SyncManager, connectivity monitoring |
| `lib/presentation/bloc/sync/sync_event.dart` | 7 sync events (Initialized, AllRequested, Push, Pull, Table, Retry, StateUpdated) |
| `lib/presentation/bloc/sync/sync_state.dart` | 6 sync states (Initial, Offline, InProgress, Completed, PartialSuccess, Error) |

### Dependency Injection
| File | Purpose |
|------|---------|
| `lib/core/di/injection_container.dart` | GetIt service locator setup for repositories, use cases, and BLoCs |

### Domain Use Cases
| File | Purpose |
|------|---------|
| `lib/domain/usecases/usecase.dart` | Base UseCase abstract class |
| `lib/domain/usecases/auth/auth_usecases.dart` | Barrel export for all 20 auth use cases |
| `lib/domain/usecases/transaction/transaction_usecases.dart` | Barrel export for transaction use cases |
| `lib/domain/usecases/account/account_usecases.dart` | Barrel export for account use cases |
| `lib/domain/usecases/budget/budget_usecases.dart` | Barrel export for budget use cases (includes composed use cases) |
| `lib/domain/usecases/budget/get_budgets_with_relations.dart` | Use Case Composition: joins Budget + Category |
| `lib/domain/usecases/category/category_usecases.dart` | Barrel export for category use cases |
| `lib/domain/usecases/user/user_usecases.dart` | Barrel export for user use cases |
| `lib/domain/usecases/user/ensure_user_exists.dart` | Ensures user exists in local DB (called by AuthBloc after auth) |
| `lib/domain/usecases/receipt/receipt_usecases.dart` | Barrel export for receipt use cases |
| `lib/domain/usecases/chat/chat_usecases.dart` | Barrel export for all 56 chat use cases |

---

## Environment Variables (Required)

```env
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
FIREBASE_PROJECT_ID=your_project_id
```

---

## Changelog

### 2026-01-04: SyncBloc Implementation

**Feature**: Added SyncBloc for managing data synchronization state in the UI.

**Files Created**:
1. `lib/presentation/bloc/sync/sync_bloc.dart`
   - BLoC with SyncManager and ConnectivityService integration
   - Handles 8 event types for sync operations
   - Listens to SyncManager state stream and connectivity changes

2. `lib/presentation/bloc/sync/sync_event.dart`
   - 8 events: `SyncInitialized`, `SyncAllRequested`, `SyncPushRequested`, `SyncPullRequested`, `SyncTableRequested`, `SyncRetryFailedRequested`, `SyncStateUpdated`, `SyncPendingCountRequested`
   - `SyncStatus` enum for internal state tracking

3. `lib/presentation/bloc/sync/sync_state.dart`
   - 6 states: `SyncInitial`, `SyncOffline`, `SyncInProgress`, `SyncCompleted`, `SyncPartialSuccess`, `SyncError`
   - `SyncErrorType` enum for categorized error handling

4. `lib/presentation/bloc/sync/sync_bloc_exports.dart`
   - Barrel export for all sync BLoC files

**Files Modified**:
1. `lib/core/di/injection_container.dart`
   - Added SyncBloc factory registration with SyncManager and ConnectivityService dependencies

2. `lib/presentation/screens/dashboard/dashboard_screen.dart`
   - Added SyncBloc initialization in `initState()`
   - Added sync status indicator in app bar subtitle
   - Added sync button in user popup menu
   - Added BlocListener for sync state feedback (snackbars)
   - Shows syncing progress, offline status, and error states

**Usage**:
```dart
// Initialize sync on screen load
_syncBloc = sl<SyncBloc>();
_syncBloc.add(const SyncInitialized());

// Trigger manual sync
_syncBloc.add(const SyncAllRequested());

// Retry failed items
_syncBloc.add(const SyncRetryFailedRequested());
```

---

### 2025-12-28: Transaction Creation FK Fix

**Issue**: Transaction creation was failing silently due to foreign key constraint violation.

**Root Cause**:
- `TransactionListScreen` was receiving `userId` as `accountId` parameter
- The `transactions` table has FK constraint: `accountId → accounts.id`
- No account existed with the user ID, causing silent insert failures

**Files Modified**:
1. `lib/data/repositories/user_repository_impl.dart`
   - Updated `ensureUserExists()` to also create a default "Main Account" if user has no accounts
   - Added `uuid` package import for account ID generation

2. `lib/presentation/screens/main/main_screen.dart`
   - Added `_primaryAccountId` state variable
   - Added `_loadPrimaryAccount()` method to fetch user's first account
   - Updated `_buildScreens()` to pass actual account ID instead of user ID
   - Shows loading indicator while fetching account

**Solution Flow**:
```
User Login → ensureUserExists() → Creates User + Default Account → MainScreen loads account ID → TransactionListScreen uses real account ID
```

**Action Required**: Users need to log out and log back in (or clear app data) to trigger `ensureUserExists` which now creates the default account.

---

## Related Documentation

- `rules.md` - Development rules and coding standards
- `components.mdc` - Component creation guidelines
- `README.md` - Project overview and setup instructions

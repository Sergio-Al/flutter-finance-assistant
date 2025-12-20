/// App-wide constants for the AI-Powered Personal Finance Assistant

class AppConstants {
  AppConstants._();

  // ============== App Info ==============
  static const String appName = 'Finance Assistant';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ============== API Endpoints ==============
  static const String baseUrl = 'https://api.example.com/v1';
  static const int apiTimeoutSeconds = 30;
  static const int apiRetryAttempts = 3;

  // ============== AI Services ==============
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String openAiApiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiModel = 'gemini-pro';
  static const String openAiModel = 'gpt-4';
  static const int aiMaxTokens = 2048;
  static const double aiTemperature = 0.7;

  // ============== Firebase Collections ==============
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String accountsCollection = 'accounts';
  static const String budgetsCollection = 'budgets';
  static const String categoriesCollection = 'categories';
  static const String recurringTransactionsCollection =
      'recurring_transactions';
  static const String receiptsCollection = 'receipts';
  static const String chatHistoryCollection = 'chat_history';

  // ============== Local Storage Keys ==============
  static const String themeKey = 'app_theme';
  static const String localeKey = 'app_locale';
  static const String onboardingKey = 'onboarding_completed';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String userTokenKey = 'user_token';
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String currencyKey = 'preferred_currency';

  // ============== Pagination ==============
  static const int defaultPageSize = 20;
  static const int maxTransactionsPerPage = 50;
  static const int chatHistoryLimit = 100;

  // ============== Animation Durations ==============
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ============== Input Validation ==============
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxChatMessageLength = 1000;
  static const double maxTransactionAmount = 999999999.99;
  static const double minTransactionAmount = 0.01;

  // ============== Date Formats ==============
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String dayMonthFormat = 'dd MMM';

  // ============== Currency ==============
  static const String defaultCurrency = 'USD';
  static const String defaultCurrencySymbol = '\$';
  static const int currencyDecimalPlaces = 2;

  // ============== Cache Duration ==============
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const Duration transactionsCacheDuration = Duration(minutes: 15);
  static const Duration analyticsCacheDuration = Duration(hours: 6);

  // ============== Biometric Auth ==============
  static const Duration biometricTimeout = Duration(minutes: 5);
  static const int maxBiometricAttempts = 3;

  // ============== Receipt Scanner (OCR) ==============
  static const double minOcrConfidence = 0.7;
  static const int maxReceiptImageSizeKb = 5120; // 5MB
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'heic',
  ];

  // ============== Charts & Analytics ==============
  static const int defaultChartDays = 30;
  static const int maxChartDataPoints = 365;
  static const int analyticsRetentionDays = 90;

  // ============== Notifications ==============
  static const String notificationChannelId = 'finance_assistant_channel';
  static const String notificationChannelName = 'Finance Assistant';
  static const String notificationChannelDescription =
      'Notifications for budget alerts and insights';

  // ============== Export ==============
  static const String pdfExportFileName = 'finance_report';
  static const String csvExportFileName = 'transactions_export';

  // ============== Anomaly Detection ==============
  static const double anomalyThresholdMultiplier = 2.5; // Standard deviations
  static const int minDataPointsForAnomaly = 10;

  // ============== Rate Limiting ==============
  static const int maxAiRequestsPerMinute = 10;
  static const int maxReceiptScansPerDay = 50;
}

/// Default expense categories with icons and colors
class CategoryConstants {
  CategoryConstants._();

  static const List<Map<String, dynamic>> defaultCategories = [
    {
      'id': 'food',
      'name': 'Food & Dining',
      'icon': 'restaurant',
      'color': 0xFFFF6B6B,
    },
    {
      'id': 'transport',
      'name': 'Transportation',
      'icon': 'directions_car',
      'color': 0xFF4ECDC4,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': 'shopping_bag',
      'color': 0xFFFFE66D,
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': 'movie',
      'color': 0xFF95E1D3,
    },
    {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'icon': 'receipt_long',
      'color': 0xFFF38181,
    },
    {
      'id': 'health',
      'name': 'Health & Medical',
      'icon': 'medical_services',
      'color': 0xFFAA96DA,
    },
    {
      'id': 'education',
      'name': 'Education',
      'icon': 'school',
      'color': 0xFFFCBF49,
    },
    {'id': 'travel', 'name': 'Travel', 'icon': 'flight', 'color': 0xFF00B4D8},
    {
      'id': 'groceries',
      'name': 'Groceries',
      'icon': 'local_grocery_store',
      'color': 0xFF80ED99,
    },
    {
      'id': 'personal',
      'name': 'Personal Care',
      'icon': 'spa',
      'color': 0xFFFFAFCC,
    },
    {
      'id': 'home',
      'name': 'Home & Garden',
      'icon': 'home',
      'color': 0xFFB5838D,
    },
    {
      'id': 'gifts',
      'name': 'Gifts & Donations',
      'icon': 'card_giftcard',
      'color': 0xFFE07A5F,
    },
    {
      'id': 'investment',
      'name': 'Investments',
      'icon': 'trending_up',
      'color': 0xFF3D5A80,
    },
    {
      'id': 'income',
      'name': 'Income',
      'icon': 'attach_money',
      'color': 0xFF52B788,
    },
    {'id': 'other', 'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF9E9E9E},
  ];
}

/// Account type constants
class AccountTypeConstants {
  AccountTypeConstants._();

  static const String cash = 'cash';
  static const String bankAccount = 'bank_account';
  static const String creditCard = 'credit_card';
  static const String debitCard = 'debit_card';
  static const String savings = 'savings';
  static const String investment = 'investment';
  static const String loan = 'loan';
  static const String ewallet = 'e_wallet';

  static const List<String> allTypes = [
    cash,
    bankAccount,
    creditCard,
    debitCard,
    savings,
    investment,
    loan,
    ewallet,
  ];
}

/// Transaction type constants
class TransactionTypeConstants {
  TransactionTypeConstants._();

  static const String expense = 'expense';
  static const String income = 'income';
  static const String transfer = 'transfer';
}

/// Recurring transaction frequency constants
class RecurrenceConstants {
  RecurrenceConstants._();

  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String biweekly = 'biweekly';
  static const String monthly = 'monthly';
  static const String quarterly = 'quarterly';
  static const String yearly = 'yearly';

  static const List<String> allFrequencies = [
    daily,
    weekly,
    biweekly,
    monthly,
    quarterly,
    yearly,
  ];
}

/// AI Chat prompt templates
class AiPromptConstants {
  AiPromptConstants._();

  static const String systemPrompt = '''
You are a helpful personal finance assistant. Your role is to:
- Help users understand their spending patterns
- Provide personalized budget recommendations
- Answer questions about their financial data
- Offer tips for saving money and improving financial health
- Be encouraging and supportive about financial goals

Always be concise, accurate, and helpful. If you don't have enough data to answer a question, say so politely.
''';

  static const String categorizationPrompt = '''
Categorize the following transaction into one of these categories:
Food & Dining, Transportation, Shopping, Entertainment, Bills & Utilities, 
Health & Medical, Education, Travel, Groceries, Personal Care, Home & Garden, 
Gifts & Donations, Investments, Income, Other.

Transaction: {description}
Amount: {amount}

Respond with only the category name.
''';

  static const String insightPrompt = '''
Based on the following spending data, provide a brief insight (2-3 sentences max):
{spendingData}

Focus on actionable advice or interesting patterns.
''';
}

/// Error messages
class ErrorMessages {
  ErrorMessages._();

  static const String networkError =
      'Please check your internet connection and try again.';
  static const String serverError =
      'Something went wrong. Please try again later.';
  static const String authError =
      'Authentication failed. Please sign in again.';
  static const String invalidInput = 'Please check your input and try again.';
  static const String transactionFailed =
      'Failed to save transaction. Please try again.';
  static const String aiServiceUnavailable =
      'AI service is temporarily unavailable.';
  static const String ocrFailed =
      'Could not read the receipt. Please try again or enter manually.';
  static const String biometricFailed = 'Biometric authentication failed.';
  static const String exportFailed = 'Failed to export data. Please try again.';
  static const String syncFailed =
      'Failed to sync data. Your changes are saved locally.';
  static const String budgetExceeded =
      'You have exceeded your budget for this category.';
  static const String noDataAvailable =
      'No data available for the selected period.';
}

/// Success messages
class SuccessMessages {
  SuccessMessages._();

  static const String transactionAdded = 'Transaction added successfully!';
  static const String transactionUpdated = 'Transaction updated successfully!';
  static const String transactionDeleted = 'Transaction deleted successfully!';
  static const String budgetCreated = 'Budget created successfully!';
  static const String budgetUpdated = 'Budget updated successfully!';
  static const String receiptScanned = 'Receipt scanned successfully!';
  static const String dataExported = 'Data exported successfully!';
  static const String dataSynced = 'Data synced successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  static const String accountCreated = 'Account created successfully!';
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  // Images
  static const String imagesPath = 'assets/images';
  static const String logoPath = '$imagesPath/logo.png';
  static const String onboarding1 = '$imagesPath/onboarding_1.png';
  static const String onboarding2 = '$imagesPath/onboarding_2.png';
  static const String onboarding3 = '$imagesPath/onboarding_3.png';
  static const String emptyState = '$imagesPath/empty_state.png';
  static const String errorState = '$imagesPath/error_state.png';

  // Icons
  static const String iconsPath = 'assets/icons';

  // Animations (Lottie)
  static const String animationsPath = 'assets/animations';
  static const String loadingAnimation = '$animationsPath/loading.json';
  static const String successAnimation = '$animationsPath/success.json';
  static const String errorAnimation = '$animationsPath/error.json';
  static const String emptyAnimation = '$animationsPath/empty.json';

  // ML Models
  static const String modelsPath = 'assets/models';
  static const String categorizationModel =
      '$modelsPath/categorization_model.tflite';
}

/// Route names for navigation
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String editTransaction = '/edit-transaction';
  static const String transactionDetails = '/transaction-details';
  static const String analytics = '/analytics';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String budgets = '/budgets';
  static const String addBudget = '/add-budget';
  static const String receiptScanner = '/receipt-scanner';
  static const String export = '/export';
  static const String notifications = '/notifications';
}

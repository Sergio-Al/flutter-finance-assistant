# Finance Assistant - Prompts for AI Agents

This file contains pre-built prompts for common development tasks. Copy and use these when working with AI coding assistants.

---

## Feature Development Prompts

### Create a New Feature (Full Stack)

```
Create a new feature for {FEATURE_NAME} in the Finance Assistant app.

Follow these steps:
1. Create the entity in `lib/domain/entities/{feature}.dart`
2. Create the model in `lib/data/models/{feature}_model.dart`
3. Create the repository interface in `lib/domain/repositories/{feature}_repository.dart`
4. Create the repository implementation in `lib/data/repositories/{feature}_repository_impl.dart`
5. Create use cases in `lib/domain/usecases/{feature}/`
6. Create BLoC in `lib/presentation/bloc/{feature}/`
7. Create the screen in `lib/presentation/screens/{feature}/`

Follow the rules in `.cursor/rules.md` and component templates in `.cursor/components.mdc`.

The feature should:
- {Describe what the feature does}
- {List specific requirements}
```

### Create a New Screen

```
Create a new screen called {SCREEN_NAME}Screen in the Finance Assistant app.

Location: `lib/presentation/screens/{feature}/{feature}_screen.dart`

Requirements:
- Follow the screen template in `.cursor/components.mdc`
- Use BlocProvider and BlocBuilder pattern
- Handle loading, error, and success states
- Use theme colors from AppTheme (no hardcoded colors)
- Support dark/light mode
- Use GlassCard widget for cards
- Follow naming conventions from `.cursor/rules.md`

The screen should display:
- {Describe UI elements}
- {List interactions}
```

### Create a New Widget

```
Create a reusable widget called {WIDGET_NAME} for the Finance Assistant app.

Location: `lib/presentation/widgets/{widget_name}.dart`

Requirements:
- Follow widget template in `.cursor/components.mdc`
- Use const constructor
- Document all public parameters
- Support dark/light mode using Theme.of(context)
- Use AppTheme colors for status colors (success, error, warning)
- Keep under 150 lines

Props needed:
- {List required parameters}
- {List optional parameters}

Behavior:
- {Describe widget behavior}
```

### Create a BLoC

```
Create a BLoC for {FEATURE_NAME} in the Finance Assistant app.

Location: `lib/presentation/bloc/{feature}/`

Files to create:
- {feature}_bloc.dart
- {feature}_event.dart (as part file)
- {feature}_state.dart (as part file)

Events needed:
- {Feature}LoadRequested - Load initial data
- {Feature}ItemAdded - Add new item
- {Feature}ItemUpdated - Update existing item
- {Feature}ItemDeleted - Delete item

States needed:
- {Feature}Initial
- {Feature}Loading
- {Feature}Loaded (with data)
- {Feature}Error (with message)

Follow BLoC rules in `.cursor/rules.md`:
- Use sealed classes for events and states
- Inject use cases through constructor
- Use Either<Failure, T> for error handling
```

---

## Bug Fix Prompts

### Fix a UI Issue

```
Fix the following UI issue in {FILE_PATH}:

Issue: {Describe the problem}
Expected: {Describe expected behavior}
Actual: {Describe actual behavior}

When fixing:
- Follow theme guidelines (no hardcoded colors)
- Ensure dark/light mode compatibility
- Check responsive behavior
- Maintain existing functionality
```

### Fix a State Management Issue

```
Fix the state management issue in {BLOC_NAME}:

Issue: {Describe the problem}

Check for:
- Proper event handling
- State emission order
- Error handling with Either pattern
- Memory leaks (unclosed streams)
- Proper use of emit.forEach for streams
```

---

## Refactoring Prompts

### Refactor to Clean Architecture

```
Refactor {FILE_PATH} to follow Clean Architecture:

Current state: {Describe current implementation}

Refactor to:
1. Extract business logic to use case in `lib/domain/usecases/`
2. Create repository interface in `lib/domain/repositories/`
3. Move data operations to repository impl in `lib/data/repositories/`
4. Update BLoC to use injected use cases

Follow dependency rules:
- Domain layer has no external dependencies
- Data layer implements domain interfaces
- Presentation layer only uses domain layer
```

### Extract Widget

```
Extract the following code into a reusable widget:

```dart
{PASTE CODE HERE}
```

Create the widget in: `lib/presentation/widgets/{widget_name}.dart`

Requirements:
- Identify configurable parameters
- Make it reusable across screens
- Add documentation comments
- Follow widget template in `.cursor/components.mdc`
```

---

## Testing Prompts

### Write Unit Tests

```
Write unit tests for {CLASS_NAME} in {FILE_PATH}.

Test file location: `test/{matching_path}_test.dart`

Test cases to cover:
- Happy path scenarios
- Error cases
- Edge cases (empty data, null values, etc.)

Use:
- mocktail for mocking
- bloc_test for BLoC tests
- Group related tests together
- Follow AAA pattern (Arrange, Act, Assert)
```

### Write Widget Tests

```
Write widget tests for {WIDGET_NAME}:

Test cases:
- Widget renders correctly
- Responds to user interactions
- Displays correct data
- Handles loading/error states
- Works in dark and light mode

Use:
- WidgetTester for interactions
- find.byType, find.text for finding widgets
- pumpAndSettle for animations
```

---

## Database Prompts

### Create Database Table

```
Create a new Drift table for {TABLE_NAME} in the Finance Assistant app.

Columns needed:
- {column_name}: {type} - {description}
- {column_name}: {type} - {description}

Include:
- id (primary key, auto-increment or UUID)
- createdAt, updatedAt timestamps
- syncStatus for offline-first sync

Use column constants from database_constants.dart pattern.
Create corresponding Model and Entity classes.
```

### Add Database Migration

```
Add a database migration for {CHANGE_DESCRIPTION}.

Migration should:
- Add new column: {column_name} to {table_name}
- Set default value for existing rows
- Update database version
- Handle rollback if needed

Follow Drift migration best practices.
```

---

## API Integration Prompts

### Integrate AI Service

```
Integrate {AI_SERVICE} for {USE_CASE} in the Finance Assistant app.

Service: {Gemini API / OpenAI / ML Kit}
Purpose: {Describe what it should do}

Create:
1. Service interface in `lib/data/services/{service}_service.dart`
2. Implementation with error handling
3. Use case to call the service
4. Update BLoC to handle AI responses

Use constants from AppConstants for:
- API endpoints
- Model names
- Token limits
- Temperature settings

Handle:
- Network errors
- Rate limiting
- Timeout scenarios
```

---

## Quick Reference Prompt

```
I'm working on the Finance Assistant Flutter app. Here's the context:

Architecture: Clean Architecture with BLoC
Database: Drift (local) + Firestore (remote)
State: flutter_bloc
Error Handling: dartz Either<Failure, T>

Key files:
- Constants: lib/core/constants/
- Theme: lib/core/themes/app_theme.dart
- Widgets: lib/presentation/widgets/

Rules to follow:
- No hardcoded colors (use AppTheme)
- Use const constructors
- Support dark/light mode
- Offline-first data flow

Task: {YOUR TASK HERE}
```

# Finance Assistant - Glossary

Technical terms and domain concepts used in this project.

---

## Architecture Terms

| Term | Definition |
|------|------------|
| **Clean Architecture** | Software design pattern that separates code into layers (Presentation, Domain, Data) with dependencies pointing inward |
| **BLoC** | Business Logic Component - state management pattern that separates business logic from UI |
| **Repository Pattern** | Abstraction layer between domain and data layers that handles data operations |
| **UseCase** | Single-purpose class that encapsulates one business operation |
| **Use Case Composition** | Pattern where multiple repositories are composed at the use case layer to join data from different domains |
| **Entity** | Pure Dart class representing a business object in the domain layer |
| **Model** | Data class with serialization capabilities (toJson/fromJson) |
| **DataSource** | Class responsible for fetching/storing data from a specific source (local/remote) |
| **Dependency Injection** | Pattern where dependencies are provided to a class rather than created inside it |
| **Graceful Degradation** | Returning partial data when some operations fail, rather than failing entirely |

---

## State Management Terms

| Term | Definition |
|------|------------|
| **Event** | Action/intent sent to BLoC to trigger state changes |
| **State** | Immutable snapshot of data at a point in time |
| **Emit** | BLoC method to output new state |
| **BlocProvider** | Widget that provides BLoC instance to widget tree |
| **BlocBuilder** | Widget that rebuilds when BLoC state changes |
| **BlocListener** | Widget that performs side effects on state changes |
| **Cubit** | Simplified BLoC without events, uses methods directly |

---

## Database Terms

| Term | Definition |
|------|------------|
| **Drift** | Type-safe SQLite wrapper for Flutter (formerly Moor) |
| **Firestore** | Firebase NoSQL cloud database |
| **DAO** | Data Access Object - class that provides interface to database operations |
| **Remote Datasource** | Class that handles data operations with remote services (Firebase) |
| **Local Datasource** | Class that handles data operations with local database (Drift) |
| **Sync Queue** | Local table storing pending changes for remote sync |
| **Sync Status** | Flag indicating if a record is synced, pending, or failed |
| **Offline-First** | Architecture where local database is primary source of truth |
| **Migration** | Script to update database schema between versions |
| **CRUD** | Create, Read, Update, Delete - basic data operations |
| **Subcollection** | Firestore collection nested under a document (e.g., users/{id}/accounts) |
| **Server Timestamp** | Firestore timestamp set by server for consistency |
| **Conflict Resolution** | Strategy to handle when local and remote changes conflict |
| **Last Write Wins** | Conflict strategy where most recent change takes precedence |

---

## Finance Domain Terms

| Term | Definition |
|------|------------|
| **Transaction** | Any money movement (expense, income, transfer) |
| **Account** | Container for money (bank, wallet, card) |
| **Category** | Classification for transactions (Food, Transport, etc.) |
| **Budget** | Spending limit for a category over a period |
| **Recurring Transaction** | Transaction that repeats on schedule |
| **Anomaly** | Unusual spending pattern detected by AI |
| **OCR** | Optical Character Recognition - extracting text from images |

---

## AI/ML Terms

| Term | Definition |
|------|------------|
| **NLP** | Natural Language Processing - understanding human language |
| **Gemini** | Google's AI model for chat and analysis |
| **GPT-4** | OpenAI's language model |
| **ML Kit** | Google's on-device machine learning SDK |
| **TensorFlow Lite** | Lightweight ML framework for mobile |
| **Prompt** | Text instruction sent to AI model |
| **Token** | Unit of text processed by AI (roughly 4 characters) |
| **Temperature** | AI randomness setting (0=deterministic, 1=creative) |

---

## Flutter/Dart Terms

| Term | Definition |
|------|------------|
| **Widget** | Basic building block of Flutter UI |
| **StatelessWidget** | Widget that doesn't maintain mutable state |
| **StatefulWidget** | Widget that can change over time |
| **BuildContext** | Handle to widget's location in tree |
| **Theme** | Collection of colors, fonts, and styles |
| **Scaffold** | Basic screen structure with app bar, body, etc. |
| **Navigator** | Manages navigation stack |
| **Future** | Value that will be available later |
| **Stream** | Sequence of async events |
| **Sealed Class** | Class with known, fixed set of subtypes |
| **Foreign Key (FK)** | Database constraint linking table to another table's primary key |
| **Idempotent** | Operation that produces same result regardless of how many times executed |

---

## Error Handling Terms

| Term | Definition |
|------|------------|
| **Either** | Type that holds either success (Right) or failure (Left) |
| **Failure** | Domain-level error representation |
| **Exception** | Runtime error that can be caught |
| **Try/Catch** | Error handling mechanism |
| **fold** | Method to handle both Either cases |

---

## Testing Terms

| Term | Definition |
|------|------------|
| **Unit Test** | Tests single function/class in isolation |
| **Widget Test** | Tests widget behavior and rendering |
| **Integration Test** | Tests multiple components together |
| **Mock** | Fake implementation for testing |
| **Stub** | Simple mock that returns preset values |
| **AAA Pattern** | Arrange, Act, Assert - test structure |

---

## File/Code Conventions

| Convention | Example | Meaning |
|------------|---------|---------|
| `snake_case.dart` | `transaction_bloc.dart` | File names |
| `PascalCase` | `TransactionBloc` | Class names |
| `camelCase` | `getTransactions` | Variables, methods |
| `_prefixed` | `_localDataSource` | Private members |
| `kConstant` | `kDefaultPadding` | Top-level constants |
| `SCREAMING_CASE` | `API_KEY` | Environment variables |

---

## Common Abbreviations

| Abbrev | Full Form |
|--------|-----------|
| **API** | Application Programming Interface |
| **UI** | User Interface |
| **UX** | User Experience |
| **DB** | Database |
| **DI** | Dependency Injection |
| **DTO** | Data Transfer Object |
| **CRUD** | Create, Read, Update, Delete |
| **SDK** | Software Development Kit |
| **CI/CD** | Continuous Integration/Deployment |
| **FAB** | Floating Action Button |

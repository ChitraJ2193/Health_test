# Architecture Documentation

## Feature-Based MVVM Architecture

This project follows a **Feature-Based MVVM Architecture** pattern, which organizes code by features rather than by technical layers. This approach provides better scalability, maintainability, and team collaboration.

## Project Structure

```
zörgm.ai/
├── Features/                    # Feature modules
│   └── Chat/                    # Chat feature
│       ├── ChatView.swift       # View (UI)
│       ├── ChatViewModel.swift  # ViewModel (Business Logic)
│       ├── ChatMessage.swift    # Model (Feature-specific)
│       └── ChatResponse.swift   # Model (Feature-specific)
│
├── Core/                        # Shared/core modules
│   ├── Models/                  # Shared data models
│   │   └── SearchResult.swift
│   ├── Services/                # Business logic services
│   │   ├── NetworkManager.swift # Network layer
│   │   └── NHSService.swift     # NHS API service
│   └── Utilities/               # Helper utilities
│       └── Constants.swift
│
├── ContentView.swift            # Root view
└── zo_rgm_aiApp.swift          # App entry point
```

## Architecture Layers

### 1. Features Layer (`Features/`)
Each feature is self-contained with its own:
- **Views**: SwiftUI views for the feature
- **ViewModels**: Business logic and state management
- **Models**: Feature-specific data models

**Example: Chat Feature**
- `ChatView`: The main chat interface
- `ChatViewModel`: Manages chat state, message handling, and conversation context
- `ChatMessage`: Represents a single chat message
- `ChatResponse`: Represents a response from the service

### 2. Core Layer (`Core/`)
Shared components used across features:

#### Models (`Core/Models/`)
- Shared data models used by multiple features
- `SearchResult`: Represents search results from NHS

#### Services (`Core/Services/`)
- Business logic services
- `NetworkManager`: Handles all network requests
- `NHSService`: Provides NHS.uk search and content fetching

#### Utilities (`Core/Utilities/`)
- Helper functions and constants
- `Constants`: App-wide constants

## MVVM Pattern

### Model
- Data structures and business entities
- Located in `Features/[Feature]/` for feature-specific models
- Located in `Core/Models/` for shared models

### View
- SwiftUI views that display UI
- Located in `Features/[Feature]/`
- Observes ViewModels using `@StateObject` or `@ObservedObject`

### ViewModel
- Contains business logic and state management
- Located in `Features/[Feature]/`
- Uses `@Published` properties to notify views of changes
- Communicates with Services for data operations

## Benefits of This Architecture

1. **Scalability**: Easy to add new features without affecting existing ones
2. **Maintainability**: Related code is grouped together
3. **Testability**: Each feature can be tested independently
4. **Team Collaboration**: Different developers can work on different features
5. **Code Reusability**: Core services can be shared across features

## Adding a New Feature

To add a new feature:

1. Create a new folder in `Features/` (e.g., `Features/Settings/`)
2. Add feature-specific files:
   - `SettingsView.swift`
   - `SettingsViewModel.swift`
   - `SettingsModel.swift` (if needed)
3. Use services from `Core/Services/` as needed
4. Update `ContentView.swift` or navigation to include the new feature

## Dependencies

- **Features** → **Core**: Features can use Core services and models
- **Core** → **Core**: Core modules can depend on each other
- **Features** → **Features**: Features should be independent (avoid cross-feature dependencies)

## Example Flow

1. User interacts with `ChatView`
2. `ChatView` calls methods on `ChatViewModel`
3. `ChatViewModel` uses `NHSService` (from Core) to fetch data
4. `NHSService` uses `NetworkManager` (from Core) for network requests
5. Data flows back through ViewModel to View
6. View updates UI based on ViewModel state


# Architecture Diagrams

> Visual representations of project architecture

---

## 📊 Overall Architecture Flow

```mermaid
graph TB
    User[User Interaction] --> Screen[Screen/UI Layer]
    Screen --> Consumer[Consumer Widget]
    Consumer --> Provider[Provider/State Management]
    Provider --> Service[API Service]
    Provider --> DB[(Local Database)]
    Service --> API[External API]
    API --> Service
    Service --> Provider
    DB --> Provider
    Provider --> Consumer
    Consumer --> Screen
    Screen --> User
    
    style User fill:#375DFB,color:#fff
    style Screen fill:#38C793,color:#fff
    style Provider fill:#F17B2C,color:#fff
    style Service fill:#F2AE40,color:#000
    style DB fill:#868C98,color:#fff
    style API fill:#EA134B,color:#fff
```

---

## 🏗️ Layer Architecture

```mermaid
graph LR
    A[Presentation Layer] --> B[Business Logic Layer]
    B --> C[Data Layer]
    
    A1[Screens] -.-> A
    A2[Widgets] -.-> A
    A3[Components] -.-> A
    
    B1[Providers] -.-> B
    B2[State] -.-> B
    
    C1[Models] -.-> C
    C2[Services] -.-> C
    C3[Database] -.-> C
    C4[Repositories] -.-> C
    
    style A fill:#38C793,color:#fff
    style B fill:#F17B2C,color:#fff
    style C fill:#375DFB,color:#fff
```

---

## 🔄 Provider State Flow

```mermaid
sequenceDiagram
    participant U as User
    participant S as Screen
    participant P as Provider
    participant API as API Service
    participant DB as Database
    
    U->>S: Tap Button
    S->>P: context.read<Provider>().fetchData()
    P->>P: _isLoading = true
    P->>P: notifyListeners()
    S-->>U: Show Loading
    
    P->>API: HTTP Request
    
    alt API Success
        API-->>P: Response Data
        P->>P: _data = response
        P->>DB: Save to Local DB
        P->>P: _isLoading = false
        P->>P: notifyListeners()
        S-->>U: Show Data
    else API Failure
        API-->>P: Error
        P->>DB: Load from Cache
        DB-->>P: Cached Data
        P->>P: _error = error
        P->>P: _isLoading = false
        P->>P: notifyListeners()
        S-->>U: Show Error/Cached Data
    end
```

---

## 📁 Folder Structure Diagram

```mermaid
graph TD
    Root[lib/] --> Core[core/]
    Root --> Data[data/]
    Root --> Presentation[presentation/]
    Root --> Services[services/]
    Root --> Shared[shared/]
    
    Core --> Theme[theme/]
    Core --> Constants[constants/]
    Core --> Utils[utils/]
    Core --> Routes[routes/]
    
    Theme --> Colors[app_colors.dart]
    Theme --> Styles[app_text_styles.dart]
    Theme --> AppTheme[app_theme.dart]
    
    Data --> Models[models/]
    Data --> Database[database/]
    Data --> Repos[repositories/]
    
    Presentation --> Providers[providers/]
    Presentation --> Screens[screens/]
    Presentation --> Widgets[widgets/]
    
    Services --> API[api/]
    Services --> Local[local/]
    
    Shared --> Components[components/]
    Shared --> Extensions[extensions/]
    
    style Root fill:#375DFB,color:#fff
    style Core fill:#38C793,color:#fff
    style Data fill:#F17B2C,color:#fff
    style Presentation fill:#F2AE40,color:#000
    style Services fill:#868C98,color:#fff
    style Shared fill:#EA134B,color:#fff
```

---

## 🔄 Data Flow - Collection Feature

```mermaid
graph TD
    A[User Opens Collection Screen] --> B[CollectionHistoryScreen]
    B --> C{Consumer Builder}
    C --> D[CollectionHistoryProvider]
    
    D --> E{Check Loading State}
    E -->|True| F[Show Loading Indicator]
    E -->|False| G{Check Data}
    
    G -->|Has Data| H[Display List]
    G -->|No Data| I[Show Empty State]
    G -->|Error| J[Show Error Message]
    
    D --> K[fetchCollectionHistory]
    K --> L[GetServiceUtils.fetchData]
    L --> M{API Call}
    
    M -->|Success| N[Parse Response]
    N --> O[collectionHistoryModelFromJson]
    O --> P[Update _collectionHistory]
    P --> Q[Save to Database]
    Q --> R[notifyListeners]
    
    M -->|Failure| S[Load from Database]
    S --> T[Set Error State]
    T --> R
    
    R --> C
    
    style A fill:#375DFB,color:#fff
    style D fill:#F17B2C,color:#fff
    style H fill:#38C793,color:#fff
    style I fill:#F2AE40,color:#000
    style J fill:#EA134B,color:#fff
```

---

## 🎯 Screen Component Breakdown

```mermaid
graph TD
    Screen[CollectionHistoryScreen] --> AppBar[_buildAppBar]
    Screen --> Filters[_buildFilters]
    Screen --> Summary[_buildSummarySection]
    Screen --> Content[_buildContent]
    
    AppBar --> BackBtn[Back Button]
    AppBar --> Title[Screen Title]
    
    Filters --> Status[Status Dropdown]
    Filters --> Date[Date Filter]
    Filters --> Payment[Payment Mode]
    Filters --> Clear[Clear Button]
    
    Summary --> Card1[Amount Collected]
    Summary --> Card2[Bank Transfer]
    Summary --> Card3[Cash Payment]
    
    Content --> Consumer[Consumer Widget]
    Consumer --> Loading{isLoading?}
    Loading -->|Yes| Spinner[CircularProgressIndicator]
    Loading -->|No| DataCheck{Has Data?}
    
    DataCheck -->|Yes| List[RefreshIndicator + ListView]
    DataCheck -->|No| Empty[Empty State]
    
    List --> Items[List Items]
    Items --> ItemWidget[_buildListItem]
    
    style Screen fill:#375DFB,color:#fff
    style Consumer fill:#F17B2C,color:#fff
    style List fill:#38C793,color:#fff
```

---

## 🌐 API Request Flow

```mermaid
sequenceDiagram
    participant P as Provider
    participant S as GetServiceUtils
    participant H as HTTP Client
    participant API as External API
    participant DB as Local DB
    
    P->>S: fetchData(url, context)
    S->>S: Get Auth Token
    S->>H: http.get(url, headers)
    H->>API: GET Request
    
    alt Status 200
        API-->>H: Success Response
        H-->>S: Response Body
        S->>S: Log Response
        S-->>P: Return Response String
        P->>P: Parse JSON
        P->>DB: Save to Database
        P->>P: Update State
        P->>P: notifyListeners()
    else Status 401
        API-->>H: Unauthorized
        H-->>S: 401 Response
        S->>S: Clear Preferences
        S->>S: Navigate to Login
        S-->>P: Throw Exception
    else Status 500
        API-->>H: Server Error
        H-->>S: 500 Response
        S->>S: Show Error Message
        S-->>P: Throw Exception
        P->>DB: Load Cached Data
    else Network Error
        H-->>S: SocketException
        S-->>P: Throw 'No Internet'
        P->>DB: Load Cached Data
    end
```

---

## 📦 Model Parsing Flow

```mermaid
graph LR
    A[JSON String] --> B[collectionHistoryModelFromJson]
    B --> C[json.decode]
    C --> D[Map<String, dynamic>]
    D --> E[CollectionHistoryModel.fromJson]
    
    E --> F{Parse Fields}
    F --> G[amountCollected]
    F --> H[cashCollected]
    F --> I[emiHistory Array]
    
    I --> J{Loop through array}
    J --> K[EmiHistoryList.fromJson]
    K --> L[Parse nested fields]
    L --> M[Create EmiHistoryList object]
    
    G --> N[CollectionHistoryModel Object]
    H --> N
    M --> N
    
    N --> O[Return to Provider]
    O --> P[Update State]
    P --> Q[notifyListeners]
    Q --> R[UI Rebuilds]
    
    style A fill:#375DFB,color:#fff
    style E fill:#F17B2C,color:#fff
    style N fill:#38C793,color:#fff
    style R fill:#F2AE40,color:#000
```

---

## 🔐 Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant L as Login Screen
    participant P as Auth Provider
    participant API as Auth API
    participant SP as SharedPreferences
    participant H as Home Screen
    
    U->>L: Enter Credentials
    U->>L: Tap Login
    L->>P: login(username, password)
    P->>P: _isLoading = true
    P->>P: notifyListeners()
    L-->>U: Show Loading
    
    P->>API: POST /login
    
    alt Login Success
        API-->>P: {token, user_data}
        P->>SP: Save Token
        P->>SP: Save User Data
        P->>P: _isAuthenticated = true
        P->>P: notifyListeners()
        L->>H: Navigate to Home
    else Login Failed
        API-->>P: {error: "Invalid credentials"}
        P->>P: _error = error
        P->>P: notifyListeners()
        L-->>U: Show Error Message
    end
```

---

## 🗄️ Offline-First Strategy

```mermaid
graph TD
    A[App Opens] --> B{Check Network}
    
    B -->|Online| C[Fetch from API]
    B -->|Offline| D[Load from Database]
    
    C --> E{API Success?}
    E -->|Yes| F[Parse Data]
    E -->|No| D
    
    F --> G[Save to Database]
    G --> H[Update UI]
    
    D --> I{Has Cached Data?}
    I -->|Yes| H
    I -->|No| J[Show Empty State]
    
    K[User Creates Data] --> L{Network Available?}
    L -->|Yes| M[Send to API]
    L -->|No| N[Save Locally]
    
    M --> O{API Success?}
    O -->|Yes| P[Mark as Synced]
    O -->|No| N
    
    N --> Q[Queue for Sync]
    Q --> R[Listen for Network]
    R -->|Network Restored| S[Auto Sync]
    
    style A fill:#375DFB,color:#fff
    style C fill:#38C793,color:#fff
    style D fill:#F17B2C,color:#fff
    style Q fill:#EA134B,color:#fff
```

---

## 🎨 Theme System Structure

```mermaid
graph TD
    Theme[AppTheme] --> Light[Light Theme]
    
    Light --> Colors[AppColors]
    Light --> Texts[AppTextStyles]
    Light --> Dims[AppDimensions]
    
    Colors --> Primary[Primary Colors]
    Colors --> Status[Status Colors]
    Colors --> TextC[Text Colors]
    Colors --> BG[Background Colors]
    
    Texts --> H[Headings]
    Texts --> Body[Body Text]
    Texts --> Button[Button Text]
    
    Dims --> Padding[Padding Values]
    Dims --> Radius[Border Radius]
    Dims --> Icons[Icon Sizes]
    
    App[MaterialApp] --> Theme
    Theme --> Screens[All Screens]
    
    style Theme fill:#375DFB,color:#fff
    style Colors fill:#38C793,color:#fff
    style Texts fill:#F17B2C,color:#fff
    style Dims fill:#F2AE40,color:#000
```

---

## 🧩 Component Hierarchy

```mermaid
graph TD
    App[MyApp] --> Home[HomeScreen]
    
    Home --> List[CollectionListScreen]
    List --> Item1[CollectionItem]
    List --> Item2[CollectionItem]
    List --> Item3[CollectionItem]
    
    Item1 --> CustomCard[CustomCard Component]
    Item1 --> CustomButton[CustomButton Component]
    
    Home --> Details[CollectionDetailsScreen]
    Details --> Form[Form Widgets]
    Form --> CustomInput[CustomTextFormField]
    Form --> CustomDropdown[CustomDropdown]
    Form --> CustomButton2[CustomButton]
    
    Details --> BottomSheet[PaymentBottomSheet]
    BottomSheet --> CustomButton3[CustomButton]
    
    style App fill:#375DFB,color:#fff
    style CustomCard fill:#38C793,color:#fff
    style CustomButton fill:#F17B2C,color:#fff
    style CustomInput fill:#F2AE40,color:#000
```

---

## 📱 Screen Lifecycle with Provider

```mermaid
sequenceDiagram
    participant S as Screen Widget
    participant P as Provider
    participant API as API
    
    Note over S: Screen Created
    S->>S: build()
    S->>P: Consumer<Provider>
    
    Note over P: First Build
    P->>P: Constructor
    P->>P: _initialize()
    P->>API: fetchData()
    P->>P: notifyListeners()
    
    Note over S: Rebuild Triggered
    S->>S: build()
    S->>P: Read State
    P-->>S: Return Data
    S->>S: Render UI
    
    Note over S: User Interaction
    S->>P: context.read<P>().updateData()
    P->>P: Update State
    P->>P: notifyListeners()
    
    Note over S: Rebuild Again
    S->>S: build()
    S->>P: Read State
    P-->>S: Return Updated Data
    S->>S: Render UI
    
    Note over S: Screen Disposed
    S->>S: dispose()
    Note over P: Provider persists (app-level)
```

---

## 🚀 Feature Development Flow

```mermaid
graph LR
    A[Start] --> B[Create Model]
    B --> C[Create Provider]
    C --> D[Create Service]
    D --> E[Create Screen]
    E --> F[Create Components]
    F --> G[Register Provider]
    G --> H[Add Route]
    H --> I[Test Feature]
    
    I --> J{Works?}
    J -->|Yes| K[Code Review]
    J -->|No| L[Debug]
    L --> I
    
    K --> M{Approved?}
    M -->|Yes| N[Merge]
    M -->|No| O[Fix Issues]
    O --> K
    
    N --> P[Deploy]
    
    style A fill:#375DFB,color:#fff
    style N fill:#38C793,color:#fff
    style L fill:#EA134B,color:#fff
    style P fill:#F2AE40,color:#000
```

---

## 💾 Database Operations Flow

```mermaid
graph TD
    A[Provider] --> B{Operation Type}
    
    B -->|Read| C[getAllCollections]
    B -->|Create| D[insertCollection]
    B -->|Update| E[updateCollection]
    B -->|Delete| F[deleteCollection]
    
    C --> G[Drift Query]
    D --> H[Drift Insert]
    E --> I[Drift Update]
    F --> J[Drift Delete]
    
    G --> K[(SQLite DB)]
    H --> K
    I --> K
    J --> K
    
    K --> L[Return Result]
    L --> M[Update Provider State]
    M --> N[notifyListeners]
    N --> O[UI Updates]
    
    style A fill:#375DFB,color:#fff
    style K fill:#868C98,color:#fff
    style O fill:#38C793,color:#fff
```

---

**ഈ diagrams VS Code-ലോ GitHub-ലോ open ചെയ്താൽ visual representation കാണാം!**

---

## 📖 References

- Mermaid Documentation: https://mermaid.js.org/
- Full Architecture: [FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md)
- Quick Reference: [ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)

---

**Last Updated:** June 2026

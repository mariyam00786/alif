# Flutter Project Cheat Sheet

> Print ചെയ്ത് desk-ൽ വെക്കാവുന്ന quick reference 📋

---

## 🎯 Provider Pattern (3 Steps)

### 1. Create Provider
```dart
class MyProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    // API call
    _isLoading = false;
    notifyListeners();
  }
}
```

### 2. Register in main.dart
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
  child: MyApp(),
)
```

### 3. Use in Screen
```dart
// For actions
context.read<MyProvider>().fetchData();

// For values
Consumer<MyProvider>(
  builder: (context, provider, _) => Text(provider.data),
)
```

---

## 📁 Folder Structure (Quick)

```
lib/
├── core/theme/         → AppColors, AppTextStyles
├── constants/          → APIs, Assets, Strings
├── data/models/        → Data models
├── database/           → Drift tables
├── presentation/
│   ├── providers/      → State management
│   ├── screens/        → UI screens
│   └── widgets/        → Reusable widgets
├── services/api/       → API calls
└── utils/              → Helpers
```

---

## 🎨 Theme Usage

```dart
// Colors
AppColors.primary
AppColors.textBlack
AppColors.success
AppColors.error

// Text
AppTextStyles.heading1
AppTextStyles.heading2
AppTextStyles.bodyMedium
AppTextStyles.button

// Dimensions
AppDimensions.paddingM    // 16
AppDimensions.radiusL     // 16
AppDimensions.iconM       // 24
```

---

## 📱 Screen Template (Copy-Paste)

```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Title')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<MyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) 
          return Center(child: CircularProgressIndicator());
        
        if (provider.error != null) 
          return Center(child: Text(provider.error!));
        
        if (provider.data?.isEmpty ?? true) 
          return Center(child: Text('No data'));
        
        return ListView.builder(...);
      },
    );
  }
}
```

---

## 🌐 API Call Pattern

```dart
// GET
final response = await GetServiceUtils.fetchData(url, context);
final model = modelFromJson(response);

// POST (Multipart)
var request = http.MultipartRequest('POST', Uri.parse(url));
request.headers['Authorization'] = 'Bearer $token';
request.fields.addAll({...});
request.files.add(await http.MultipartFile.fromPath('file', path));
final response = await request.send();
```

---

## 📦 Model Pattern

```dart
import 'dart:convert';

ModelName modelFromJson(String str) => 
    ModelName.fromJson(json.decode(str));

class ModelName {
  final String? id;
  final num? amount;
  final List<Item>? items;

  ModelName({this.id, this.amount, this.items});

  factory ModelName.fromJson(Map<String, dynamic> json) => ModelName(
    id: json["id"],
    amount: json["amount"] ?? 0,
    items: json["items"] == null ? [] : 
           List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "amount": amount,
    "items": items?.map((x) => x.toJson()).toList() ?? [],
  };
}
```

---

## ✅ Pre-Commit Checklist

```
□ No hardcoded colors/styles
□ All imports used
□ Proper null handling
□ Loading/Error/Empty states
□ Uses Provider for state
□ Follows folder structure
□ Meaningful variable names
□ Code formatted
```

---

## 🚫 Common Mistakes

| ❌ Wrong | ✅ Right |
|---------|---------|
| `Color(0xFF375DFB)` | `AppColors.primary` |
| `TextStyle(fontSize: 16)` | `AppTextStyles.bodyMedium` |
| `context.watch<P>().method()` | `context.read<P>().method()` |
| `setState(() {})` | `notifyListeners()` |
| All UI in build() | Break into methods |

---

## 🔧 Quick Commands

```bash
# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build

# Clean & regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build APK
flutter build apk --release

# Format code
dart format .

# Analyze
flutter analyze
```

---

## 📝 Naming Conventions

```dart
// Files
feature_name_screen.dart
feature_name_provider.dart
model_name_model.dart

// Classes
FeatureNameScreen
FeatureNameProvider
ModelName

// Variables
_privateVariable
publicVariable
CONSTANT_VALUE
```

---

## 🎯 New Feature (5 Steps)

```
1. Model      → data/models/product_model.dart
2. Provider   → presentation/providers/product_provider.dart
3. Screen     → presentation/screens/products/
4. Register   → main.dart (ChangeNotifierProvider)
5. Route      → core/routes/app_routes.dart
```

---

## 🔄 State Flow

```
User Action
    ↓
Screen calls Provider method
    ↓
Provider updates state
    ↓
notifyListeners()
    ↓
Consumer rebuilds
    ↓
UI updates
```

---

## 💡 Quick Tips

1. **Always use const** where possible
2. **Consumer over watch** for selective rebuilds
3. **Break widgets** into methods
4. **Handle null** everywhere
5. **Try-catch** all API calls
6. **Test offline** scenarios
7. **Use theme** constants
8. **Add comments** for complex logic

---

## 🆘 Emergency Fixes

**Provider not found:**
```dart
// Check if registered in main.dart
ChangeNotifierProvider(create: (_) => YourProvider())
```

**Build runner issues:**
```bash
flutter pub run build_runner clean
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Null errors:**
```dart
// Use null-aware operators
value?.property ?? defaultValue
list?.isEmpty ?? true
```

---

## 📚 References

- Full Guide: `FLUTTER_PROJECT_ARCHITECTURE.md`
- Quick Ref: `ARCHITECTURE_QUICK_REFERENCE.md`
- AI Guide: `.agent-instructions.md`

---

**Version:** 1.0 | **Updated:** June 2026

---

🖨️ **Print this page and keep at your desk!**

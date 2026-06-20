# Documentation Guide

ഈ project-ൽ മൂന്നു documentation files ഉണ്ട്:

---

## 📚 Documentation Files

### 1. **FLUTTER_PROJECT_ARCHITECTURE.md**
**For:** Developers & Team Members  
**Purpose:** സമ്പൂർണ്ണമായ architecture guide

**Contains:**
- Detailed architecture explanation
- Folder structure with examples
- State management patterns
- Complete code examples
- Best practices
- Troubleshooting tips

**When to use:**
- പുതിയ team members onboarding
- Architecture decisions മനസ്സിലാക്കാൻ
- Detailed implementation examples വേണമെങ്കിൽ
- Best practices പഠിക്കാൻ

---

### 2. **.agent-instructions.md**
**For:** AI Agents (GitHub Copilot, ChatGPT, etc.)  
**Purpose:** AI agents-ന് വേണ്ടിയുള്ള concise instructions

**Contains:**
- Quick code templates
- Must-follow rules
- Folder structure
- Naming conventions
- Critical dos and don'ts

**When to use:**
- AI agent-നോട് code generate ചെയ്യിപ്പിക്കുമ്പോൾ
- Automated scaffolding വേണമെങ്കിൽ
- Quick reference വേണമെങ്കിൽ

**Usage:**
```
"Create a new feature called 'Products' following .agent-instructions.md"
```

---

### 3. **ARCHITECTURE_QUICK_REFERENCE.md** (ഈ file)
**For:** Daily development reference  
**Purpose:** Quick lookup guide

---

## 🚀 Quick Start

### For New Developers:

1. **First:** Read `FLUTTER_PROJECT_ARCHITECTURE.md` (30-45 minutes)
2. **Then:** Bookmark `ARCHITECTURE_QUICK_REFERENCE.md` for daily use
3. **Keep:** `.agent-instructions.md` for AI-assisted development

### For AI Agents:

```bash
"Please read .agent-instructions.md and create a new feature following those patterns"
```

---

## 📖 How to Use This Documentation

### Creating a New Feature

**Step 1:** Plan
```
Feature: Customer Orders
Screens: OrderListScreen, OrderDetailsScreen
Models: OrderModel
Provider: OrderProvider
```

**Step 2:** Follow Template (from .agent-instructions.md)
```
1. Create model in data/models/
2. Create provider in presentation/providers/
3. Create screens in presentation/screens/orders/
4. Register provider in main.dart
```

**Step 3:** Implement (refer to FLUTTER_PROJECT_ARCHITECTURE.md for details)

---

## 🎯 Common Patterns Quick Reference

### 1. Fetch Data Pattern

```dart
// In Provider
Future<void> fetchData() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await ApiService.getData();
    _data = response;
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### 2. Screen with States

```dart
Consumer<Provider>(
  builder: (context, provider, _) {
    if (provider.isLoading) return Loading();
    if (provider.error != null) return Error();
    if (provider.data == null) return Empty();
    return DataView();
  },
)
```

### 3. Provider Usage

```dart
// Read (for actions)
context.read<Provider>().method();

// Watch (for rebuilds)
final data = context.watch<Provider>().data;

// Consumer (selective rebuild)
Consumer<Provider>(
  builder: (context, provider, _) => Widget(),
)
```

---

## 🔧 Folder Structure at a Glance

```
lib/
├── core/
│   ├── theme/          # Colors, TextStyles, Theme
│   ├── constants/      # APIs, Assets, Strings
│   ├── utils/          # Helpers
│   └── routes/         # Navigation
├── data/
│   ├── models/         # Data models
│   ├── database/       # Drift tables
│   └── repositories/   # Data access
├── presentation/
│   ├── providers/      # State management
│   ├── screens/        # UI screens
│   └── widgets/        # Reusable widgets
├── services/
│   └── api/            # API calls
└── shared/
    └── components/     # Shared components
```

---

## 📝 Naming Conventions

```dart
// Files
feature_name_screen.dart
feature_name_provider.dart
model_name_model.dart
custom_component_name.dart

// Classes
FeatureNameScreen
FeatureNameProvider
ModelName
CustomComponentName

// Variables
_privateVariable
publicVariable
CONSTANT_VALUE
```

---

## ✅ Pre-Commit Checklist

Before committing code:

- [ ] Follows folder structure
- [ ] Uses Provider for state
- [ ] Has loading/error/empty states
- [ ] Uses theme constants (no hardcoded colors/styles)
- [ ] Proper null handling
- [ ] No unused imports
- [ ] Formatted code
- [ ] Meaningful variable names
- [ ] Comments for complex logic
- [ ] Tested on debug build

---

## 🎨 Theme Usage

```dart
// Colors
AppColors.primary
AppColors.textBlack
AppColors.background

// Text Styles
AppTextStyles.heading1
AppTextStyles.bodyMedium
AppTextStyles.button

// Dimensions
AppDimensions.paddingM
AppDimensions.radiusL
AppDimensions.iconM
```

---

## 🌐 API Call Pattern

```dart
// GET
final response = await ApiService.fetchData(url, context);
final model = modelFromJson(response);

// POST
final success = await ApiService.postData(url, data, context);

// Multipart
var request = http.MultipartRequest('POST', Uri.parse(url));
request.fields.addAll({...});
request.files.add(await http.MultipartFile.fromPath('file', path));
```

---

## 🔄 State Management Rules

```dart
// ✅ Correct
context.read<Provider>().method();          // Actions
final data = context.watch<Provider>().data; // Rebuilds
Consumer<Provider>(...)                      // Selective

// ❌ Wrong
context.watch<Provider>().method();          // In callbacks
context.read<Provider>().data                // Expecting rebuild
```

---

## 📦 New Feature Checklist

Creating feature "Products":

```
✅ Model
   └── lib/data/models/product_model.dart

✅ Provider
   └── lib/presentation/providers/product_provider.dart

✅ Screens
   ├── lib/presentation/screens/products/product_list_screen.dart
   └── lib/presentation/screens/products/product_details_screen.dart

✅ Service (if needed)
   └── lib/services/api/product_service.dart

✅ Register Provider
   └── main.dart → ChangeNotifierProvider(create: (_) => ProductProvider())

✅ Route
   └── lib/core/routes/app_routes.dart

✅ Components (if needed)
   └── lib/presentation/widgets/cards/product_card.dart
```

---

## 🐛 Common Mistakes to Avoid

### ❌ Don't Do This:

```dart
// Hardcoding
Text('Title', style: TextStyle(fontSize: 16))
Container(color: Color(0xFF375DFB))

// Wrong Provider usage
onPressed: () {
  context.watch<Provider>().method(); // ERROR
}

// No error handling
final data = await apiCall(); // What if it fails?

// All UI in one method
Widget build(BuildContext context) {
  return Scaffold(body: Column(children: [
    // 500 lines of UI code
  ]));
}
```

### ✅ Do This:

```dart
// Use constants
Text('Title', style: AppTextStyles.heading3)
Container(color: AppColors.primary)

// Correct Provider usage
onPressed: () {
  context.read<Provider>().method();
}

// Handle errors
try {
  final data = await apiCall();
} catch (e) {
  handleError(e);
}

// Break into methods
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(children: [
      _buildHeader(),
      _buildContent(),
      _buildFooter(),
    ]),
  );
}
```

---

## 🎓 Learning Path

### Week 1: Basics
- [ ] Read FLUTTER_PROJECT_ARCHITECTURE.md
- [ ] Understand folder structure
- [ ] Learn Provider basics
- [ ] Practice with existing features

### Week 2: Implementation
- [ ] Create a simple feature
- [ ] Follow templates
- [ ] Get code reviewed
- [ ] Learn from feedback

### Week 3: Mastery
- [ ] Create complex features
- [ ] Write reusable components
- [ ] Optimize performance
- [ ] Help others

---

## 📞 Support

**Questions?**
- Check FLUTTER_PROJECT_ARCHITECTURE.md for detailed explanations
- Ask team lead for clarification
- Update documentation if you find gaps

**Found a better pattern?**
- Discuss with team
- Update documentation
- Share with everyone

---

## 🔄 Version History

**v1.0 - June 2026**
- Initial documentation
- Provider pattern
- MVVM-like architecture
- Drift database integration

---

**Remember:** ഈ documentation ഒരു living document ആണ്. Project evolve ചെയ്യുമ്പോൾ ഇതും update ചെയ്യുക!

---

**Quick Links:**
- 📘 Full Guide: [FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md)
- 🤖 AI Instructions: [.agent-instructions.md](.agent-instructions.md)
- 📋 This Guide: [ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)

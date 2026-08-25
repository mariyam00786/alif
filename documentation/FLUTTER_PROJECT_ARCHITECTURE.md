# Flutter Project Architecture Documentation

> ഈ documentation ഉപയോഗിച്ച് നിങ്ങളുടെ Flutter പ്രോജക്ടുകൾ standardized ആയി develop ചെയ്യാം.

---

## Table of Contents

1. [Project Architecture Overview](#project-architecture-overview)
2. [Folder Structure](#folder-structure)
3. [State Management - Provider Pattern](#state-management---provider-pattern)
4. [Model Creation](#model-creation)
5. [API Data Fetching](#api-data-fetching)
6. [Screen Development](#screen-development)
7. [Reusable Components](#reusable-components)
8. [Theme & Styling](#theme--styling)
9. [Database Integration](#database-integration)
10. [Best Practices](#best-practices)

---

## Project Architecture Overview

ഈ project **MVVM-like architecture** ആണ് follow ചെയ്യുന്നത്, Provider state management ഉപയോഗിച്ച്.

### Architecture Layers:

```
┌─────────────────────────────────────┐
│           UI Layer (Screens)        │
│   - StatelessWidgets                │
│   - Consumer widgets                │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│      Business Logic (Providers)     │
│   - State Management                │
│   - API Calls                       │
│   - Data Processing                 │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│       Data Layer                    │
│   - Models                          │
│   - Services (API)                  │
│   - Database (Drift)                │
└─────────────────────────────────────┘
```

---

## Folder Structure

നിലവിലുള്ള project structure:

```
lib/
├── main.dart                          # App entry point
├── components/                        # Reusable UI components
│   ├── custom_app_bar.dart
│   ├── custom_submit_button.dart
│   ├── login_text_form_field.dart
│   └── ...
├── constants/                         # App-wide constants
│   ├── apis.dart                      # API endpoints
│   ├── assets.dart                    # Asset paths
│   ├── colors.dart                    # Color palette
│   ├── string_class.dart              # String constants
│   └── textstyles.dart                # Text styles
├── database/                          # Local database (Drift)
│   ├── agent_profile_database.dart
│   ├── collection_history_database.dart
│   └── ...
├── model/                             # Data models
│   ├── collection_history_model.dart
│   ├── customer_details_model.dart
│   └── ...
├── provider/                          # State management
│   ├── collection_provider.dart
│   ├── collection_history_provider.dart
│   └── ...
├── routes/                            # Navigation routes
│   └── app_routes.dart
├── screens/                           # UI screens
│   ├── collection_history/
│   │   └── collection_history_screen.dart
│   ├── collect_payment/
│   │   └── collect_emi_screen.dart
│   └── ...
├── services/                          # API & Business Services
│   ├── fetch_data_service.dart
│   └── ...
├── shimmers/                          # Loading skeletons
│   └── ...
└── utils/                             # Utility functions
    ├── app_utils.dart
    ├── shared_utils.dart
    └── ...
```

### Recommended Enhanced Structure (Future Projects):

```
lib/
├── main.dart
├── core/                              # Core functionality
│   ├── constants/
│   │   ├── apis.dart
│   │   ├── assets.dart
│   │   └── strings.dart
│   ├── theme/                         # ⭐ New: Centralized theming
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_theme.dart
│   │   └── dimensions.dart
│   ├── utils/
│   │   ├── app_utils.dart
│   │   ├── validators.dart
│   │   └── date_utils.dart
│   └── routes/
│       └── app_routes.dart
├── data/                              # Data layer
│   ├── models/
│   ├── database/
│   └── repositories/                  # ⭐ New: Repository pattern
│       └── collection_repository.dart
├── domain/                            # ⭐ New: Business logic
│   ├── entities/
│   └── use_cases/
├── presentation/                      # UI layer
│   ├── screens/
│   ├── widgets/                       # Shared widgets
│   │   ├── buttons/
│   │   ├── inputs/
│   │   ├── cards/
│   │   └── dialogs/
│   └── providers/                     # State management
├── services/                          # External services
│   ├── api/
│   │   ├── api_client.dart
│   │   └── api_endpoints.dart
│   ├── local/
│   │   └── storage_service.dart
│   └── network/
│       └── network_service.dart
└── shared/                            # ⭐ Shared resources
    ├── components/                    # Reusable components
    ├── extensions/
    └── mixins/
```

---

## State Management - Provider Pattern

ഈ project **Provider** state management ആണ് ഉപയോഗിക്കുന്നത്.

### Provider Setup

#### 1. Provider Class Structure

```dart
import 'package:flutter/material.dart';

class CollectionHistoryProvider extends ChangeNotifier {
  // Private state variables
  bool _isLoading = false;
  String? _error;
  List<DataModel>? _data;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DataModel>? get data => _data;
  
  // Constructor
  CollectionHistoryProvider() {
    _initialize();
  }
  
  // Initialize method
  Future<void> _initialize() async {
    await fetchData();
  }
  
  // Business logic methods
  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // API call or database query
      final result = await _apiService.getData();
      _data = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update methods
  void updateFilter(String filter) {
    // Update logic
    notifyListeners();
  }
}
```

#### 2. Provider Registration (main.dart)

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CollectionHistoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CollectionProvider(
            database: ServiceLocator.instance<EmiCollectionDatabase>(),
          ),
        ),
        // Add more providers here
      ],
      child: MyApp(),
    ),
  );
}
```

#### 3. Using Provider in Screens

**Method 1: Consumer Widget (Recommended for specific rebuilds)**

```dart
Consumer<CollectionHistoryProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (provider.error != null) {
      return Text('Error: ${provider.error}');
    }
    
    return ListView.builder(
      itemCount: provider.data?.length ?? 0,
      itemBuilder: (context, index) {
        final item = provider.data![index];
        return ListTile(title: Text(item.name));
      },
    );
  },
)
```

**Method 2: context.read() (For one-time actions)**

```dart
// For calling methods without listening to changes
onPressed: () {
  context.read<CollectionProvider>().collectEmi(customerId);
}
```

**Method 3: context.watch() (For reading values with rebuild)**

```dart
Widget build(BuildContext context) {
  final provider = context.watch<CollectionHistoryProvider>();
  
  return Text(provider.todayCollected.toString());
}
```

### Provider Best Practices

✅ **DO:**
- Use `ChangeNotifier` for state management
- Call `notifyListeners()` after state changes
- Use `Consumer` for selective rebuilds
- Use `context.read()` for actions without rebuilds
- Initialize providers in constructor or `_initialize()` method
- Handle loading and error states

❌ **DON'T:**
- Call `notifyListeners()` inside build methods
- Use `context.watch()` inside callbacks
- Expose mutable state directly (use getters)
- Forget to dispose controllers in provider

---

## Model Creation

Models ഉണ്ടാക്കുമ്പോൾ follow ചെയ്യേണ്ട pattern:

### Model Structure

```dart
// To parse this JSON data, do
//
//     final collectionHistoryModel = collectionHistoryModelFromJson(jsonString);

import 'dart:convert';

// Top-level parsing functions
CollectionHistoryModel collectionHistoryModelFromJson(String str) => 
    CollectionHistoryModel.fromJson(json.decode(str));

String collectionHistoryModelToJson(CollectionHistoryModel data) => 
    json.encode(data.toJson());

// Main Model Class
class CollectionHistoryModel {
  num? amountCollected;
  num? cashCollected;
  num? bankTransferCollected;
  List<EmiHistoryList>? emiHistory;

  CollectionHistoryModel({
    this.amountCollected,
    this.cashCollected,
    this.bankTransferCollected,
    this.emiHistory,
  });

  // FromJson factory constructor
  factory CollectionHistoryModel.fromJson(Map<String, dynamic> json) => 
      CollectionHistoryModel(
        amountCollected: json["amount_collected"],
        cashCollected: json["cash_collected"],
        bankTransferCollected: json["bank_transfer_collected"],
        emiHistory: json["emi_history"] == null 
            ? [] 
            : List<EmiHistoryList>.from(
                json["emi_history"]!.map((x) => EmiHistoryList.fromJson(x))
              ),
      );

  // ToJson method
  Map<String, dynamic> toJson() => {
    "amount_collected": amountCollected,
    "cash_collected": cashCollected,
    "bank_transfer_collected": bankTransferCollected,
    "emi_history": emiHistory == null 
        ? [] 
        : List<dynamic>.from(emiHistory!.map((x) => x.toJson())),
  };
}

// Nested Model Class
class EmiHistoryList {
  String? transactionId;
  String? customerName;
  String? transactionMode;
  num? emiAmount;
  String? status;
  String? createdAt;
  String? screenshot;
  String? paymentReferenceNumber;

  EmiHistoryList({
    this.transactionId,
    this.customerName,
    this.transactionMode,
    this.emiAmount,
    this.status,
    this.createdAt,
    this.screenshot,
    this.paymentReferenceNumber,
  });

  factory EmiHistoryList.fromJson(Map<String, dynamic> json) => EmiHistoryList(
    transactionId: json["transaction_id"],
    customerName: json["customer_name"],
    transactionMode: json["transaction_mode"],
    emiAmount: json["emi_amount"] ?? 0.0,  // Default value
    status: json["status"],
    createdAt: json["created_at"],
    screenshot: json["screenshot"],
    paymentReferenceNumber: json["payment_reference_number"],
  );

  Map<String, dynamic> toJson() => {
    "transaction_id": transactionId,
    "customer_name": customerName,
    "transaction_mode": transactionMode,
    "emi_amount": emiAmount,
    "status": status,
    "created_at": createdAt,
    "screenshot": screenshot,
    "payment_reference_number": paymentReferenceNumber,
  };
}
```

### Model Creation Checklist

✅ **Follow these steps:**

1. **Nullable vs Non-nullable**: 
   - API-ൽ നിന്നും വരുന്ന data nullable ആയി declare ചെയ്യുക (`String?`, `int?`)
   - Required fields non-nullable ആക്കുക

2. **Default Values**: 
   - Null safety-ക്ക് default values കൊടുക്കുക
   ```dart
   emiAmount: json["emi_amount"] ?? 0.0,
   ```

3. **List Handling**:
   ```dart
   emiHistory: json["emi_history"] == null 
       ? [] 
       : List<EmiHistoryList>.from(
           json["emi_history"]!.map((x) => EmiHistoryList.fromJson(x))
         ),
   ```

4. **Comments**: Top-ലേക്ക് parsing function examples കൊടുക്കുക

5. **File Naming**: `model_name_model.dart` (e.g., `collection_history_model.dart`)

---

## API Data Fetching

### Service Pattern

API calls-നു dedicated service class ഉപയോഗിക്കുക:

#### GetServiceUtils (GET Requests)

```dart
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GetServiceUtils {
  static Future<String> fetchData(String getUrl, BuildContext context) async {
    try {
      final url = Uri.parse(getUrl);
      String token = await SharedUtils.getString(StringClass.token);
      
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          log('$url: ${response.body}');
        }
        return response.body;
      } else if (response.statusCode == 401) {
        // Session expired - clear and redirect
        SharedPreferences preferences = await SharedPreferences.getInstance();
        await preferences.clear();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const SplashScreen()
            )
          );
          AppUtils.showInSnackBarNormal(
            'Session Expired, Please Login Again', 
            context
          );
        }
        throw Exception('Session Expired');
      } else if (response.statusCode == 500) {
        if (context.mounted) {
          AppUtils.showInSnackBarNormal('Something went wrong', context);
        }
        throw Exception('Server Error');
      } else {
        throw Exception('Failed to get Data');
      }
    } on SocketException catch (_) {
      throw Exception('No Internet Connection');
    } catch (e) {
      rethrow;
    }
  }
}
```

#### POST Request with Multipart

```dart
Future<bool> _sendBankUpiRequest(String url, String customerId) async {
  String token = await SharedUtils.getString(StringClass.token);
  var request = http.MultipartRequest('POST', Uri.parse(url));

  request.headers.addAll({'Authorization': 'Bearer $token'});

  request.fields.addAll({
    'customer_id': customerId,
    'emi_amount': _amount.text,
    'transaction_type': 'paid',
    'transaction_mode': 'bank',
    'payment_reference_no': _transactionId.text,
    'description': ''
  });

  // Add file if exists
  if (_screenshotPath != null) {
    request.files.add(
      await http.MultipartFile.fromPath('screenshot', _screenshotPath!)
    );
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    // Handle success
    await _handleSuccessResponse(customerId, response);
    return true;
  } else if (response.statusCode == 413) {
    AppUtils.showInSnackBarNormal('File size is too large', context);
    return false;
  } else {
    AppUtils.showInSnackBarNormal('Something Went Wrong', context);
    return false;
  }
}
```

### API Integration in Provider

```dart
Future<void> fetchCollectionHistory(BuildContext context) async {
  _isSyncing = true;
  _error = null;
  notifyListeners();

  try {
    // Build query parameters
    Map<String, String> queryParams = {};
    if (_selectedDate != null) {
      queryParams['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
    if (_selectedStatus != null) {
      queryParams['status'] = _selectedStatus!;
    }

    // Build URL with query params
    String url = Apis.collectionHistoryUrl();
    if (queryParams.isNotEmpty) {
      url += '?' + queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
    }

    // Fetch data
    final response = await GetServiceUtils.fetchData(url, context);
    
    // Parse response
    final model = collectionHistoryModelFromJson(response);
    
    // Update state
    _collectionHistory = model;
    _updateSummaryData();
    
    // Save to database for offline access
    await _saveToDatabase(model);
    
  } catch (e) {
    _error = e.toString();
    debugPrint('Error fetching collection history: $e');
    
    // Load from database if API fails
    await _loadFromDatabase();
  } finally {
    _isSyncing = false;
    notifyListeners();
  }
}
```

---

## Screen Development

Screen develop ചെയ്യുമ്പോൾ follow ചെയ്യേണ്ട pattern:

### Screen Structure

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionHistoryScreen extends StatelessWidget {
  const CollectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Cleanup when screen pops
        context.read<CollectionHistoryProvider>().clearFilters();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            _buildAppBar(context),
            
            const SizedBox(height: 20),
            
            // Filters
            _buildFilters(context),
            
            const SizedBox(height: 20),
            
            // Summary Cards
            _buildSummarySection(context),
            
            Divider(
              color: AppColors.extraLightGrey,
              height: 32,
              thickness: 1,
            ),
            
            // List Content
            Expanded(
              child: _buildListContent(context),
            ),
          ],
        ),
      ),
    );
  }

  // Break into smaller widget methods
  Widget _buildAppBar(BuildContext context) {
    return CustomAppbarWidget(
      bottomContent: Row(
        children: [
          // Back button
          Consumer<CollectionHistoryProvider>(
            builder: (context, provider, _) => GestureDetector(
              onTap: () {
                provider.clearFilters();
                provider.fetchCollectionHistory(context);
                Navigator.pop(context);
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(AppImages.arrowBack),
                ),
              ),
            )
          ),
          const SizedBox(width: 20),
          
          // Title
          SizedBox(
            width: MediaQuery.of(context).size.width - 150,
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'Collection History',
                  style: AppTextStyles.manrope600TextStyle(
                    16, 
                    AppColors.textBlack
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(BuildContext context) {
    return Consumer<CollectionHistoryProvider>(
      builder: (context, provider, _) {
        // Loading state
        if (provider.isSyncing) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final history = provider.filteredHistory;
        
        // Empty state
        if (history == null || history.isEmpty) {
          return Center(
            child: Text(
              'No Collection Found',
              style: AppTextStyles.manrope400TextStyle(
                14, 
                AppColors.textGrey
              ),
            ),
          );
        }

        // List with pull-to-refresh
        return RefreshIndicator(
          onRefresh: () => provider.refreshData(context),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildListItem(context, item);
            },
          ),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, EmiHistoryList item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () => showPaymentDetails(context, item),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName ?? '',
                    style: AppTextStyles.manrope600TextStyle(
                      14, 
                      AppColors.textBlack
                    ),
                  ),
                  Text(
                    '${DateFormat('hh:mm a').format(DateTime.parse(item.createdAt!))} - ${item.transactionMode} Payment',
                    style: AppTextStyles.manrope400TextStyle(
                      13, 
                      AppColors.textGrey
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ ${NumberFormat('#,##,###').format(item.emiAmount)}',
                  style: AppTextStyles.manrope600TextStyle(
                    14, 
                    AppColors.textBlack
                  ),
                ),
                Text(
                  _getStatusTitle(item.status ?? ''),
                  style: AppTextStyles.manrope600TextStyle(
                    13,
                    _getStatusColor(item.status ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppColors.green;
      case 'rejected':
      case 'failed':
        return AppColors.red;
      case 'inprogress':
      default:
        return AppColors.orange;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Approved';
      case 'rejected':
      case 'failed':
        return 'Rejected';
      case 'inprogress':
      default:
        return 'In Progress';
    }
  }
}
```

### Screen Development Best Practices

✅ **DO:**
- Use `StatelessWidget` with Provider (avoid `StatefulWidget` unless necessary)
- Break complex screens into smaller widget methods
- Use `Consumer` for specific rebuilds
- Handle loading, error, and empty states
- Use `const` where possible for performance
- Add pull-to-refresh where applicable
- Use PopScope for cleanup when screen pops

❌ **DON'T:**
- Put all UI in single build method
- Use `setState` when Provider can handle it
- Hardcode strings (use constants)
- Forget to handle null values
- Call async methods directly in build

---

## Reusable Components

Reusable components `lib/components/` folder-ൽ സൂക്ഷിക്കുക.

### Example: Custom Button

```dart
// lib/components/custom_submit_button.dart

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/textstyles.dart';

class CustomSubmitButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final Widget? leadingIcon;

  const CustomSubmitButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height ?? 56,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.manrope600TextStyle(
                        16,
                        textColor ?? Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

### Usage:

```dart
CustomSubmitButton(
  title: 'Submit Payment',
  onTap: () {
    context.read<CollectionProvider>().collectEmi(customerId);
  },
  isLoading: context.watch<CollectionProvider>().isLoading,
)
```

### Component Guidelines

✅ **Create reusable components for:**
- Buttons (primary, secondary, outlined)
- Text fields
- Cards
- App bars
- Dialogs
- Bottom sheets
- Loading indicators
- Empty state widgets

✅ **Component naming convention:**
- `custom_[component_name].dart` (e.g., `custom_submit_button.dart`)

---

## Theme & Styling

### Current Structure

```
lib/constants/
├── colors.dart          # Color palette
└── textstyles.dart      # Text styles
```

### Recommended Enhanced Structure

```
lib/core/theme/
├── app_colors.dart
├── app_text_styles.dart
├── app_theme.dart       # ThemeData configuration
└── dimensions.dart      # Spacing, sizes
```

### Color System

```dart
// lib/core/theme/app_colors.dart

import 'dart:ui';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF375DFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF38C793);
  static const Color red = Color(0xFFEA134B);
  static const Color blue = Color(0xFF375DFB);
  static const Color orange = Color(0xFFF17B2C);
  static const Color yellow = Color(0xFFF2AE40);
  static const Color grey = Color(0xFFF6F8FA);
  static const Color lightGrey = Color(0xFFE2E4E9);

  // Color variants with opacity
  static Color greenLight = green.withOpacity(0.15);
  static Color redLight = red.withOpacity(0.10);
  static Color blueLight = blue.withOpacity(0.10);
  static Color extraLightGrey = lightGrey.withOpacity(0.5);

  // Text colors
  static const Color textBlack = Color(0xFF0A0D14);
  static const Color textGrey = Color(0xFF525866);
  static const Color textSlateGrey = Color(0xFF868C98);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFf6f8fa);
  static const Color surfaceBackground = Color(0xFFF5F5F5);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
}
```

### Text Styles System

```dart
// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  static const String primaryFontName = 'Manrope';
  static const double textHeight = 1.4;

  // Weight 400 (Regular)
  static TextStyle manrope400TextStyle(double fontSize, Color color) {
    return TextStyle(
      fontFamily: primaryFontName,
      color: color,
      fontWeight: FontWeight.w400,
      height: textHeight,
      fontSize: fontSize,
    );
  }

  // Weight 500 (Medium)
  static TextStyle manrope500TextStyle(double fontSize, Color color) {
    return TextStyle(
      fontFamily: primaryFontName,
      color: color,
      fontWeight: FontWeight.w500,
      height: textHeight,
      fontSize: fontSize,
    );
  }

  // Weight 600 (SemiBold)
  static TextStyle manrope600TextStyle(double fontSize, Color color) {
    return TextStyle(
      fontFamily: primaryFontName,
      color: color,
      fontWeight: FontWeight.w600,
      height: textHeight,
      fontSize: fontSize,
    );
  }

  // Weight 600 with underline
  static TextStyle manrope600TextUnderline(double fontSize, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      fontFamily: primaryFontName,
      decoration: TextDecoration.underline,
      decorationThickness: 0.7,
    );
  }

  // Weight 700 (Bold)
  static TextStyle manrope700TextStyle(double fontSize, Color color) {
    return TextStyle(
      fontFamily: primaryFontName,
      color: color,
      fontWeight: FontWeight.w700,
      height: textHeight,
      fontSize: fontSize,
    );
  }

  // Predefined text styles for common use cases
  static TextStyle get heading1 => manrope700TextStyle(24, AppColors.textBlack);
  static TextStyle get heading2 => manrope600TextStyle(20, AppColors.textBlack);
  static TextStyle get heading3 => manrope600TextStyle(18, AppColors.textBlack);
  static TextStyle get bodyLarge => manrope400TextStyle(16, AppColors.textGrey);
  static TextStyle get bodyMedium => manrope400TextStyle(14, AppColors.textGrey);
  static TextStyle get bodySmall => manrope400TextStyle(12, AppColors.textGrey);
  static TextStyle get button => manrope600TextStyle(16, AppColors.white);
  static TextStyle get caption => manrope400TextStyle(12, AppColors.textSlateGrey);
}
```

### Dimensions System (Recommended)

```dart
// lib/core/theme/dimensions.dart

class AppDimensions {
  // Padding & Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button Heights
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;
}
```

### Theme Configuration

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.primaryFontName,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textBlack),
        titleTextStyle: AppTextStyles.heading3,
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.white,
      ),
      
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.blue,
        error: AppColors.error,
        background: AppColors.background,
        surface: AppColors.white,
      ),
    );
  }
}
```

### Usage in main.dart

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [...],
      child: MaterialApp(
        title: 'Choice Agent App',
        theme: AppTheme.lightTheme,  // Apply theme
        home: const SplashScreen(),
      ),
    ),
  );
}
```

---

## Database Integration

ഈ project **Drift** (formerly Moor) ആണ് local database-നായി ഉപയോഗിക്കുന്നത്.

### Database Setup

```dart
// lib/database/collection_history_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'collection_history_database.g.dart';

// Define table
class CollectionHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get transactionMode => text().nullable()();
  RealColumn get emiAmount => real().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get screenshot => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// Database class
@DriftDatabase(tables: [CollectionHistoryTable])
class CollectionHistoryDatabase extends _$CollectionHistoryDatabase {
  CollectionHistoryDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Queries
  Future<List<CollectionHistoryTableData>> getAllCollections() =>
      select(collectionHistoryTable).get();

  Future<List<CollectionHistoryTableData>> getUnsyncedCollections() =>
      (select(collectionHistoryTable)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();

  Future<int> insertCollection(CollectionHistoryTableCompanion entry) =>
      into(collectionHistoryTable).insert(entry);

  Future<bool> updateCollection(CollectionHistoryTableCompanion entry) =>
      update(collectionHistoryTable).replace(entry);

  Future<int> deleteCollection(int id) =>
      (delete(collectionHistoryTable)..where((tbl) => tbl.id.equals(id))).go();
}

// Connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'collection_history.sqlite'));
    return NativeDatabase(file);
  });
}
```

### Using Database in Provider

```dart
class CollectionHistoryProvider extends ChangeNotifier {
  final CollectionHistoryDatabase database;

  CollectionHistoryProvider({required this.database});

  Future<void> _saveToDatabase(CollectionHistoryModel model) async {
    for (var item in model.emiHistory ?? []) {
      final entry = CollectionHistoryTableCompanion.insert(
        transactionId: Value(item.transactionId),
        customerName: Value(item.customerName),
        transactionMode: Value(item.transactionMode),
        emiAmount: Value(item.emiAmount?.toDouble()),
        status: Value(item.status),
        createdAt: Value(DateTime.parse(item.createdAt!)),
        screenshot: Value(item.screenshot),
        isSynced: const Value(true),
      );
      await database.insertCollection(entry);
    }
  }

  Future<void> _loadFromDatabase() async {
    final collections = await database.getAllCollections();
    // Convert to model and update state
  }
}
```

---

## Best Practices

### 1. Code Organization

✅ **DO:**
- One widget per file
- Group related files in folders
- Use barrel files (index.dart) for exports
- Keep business logic in providers
- Use services for API calls

### 2. Performance

✅ **DO:**
- Use `const` constructors where possible
- Use `Consumer` for selective rebuilds
- Implement pagination for large lists
- Cache images and data
- Use `ListView.builder` instead of `ListView`

❌ **DON'T:**
- Rebuild entire screen on small changes
- Load all data at once
- Call `notifyListeners()` unnecessarily

### 3. Error Handling

✅ **DO:**
```dart
try {
  final result = await apiCall();
  _data = result;
} on SocketException {
  _error = 'No Internet Connection';
} on HttpException {
  _error = 'Server Error';
} catch (e) {
  _error = 'Something went wrong';
} finally {
  _isLoading = false;
  notifyListeners();
}
```

### 4. Null Safety

✅ **DO:**
```dart
// Null-aware operators
final name = user?.name ?? 'Unknown';

// Null check before use
if (data != null) {
  processData(data);
}

// List null handling
final items = response.items ?? [];
```

### 5. Navigation

✅ **DO:**
```dart
// Named routes
Navigator.pushNamed(context, '/details', arguments: customerId);

// Pop with result
Navigator.pop(context, result);

// Replace
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => NewScreen()),
);
```

### 6. State Management Rules

✅ **Provider Pattern:**
```dart
// ✅ Correct: Read for actions
context.read<Provider>().methodName();

// ✅ Correct: Watch for rebuilds
final data = context.watch<Provider>().data;

// ✅ Correct: Consumer for selective rebuilds
Consumer<Provider>(
  builder: (context, provider, child) => Widget(),
)

// ❌ Wrong: Watch in callbacks
onPressed: () {
  context.watch<Provider>().method(); // ERROR
}

// ❌ Wrong: Read with rebuild expectation
final data = context.read<Provider>().data; // Won't rebuild
```

### 7. Asset Management

```dart
// lib/constants/assets.dart
class AppImages {
  static const String logo = 'assets/images/logo.png';
  static const String arrowBack = 'assets/icons/arrow_back.svg';
}

class AppFonts {
  static const String manrope = 'Manrope';
}
```

### 8. String Constants

```dart
// lib/constants/string_class.dart
class StringClass {
  static const String token = 'auth_token';
  static const String userId = 'user_id';
  
  // API Keys
  static const String apiKey = 'api_key';
  
  // Error Messages
  static const String noInternet = 'No Internet Connection';
  static const String serverError = 'Something went wrong';
}
```

### 9. Offline-First Approach

✅ **Pattern:**
```dart
Future<void> fetchData() async {
  try {
    // Try API first
    final response = await apiCall();
    await saveToDatabase(response);
    _data = response;
  } catch (e) {
    // Fallback to database
    final cachedData = await loadFromDatabase();
    _data = cachedData;
  }
  notifyListeners();
}
```

### 10. Clean Code Principles

✅ **DO:**
- Meaningful variable names
- Short functions (< 50 lines)
- Comments for complex logic
- Remove unused imports and code
- Format code consistently

```dart
// ❌ Bad
var d = DateTime.now();
var a = 100;

// ✅ Good
final currentDate = DateTime.now();
final emiAmount = 100;
```

---

## Quick Reference Checklist

### Starting a New Feature

- [ ] Create model in `/model`
- [ ] Create provider in `/provider`
- [ ] Register provider in `main.dart`
- [ ] Create screen in `/screens/[feature_name]`
- [ ] Create reusable components if needed in `/components`
- [ ] Add API endpoints in `/constants/apis.dart`
- [ ] Implement service methods in `/services`
- [ ] Add routes in `/routes`
- [ ] Test offline functionality
- [ ] Handle loading, error, and empty states

### Code Review Checklist

- [ ] Uses Provider for state management
- [ ] Follows folder structure
- [ ] Handles null safety
- [ ] Error handling implemented
- [ ] Offline support added
- [ ] Uses constants for colors/text styles
- [ ] No hardcoded strings
- [ ] Proper widget breakdown
- [ ] Performance optimized (const, Consumer)
- [ ] Comments added for complex logic

---

## Summary

ഈ documentation follow ചെയ്താൽ:

✅ **Consistency**: എല്ലാ developers-ഉം ഒരേ pattern follow ചെയ്യും  
✅ **Maintainability**: Code maintain ചെയ്യാൻ എളുപ്പം  
✅ **Scalability**: Project വളരുന്തോറും manage ചെയ്യാൻ എളുപ്പം  
✅ **Quality**: High-quality, production-ready code  
✅ **Onboarding**: പുതിയ developers-ന് എളുപ്പത്തിൽ മനസ്സിലാകും  

---

**Created:** June 2026  
**Last Updated:** June 2026  
**Version:** 1.0  
**Project:** Choice Agent App

---

## Need Help?

ഈ documentation-ഇൽ എന്തെങ്കിലും doubt ഉണ്ടെങ്കിൽ അല്ലെങ്കിൽ improvements suggest ചെയ്യാനുണ്ടെങ്കിൽ team-നോട് ചോദിക്കുക.

പുതിയ patterns അല്ലെങ്കിൽ best practices കണ്ടെത്തുമ്പോൾ ഈ document update ചെയ്യുക.

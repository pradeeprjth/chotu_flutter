# Chotu Flutter App - Quick Start Guide

This guide will help you get the Flutter app running quickly and understand what's been set up.

## ✅ What's Already Implemented

### 1. Project Setup
- ✅ Flutter project created with web, Android, and iOS support
- ✅ All required dependencies configured in `pubspec.yaml`
- ✅ Complete folder structure following best practices
- ✅ Theme configuration with branded colors
- ✅ Router with role-based navigation guards

### 2. Core Architecture
- ✅ API configuration file (`lib/core/api/api_config.dart`)
- ✅ User model structure (`lib/core/models/user_model.dart`)
- ✅ Auth provider with state management (`lib/features/auth/providers/auth_provider.dart`)
- ✅ Splash screen (`lib/features/auth/views/splash_screen.dart`)
- ✅ App theme (`lib/app/theme.dart`)
- ✅ Router configuration (`lib/app/router.dart`)

### 3. Documentation
- ✅ Comprehensive implementation guide
- ✅ Project README
- ✅ This quick start guide

## 🚀 Getting Started

### Step 1: Install Dependencies

```bash
cd chotu_app
flutter pub get
```

**Note**: You'll see warnings about missing files - this is expected as we need to generate code and create missing placeholder screens.

### Step 2: Create Missing Placeholder Screens

The router references screens that need to be created. Create these placeholder files:

```bash
# Create placeholder screens (run from chotu_app directory)

# Login Screen
cat > lib/features/auth/views/login_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen - To be implemented')),
    );
  }
}
EOF

# Register Screen
cat > lib/features/auth/views/register_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(child: Text('Register Screen - To be implemented')),
    );
  }
}
EOF

# Continue for all other screens...
```

**Or use the automated script** (see below).

### Step 3: Generate JSON Serialization Code

After creating the User model, generate the required code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: Update API Configuration

Edit `lib/core/api/api_config.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // For Android emulator
```

### Step 5: Run the App

```bash
flutter run
```

## 📁 File Creation Status

### ✅ Created Files

```
chotu_app/
├── pubspec.yaml                                    ✅
├── README.md                                        ✅
├── IMPLEMENTATION_GUIDE.md                          ✅
├── QUICK_START.md                                   ✅
├── lib/
│   ├── main.dart                                    ✅
│   ├── app/
│   │   ├── app_widget.dart                         ✅
│   │   ├── router.dart                             ✅
│   │   └── theme.dart                              ✅
│   ├── core/
│   │   ├── api/
│   │   │   └── api_config.dart                     ✅
│   │   └── models/
│   │       └── user_model.dart                     ✅
│   └── features/
│       └── auth/
│           ├── providers/
│           │   └── auth_provider.dart              ✅
│           └── views/
│               └── splash_screen.dart              ✅
```

### 📋 Files To Create

All other screen files need to be created as placeholders. Use this script:

```bash
#!/bin/bash
# create_placeholder_screens.sh

# Navigate to chotu_app directory
cd chotu_app

# Create all placeholder screens
screens=(
  "lib/features/auth/views/login_screen.dart:LoginScreen:Login"
  "lib/features/auth/views/register_screen.dart:RegisterScreen:Register"
  "lib/features/catalog/views/home_screen.dart:HomeScreen:Home"
  "lib/features/catalog/views/category_screen.dart:CategoryScreen:Category"
  "lib/features/catalog/views/product_detail_screen.dart:ProductDetailScreen:Product Detail"
  "lib/features/cart/views/cart_screen.dart:CartScreen:Cart"
  "lib/features/checkout/views/checkout_screen.dart:CheckoutScreen:Checkout"
  "lib/features/orders/views/orders_list_screen.dart:OrdersListScreen:Orders"
  "lib/features/orders/views/order_detail_screen.dart:OrderDetailScreen:Order Detail"
  "lib/features/addresses/views/addresses_screen.dart:AddressesScreen:Addresses"
  "lib/features/addresses/views/address_form_screen.dart:AddressFormScreen:Address Form"
  "lib/features/profile/views/profile_screen.dart:ProfileScreen:Profile"
  "lib/features/admin/dashboard/dashboard_screen.dart:AdminDashboard:Admin Dashboard"
  "lib/features/admin/products/products_list_screen.dart:ProductsListScreen:Products"
  "lib/features/admin/products/product_form_screen.dart:ProductFormScreen:Product Form"
  "lib/features/admin/inventory/inventory_screen.dart:InventoryScreen:Inventory"
  "lib/features/admin/orders/admin_orders_screen.dart:AdminOrdersScreen:Admin Orders"
  "lib/features/admin/orders/admin_order_detail_screen.dart:AdminOrderDetailScreen:Admin Order Detail"
  "lib/features/admin/delivery/delivery_partners_screen.dart:DeliveryPartnersScreen:Delivery Partners"
  "lib/features/delivery_partner/views/delivery_orders_screen.dart:DeliveryOrdersScreen:Delivery Orders"
  "lib/features/delivery_partner/views/delivery_order_detail_screen.dart:DeliveryOrderDetailScreen:Delivery Order Detail"
)

for screen in "${screens[@]}"; do
  IFS=':' read -r file class_name title <<< "$screen"

  cat > "$file" << EOF
import 'package:flutter/material.dart';

class $class_name extends StatelessWidget {
  const $class_name({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: const Center(
        child: Text('$title Screen - To be implemented'),
      ),
    );
  }
}
EOF

  echo "Created $file"
done

echo "✅ All placeholder screens created!"
```

Save this as `create_placeholder_screens.sh` and run:

```bash
chmod +x create_placeholder_screens.sh
./create_placeholder_screens.sh
```

## 🔧 Windows PowerShell Alternative

For Windows users, create `create_placeholder_screens.ps1`:

```powershell
# Create placeholder screens for Windows

$screens = @(
    @{File="lib/features/auth/views/login_screen.dart"; Class="LoginScreen"; Title="Login"},
    @{File="lib/features/auth/views/register_screen.dart"; Class="RegisterScreen"; Title="Register"},
    @{File="lib/features/catalog/views/home_screen.dart"; Class="HomeScreen"; Title="Home"},
    @{File="lib/features/catalog/views/category_screen.dart"; Class="CategoryScreen"; Title="Category"},
    @{File="lib/features/catalog/views/product_detail_screen.dart"; Class="ProductDetailScreen"; Title="Product Detail"},
    @{File="lib/features/cart/views/cart_screen.dart"; Class="CartScreen"; Title="Cart"},
    @{File="lib/features/checkout/views/checkout_screen.dart"; Class="CheckoutScreen"; Title="Checkout"},
    @{File="lib/features/orders/views/orders_list_screen.dart"; Class="OrdersListScreen"; Title="Orders"},
    @{File="lib/features/orders/views/order_detail_screen.dart"; Class="OrderDetailScreen"; Title="Order Detail"},
    @{File="lib/features/addresses/views/addresses_screen.dart"; Class="AddressesScreen"; Title="Addresses"},
    @{File="lib/features/addresses/views/address_form_screen.dart"; Class="AddressFormScreen"; Title="Address Form"},
    @{File="lib/features/profile/views/profile_screen.dart"; Class="ProfileScreen"; Title="Profile"},
    @{File="lib/features/admin/dashboard/dashboard_screen.dart"; Class="AdminDashboard"; Title="Admin Dashboard"},
    @{File="lib/features/admin/products/products_list_screen.dart"; Class="ProductsListScreen"; Title="Products"},
    @{File="lib/features/admin/products/product_form_screen.dart"; Class="ProductFormScreen"; Title="Product Form"},
    @{File="lib/features/admin/inventory/inventory_screen.dart"; Class="InventoryScreen"; Title="Inventory"},
    @{File="lib/features/admin/orders/admin_orders_screen.dart"; Class="AdminOrdersScreen"; Title="Admin Orders"},
    @{File="lib/features/admin/orders/admin_order_detail_screen.dart"; Class="AdminOrderDetailScreen"; Title="Admin Order Detail"},
    @{File="lib/features/admin/delivery/delivery_partners_screen.dart"; Class="DeliveryPartnersScreen"; Title="Delivery Partners"},
    @{File="lib/features/delivery_partner/views/delivery_orders_screen.dart"; Class="DeliveryOrdersScreen"; Title="Delivery Orders"},
    @{File="lib/features/delivery_partner/views/delivery_order_detail_screen.dart"; Class="DeliveryOrderDetailScreen"; Title="Delivery Order Detail"}
)

foreach ($screen in $screens) {
    $content = @"
import 'package:flutter/material.dart';

class $($screen.Class) extends StatelessWidget {
  const $($screen.Class)({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$($screen.Title)')),
      body: const Center(
        child: Text('$($screen.Title) Screen - To be implemented'),
      ),
    );
  }
}
"@

    $content | Out-File -FilePath $screen.File -Encoding UTF8
    Write-Host "Created $($screen.File)"
}

Write-Host "✅ All placeholder screens created!"
```

Run with:

```powershell
.\create_placeholder_screens.ps1
```

## 🎯 Next Steps

### Immediate (To Get App Running)
1. ✅ Install dependencies (`flutter pub get`)
2. ⬜ Create placeholder screens (use script above)
3. ⬜ Fix User model (handle missing `.g.dart` file - see below)
4. ⬜ Run app (`flutter run`)

### User Model Fix

The User model requires generated code. Either:

**Option A**: Comment out json_annotation temporarily

```dart
// In lib/core/models/user_model.dart
// Comment out these lines:
// part 'user_model.g.dart';
// factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
// Map<String, dynamic> toJson() => _$UserToJson(this);
```

**Option B**: Run build_runner (after fixing any errors)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Short Term (Week 1)
1. Implement login screen with form
2. Implement register screen
3. Connect to backend API
4. Implement home screen
5. Test authentication flow

### Medium Term (Week 2-3)
1. Implement product catalog
2. Implement cart functionality
3. Implement checkout
4. Implement order management

### Long Term (Week 4+)
1. Complete admin panel
2. Complete delivery partner app
3. Add comprehensive testing
4. Optimize performance
5. Prepare for release

## 📚 Key Documentation

- **IMPLEMENTATION_GUIDE.md**: Detailed implementation roadmap
- **README.md**: Project overview and setup
- **../backend/README.md**: Backend setup and API docs
- **../story/frontend.md**: Complete frontend specification

## ⚠️ Common Issues

### Issue: Missing .g.dart files
**Solution**: Run `flutter pub run build_runner build` or comment out generated code temporarily

### Issue: Android emulator can't reach localhost
**Solution**: Use `10.0.2.2` instead of `localhost` in API config

### Issue: iOS build fails
**Solution**: Run `cd ios && pod install && cd ..`

### Issue: Web CORS errors
**Solution**: Ensure backend has proper CORS configuration for `http://localhost:PORT`

## 🎉 Success Criteria

You know the setup is complete when:
- ✅ `flutter pub get` completes without errors
- ✅ `flutter run` launches the app
- ✅ Splash screen appears
- ✅ App navigates to login screen
- ✅ No compilation errors

## 💡 Tips

1. **Start Simple**: Get the authentication flow working first
2. **Use Mock Data**: Test UI before connecting to backend
3. **Test on Web First**: Faster iteration during development
4. **Use Hot Reload**: Flutter's best feature - use it liberally
5. **Check DevTools**: Great for debugging state and performance

## 🆘 Need Help?

- Check IMPLEMENTATION_GUIDE.md for detailed architecture
- Review ../story/frontend.md for complete specifications
- Ensure backend is running (see ../backend/README.md)
- Check Flutter version: `flutter --version` (needs 3.9.2+)

Good luck with the implementation! 🚀

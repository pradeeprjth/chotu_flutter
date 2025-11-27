# Chotu Flutter App

A comprehensive Flutter application for instant grocery delivery with three distinct user roles: Customer, Admin, and Delivery Partner.

## Features

### Customer App
- Browse products by categories
- Search and filter products
- Shopping cart management
- Multiple delivery addresses
- COD and Online payment options
- Order tracking with status timeline
- Order history

### Admin Panel
- Dashboard with key metrics
- Product and category management
- Inventory management
- Order management and assignment
- Delivery partner management
- Manual order status updates

### Delivery Partner App
- View assigned orders
- Update delivery status
- Customer address and contact info
- Location sharing (optional)

## Tech Stack

- **Flutter 3+**: Cross-platform framework (Web, Android, iOS)
- **Riverpod**: State management
- **GoRouter**: Declarative routing with role-based guards
- **Dio + Retrofit**: HTTP client and API integration
- **Secure Storage**: Token and sensitive data storage
- **CachedNetworkImage**: Optimized image loading
- **JSON Serialization**: Type-safe API models

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure API Endpoint
Edit `lib/core/api/api_config.dart` and update:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:3000/api/v1';
```

For local development:
- Android Emulator: `http://10.0.2.2:3000/api/v1`
- iOS Simulator: `http://localhost:3000/api/v1`
- Physical Device: `http://YOUR_COMPUTER_IP:3000/api/v1`

### 3. Run the App
```bash
flutter run
```

## Project Structure

```
lib/
├── app/                      # App configuration
├── core/                     # Shared functionality
│   ├── api/                  # API client
│   ├── models/               # Data models
│   ├── services/             # Services
│   ├── widgets/              # Reusable widgets
│   └── utils/                # Utilities
└── features/                 # Feature modules
    ├── auth/
    ├── catalog/
    ├── cart/
    ├── checkout/
    ├── orders/
    ├── admin/
    └── delivery_partner/
```

## Test Credentials

After running backend seed (`npm run seed`):
- **Customer**: customer@chotu.com / customer123
- **Admin**: admin@chotu.com / admin123
- **Delivery**: delivery@chotu.com / delivery123

## Documentation

- **Implementation Guide**: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
- **Backend API**: [../backend/API_DOCUMENTATION.md](../backend/API_DOCUMENTATION.md)
- **Frontend Spec**: [../story/frontend.md](../story/frontend.md)

## Development

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run Tests
```bash
flutter test
```

### Build Release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Status

✅ Project structure and architecture setup complete
🚧 Feature implementation in progress
📋 See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for detailed roadmap

## Resources

- [Flutter Docs](https://docs.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Backend Setup](../backend/README.md)

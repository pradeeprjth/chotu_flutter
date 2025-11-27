# Notification System - Implementation Story

## Overview
Implement a comprehensive push notification system for the Chotu delivery app using Firebase Cloud Messaging (FCM). This system will notify users about order status changes, new orders, delivery assignments, and other important events.

---

## User Stories

### US-1: Customer Order Notifications
**As a** customer
**I want to** receive push notifications about my order status
**So that** I can track my order without constantly checking the app

**Acceptance Criteria:**
- [ ] Receive notification when order is placed successfully
- [ ] Receive notification when order is confirmed by store
- [ ] Receive notification when order is being prepared
- [ ] Receive notification when delivery partner is assigned
- [ ] Receive notification when order is out for delivery
- [ ] Receive notification when order is delivered
- [ ] Receive notification if order is cancelled
- [ ] Tapping notification opens the specific order details

---

### US-2: Admin Order Notifications
**As an** admin
**I want to** receive push notifications for new orders and important events
**So that** I can manage orders promptly

**Acceptance Criteria:**
- [ ] Receive notification when a new user registers
- [ ] Receive notification when a new order is placed (with order value & items count)
- [ ] Receive notification when customer cancels an order
- [ ] Receive notification when delivery partner comes online
- [ ] Tapping notification opens the relevant admin screen

---

### US-3: Delivery Partner Notifications
**As a** delivery partner
**I want to** receive push notifications for delivery assignments
**So that** I can respond quickly to new deliveries

**Acceptance Criteria:**
- [ ] Receive notification when a new order is assigned to me
- [ ] Receive notification when assigned order is ready for pickup
- [ ] Notification shows delivery address summary
- [ ] Tapping notification opens the delivery details

---

## Technical Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ NotificationSvc │  │ FCM Token Mgmt  │  │ Local Notif.    │ │
│  │                 │  │                 │  │ (foreground)    │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │          │
│           └────────────────────┼────────────────────┘          │
│                                │                               │
│                    ┌───────────▼───────────┐                   │
│                    │   Message Handlers    │                   │
│                    │  - Foreground         │                   │
│                    │  - Background         │                   │
│                    │  - Terminated         │                   │
│                    └───────────┬───────────┘                   │
└────────────────────────────────┼───────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Firebase Cloud        │
                    │   Messaging (FCM)       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Backend Server        │
                    │   (Node.js)             │
                    │   - Store FCM tokens    │
                    │   - Send notifications  │
                    └─────────────────────────┘
```

### Notification Flow

```
1. User Action (e.g., Place Order)
         │
         ▼
2. Backend processes action
         │
         ▼
3. Backend identifies recipients (customer, admin, delivery partner)
         │
         ▼
4. Backend retrieves FCM tokens for recipients
         │
         ▼
5. Backend sends notification via FCM API
         │
         ▼
6. FCM delivers to devices
         │
         ▼
7. App receives and displays notification
         │
         ▼
8. User taps → Deep link to relevant screen
```

---

## Notification Scenarios Matrix

| Event | Customer | Admin | Delivery Partner |
|-------|----------|-------|------------------|
| New User Registration | - | ✅ | - |
| Order Placed | ✅ | ✅ | - |
| Order Confirmed | ✅ | - | - |
| Order Preparing | ✅ | - | - |
| Delivery Partner Assigned | ✅ | - | ✅ |
| Order Ready for Pickup | - | - | ✅ |
| Out for Delivery | ✅ | - | - |
| Order Delivered | ✅ | - | - |
| Order Cancelled (by customer) | ✅ | ✅ | ✅ (if assigned) |
| Order Cancelled (by admin) | ✅ | - | ✅ (if assigned) |
| Delivery Partner Online | - | ✅ | - |

---

## Notification Payload Structure

### Standard Notification Payload
```json
{
  "notification": {
    "title": "Order Confirmed",
    "body": "Your order #ORD123 has been confirmed"
  },
  "data": {
    "type": "ORDER_STATUS_CHANGED",
    "orderId": "order_id_here",
    "orderNumber": "ORD123",
    "status": "CONFIRMED",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

### Notification Types
```dart
enum NotificationType {
  // Customer notifications
  ORDER_PLACED,
  ORDER_CONFIRMED,
  ORDER_PREPARING,
  ORDER_OUT_FOR_DELIVERY,
  ORDER_DELIVERED,
  ORDER_CANCELLED,
  DELIVERY_PARTNER_ASSIGNED,

  // Admin notifications
  NEW_USER_REGISTERED,
  NEW_ORDER_RECEIVED,
  ORDER_CANCELLED_BY_CUSTOMER,
  DELIVERY_PARTNER_ONLINE,

  // Delivery partner notifications
  NEW_DELIVERY_ASSIGNED,
  ORDER_READY_FOR_PICKUP,
}
```

---

## Implementation Steps

### Phase 1: Firebase Setup
1. Create Firebase project
2. Add Android app to Firebase project
3. Download and add `google-services.json`
4. Add Firebase dependencies to `pubspec.yaml`
5. Configure Android `build.gradle` files

### Phase 2: Flutter Implementation
1. Create `NotificationService` class
2. Initialize Firebase in `main.dart`
3. Request notification permissions
4. Implement FCM token retrieval and storage
5. Create message handlers:
   - `onMessage` (foreground)
   - `onMessageOpenedApp` (background tap)
   - `onBackgroundMessage` (terminated)
6. Implement local notifications for foreground display
7. Add deep linking from notifications

### Phase 3: Backend Integration
1. Create API endpoint to register FCM tokens
2. Store FCM tokens in database (linked to user)
3. Create notification sending service
4. Trigger notifications on relevant events

### Phase 4: Testing
1. Test foreground notifications
2. Test background notifications
3. Test terminated state notifications
4. Test deep linking
5. Test notification permissions handling

---

## Dependencies Required

### Flutter Packages
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
```

### Android Configuration
- Minimum SDK: 21 (already set)
- Target SDK: 34 (already set)
- Google Services plugin

---

## File Structure

```
lib/
├── core/
│   └── services/
│       └── notification_service.dart    # Main notification service
│
├── features/
│   └── notifications/
│       ├── models/
│       │   └── notification_model.dart  # Notification data model
│       ├── providers/
│       │   └── notification_provider.dart
│       └── views/
│           └── notifications_screen.dart # Optional: notification history
│
└── main.dart                            # Firebase initialization
```

---

## API Endpoints (Backend)

### Register FCM Token
```
POST /api/v1/notifications/register-token
Body: { "fcmToken": "token_here", "platform": "android|ios" }
```

### Update FCM Token
```
PUT /api/v1/notifications/update-token
Body: { "oldToken": "old_token", "newToken": "new_token" }
```

### Remove FCM Token (logout)
```
DELETE /api/v1/notifications/remove-token
Body: { "fcmToken": "token_here" }
```

---

## Notification Messages

### Customer Messages
| Event | Title | Body |
|-------|-------|------|
| Order Placed | Order Placed Successfully | Your order #{orderNumber} has been placed. Total: ₹{total} |
| Order Confirmed | Order Confirmed | Great news! Your order #{orderNumber} has been confirmed |
| Order Preparing | Order Being Prepared | Your order #{orderNumber} is now being prepared |
| Partner Assigned | Delivery Partner Assigned | {partnerName} will deliver your order #{orderNumber} |
| Out for Delivery | Out for Delivery | Your order #{orderNumber} is on its way! |
| Delivered | Order Delivered | Your order #{orderNumber} has been delivered. Enjoy! |
| Cancelled | Order Cancelled | Your order #{orderNumber} has been cancelled |

### Admin Messages
| Event | Title | Body |
|-------|-------|------|
| New User | New User Registered | {userName} just signed up. Phone: {phone} |
| New Order | New Order Received | Order #{orderNumber} - ₹{total} - {itemCount} items |
| Order Cancelled | Order Cancelled | Order #{orderNumber} cancelled by customer |
| Partner Online | Delivery Partner Online | {partnerName} is now available for deliveries |

### Delivery Partner Messages
| Event | Title | Body |
|-------|-------|------|
| New Assignment | New Delivery Assigned | New delivery! Order #{orderNumber} to {deliveryArea} |
| Ready for Pickup | Order Ready for Pickup | Order #{orderNumber} is ready. Please pick up from store |

---

## Error Handling

1. **Token Registration Failure**: Retry with exponential backoff
2. **Permission Denied**: Show in-app banner explaining benefits
3. **Network Error**: Queue notifications locally, sync when online
4. **Invalid Token**: Request new token and update backend

---

## Security Considerations

1. FCM tokens are stored securely in backend
2. Tokens are removed on user logout
3. Notifications don't contain sensitive data in body
4. Deep links are validated before navigation

---

## Success Metrics

1. Notification delivery rate > 95%
2. User opt-in rate for notifications > 80%
3. Order-related notification tap rate > 30%
4. Reduced customer support queries about order status

---

## Future Enhancements

1. In-app notification center with history
2. Notification preferences (enable/disable by type)
3. Rich notifications with images
4. Scheduled notifications (e.g., "Your favorite items are on sale!")
5. Silent notifications for data sync

---

## Implementation Status

### Flutter App (COMPLETED)
- [x] Added Firebase dependencies to pubspec.yaml
- [x] Configured Android for Firebase (settings.gradle.kts, build.gradle.kts)
- [x] Added notification permissions to AndroidManifest.xml
- [x] Created NotificationService (lib/core/services/notification_service.dart)
- [x] Created NotificationProvider (lib/core/providers/notification_provider.dart)
- [x] Updated main.dart with Firebase initialization
- [x] Updated app_widget.dart to initialize notifications
- [x] Integrated with auth flow for FCM token management

### Backend (COMPLETED)
- [x] Added firebase-admin dependency to package.json
- [x] Created FcmToken model (src/modules/notifications/fcmToken.model.ts)
- [x] Created NotificationService (src/modules/notifications/notification.service.ts)
- [x] Created notification routes (src/modules/notifications/notification.routes.ts)
- [x] Registered routes in app.ts
- [x] Integrated with order events (order creation, status changes, cancellation)
- [x] Integrated with auth events (new user registration)
- [x] Integrated with delivery events (assignment, status updates, partner online)

### Pending Setup (Manual Steps Required)
- [ ] Create Firebase project at https://console.firebase.google.com
- [ ] Add Android app with package name: com.chotu.chotu_app
- [ ] Download google-services.json and place in android/app/
- [ ] Download Firebase service account JSON for backend
- [ ] Set FIREBASE_SERVICE_ACCOUNT environment variable on backend server

---

## Environment Variables Required (Backend)

```env
# Firebase Admin SDK credentials
# Option 1: Service account JSON as string
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"..."}

# Option 2: Path to service account file
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

---

## Files Created/Modified

### Flutter App
```
lib/
├── main.dart                                    # Updated - Firebase init
├── app/
│   └── app_widget.dart                         # Updated - Notification init
├── core/
│   ├── services/
│   │   └── notification_service.dart           # NEW - FCM service
│   └── providers/
│       └── notification_provider.dart          # NEW - State management
└── features/
    └── auth/
        └── providers/
            └── auth_provider.dart              # Updated - FCM integration

android/
├── app/
│   ├── build.gradle.kts                        # Updated - Google Services plugin
│   └── src/main/
│       ├── AndroidManifest.xml                 # Updated - Permissions & FCM config
│       └── res/values/
│           └── colors.xml                      # NEW - Notification color
└── settings.gradle.kts                         # Updated - Google Services plugin
```

### Backend
```
src/
├── server.ts                                   # Updated - Firebase init
├── app.ts                                      # Updated - Notification routes
└── modules/
    ├── notifications/
    │   ├── fcmToken.model.ts                   # NEW - FCM token storage
    │   ├── notification.service.ts             # NEW - FCM sending service
    │   ├── notification.controller.ts          # NEW - Route handlers
    │   └── notification.routes.ts              # NEW - API endpoints
    ├── orders/
    │   └── order.service.ts                    # Updated - Send notifications
    ├── auth/
    │   └── auth.service.ts                     # Updated - New user notification
    └── delivery/
        └── delivery.service.ts                 # Updated - Delivery notifications
```

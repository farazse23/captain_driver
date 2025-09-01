# Driver App - Cloud Functions Setup and Deployment

## Prerequisites
1. Firebase project with Firestore and FCM enabled
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. Node.js 20 or higher

## Setup Steps

### 1. Configure Firebase Project
```bash
# Login to Firebase
firebase login

# Initialize project (if not already done)
firebase init

# Set your project ID in .firebaserc
# Replace "your-project-id-here" with your actual Firebase project ID
```

### 2. Update Project Configuration
Edit `.firebaserc` and replace `"your-project-id-here"` with your actual Firebase project ID.

### 3. Install Dependencies
```bash
cd functions
npm install
```

### 4. Deploy Cloud Functions
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:onNotificationCreated
```

### 5. Test the Setup
1. Create a test notification document in Firestore:
   ```
   Collection: drivers/{driverId}/notifications
   Document data:
   {
     "title": "Test Notification",
     "message": "jinda ho",
     "type": "admin_message",
     "priority": "normal",
     "senderId": "admin_001",
     "timestamp": [current timestamp],
     "read": false
   }
   ```
2. The cloud function should automatically trigger and send FCM notification
3. Check function logs: `firebase functions:log`

## Flutter App Changes Made

### 1. Notification Badge Fix
- The notification badge already works correctly in `dashboard_screen.dart`
- Badge count updates automatically when notifications are marked as read
- Uses `getUnreadNotificationCount()` stream from `NotificationService`

### 2. Notification Icon Updates
- Added truck icon (FontAwesome) for `admin_message` type notifications
- Updated `_getIcon()` method in `notifications_screen.dart`
- Android: Added custom notification icon drawable (`truck_icon.xml`)

### 3. FCM Configuration
- Added notification metadata to `AndroidManifest.xml`
- Added custom notification colors
- Enhanced logging in `MessagingService`

### 4. New Cloud Function
- `onNotificationCreated`: Triggers when documents are created in `drivers/{driverId}/notifications/`
- Automatically sends FCM notification with truck icon
- Handles token cleanup for invalid tokens

## Available Cloud Functions

1. **onNotificationCreated** - Triggers on new notification documents
2. **sendNotificationToAllDrivers** - Callable function to notify all drivers
3. **sendNotificationToDriver** - Callable function to notify specific driver
4. **onAdminAnnouncement** - Triggers on admin announcement documents
5. **cleanupInvalidTokens** - Scheduled function to clean invalid FCM tokens

## Notification Data Structure

Expected notification document format:
```json
{
  "title": "Admin Notification",
  "message": "jinda ho",
  "type": "admin_message",
  "priority": "normal",
  "senderId": "admin_001",
  "timestamp": "[Firebase Timestamp]",
  "read": false
}
```

## Troubleshooting

1. **Functions not deploying**: Check Node.js version and Firebase CLI version
2. **Notifications not sending**: Verify FCM tokens are saved in Firestore
3. **Badge not updating**: Ensure notifications are being marked as read when tapped
4. **Custom icon not showing**: Check Android drawable resources and manifest configuration

## Monitoring

- Function logs: `firebase functions:log`
- FCM delivery reports in Firebase Console
- Firestore security rules may need adjustment for production

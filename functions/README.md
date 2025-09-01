# Cloud Functions for Driver App

This directory contains Firebase Cloud Functions for handling push notifications and admin announcements.

## Setup Instructions

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase Functions** (if not already done):
   ```bash
   firebase init functions
   ```

4. **Install dependencies**:
   ```bash
   cd functions
   npm install
   ```

5. **Deploy functions**:
   ```bash
   firebase deploy --only functions
   ```

## Available Functions

### 1. `sendNotificationToAllDrivers`
- **Type**: Callable Function
- **Purpose**: Send notification to all registered drivers
- **Usage**: Call from admin panel or other authenticated client
- **Parameters**:
  - `title` (string): Notification title
  - `message` (string): Notification message
  - `type` (string, optional): Notification type (default: 'admin_announcement')
  - `priority` (string, optional): Priority level (default: 'normal')

### 2. `sendNotificationToDriver`
- **Type**: Callable Function
- **Purpose**: Send notification to a specific driver
- **Usage**: Call from admin panel or other authenticated client
- **Parameters**:
  - `driverId` (string): Driver document ID
  - `title` (string): Notification title
  - `message` (string): Notification message
  - `type` (string, optional): Notification type (default: 'admin_announcement')
  - `priority` (string, optional): Priority level (default: 'normal')

### 3. `onAdminAnnouncement`
- **Type**: Firestore Trigger
- **Purpose**: Automatically send notifications when admin creates an announcement
- **Trigger**: Creates document in `admin_announcements` collection
- **Usage**: Admin creates document in `admin_announcements` collection

### 4. `cleanupInvalidTokens`
- **Type**: Scheduled Function
- **Purpose**: Clean up invalid FCM tokens
- **Schedule**: Runs every 24 hours
- **Usage**: Automatic cleanup

## How to Use

### From Admin Panel (Callable Functions)
```javascript
// Example: Send notification to all drivers
const sendToAllDrivers = firebase.functions().httpsCallable('sendNotificationToAllDrivers');
sendToAllDrivers({
  title: 'Important Update',
  message: 'Please update your app to the latest version',
  type: 'admin_announcement',
  priority: 'urgent'
});

// Example: Send notification to specific driver
const sendToDriver = firebase.functions().httpsCallable('sendNotificationToDriver');
sendToDriver({
  driverId: 'drv_1234567890',
  title: 'Trip Assignment',
  message: 'You have been assigned a new trip',
  type: 'trip_assignment',
  priority: 'normal'
});
```

### From Admin Panel (Firestore Trigger)
```javascript
// Create announcement document to trigger notification
firebase.firestore().collection('admin_announcements').add({
  title: 'System Maintenance',
  message: 'System will be down for maintenance from 2-4 AM',
  type: 'admin_announcement',
  priority: 'normal',
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

## Security Rules

Make sure your Firestore security rules allow:
- Read/write access to `drivers/{driverId}/notifications`
- Read/write access to `drivers/{driverId}/tokens`
- Read access to `drivers` collection
- Write access to `admin_announcements` collection (for admin users only)

## Testing

1. **Local testing**:
   ```bash
   firebase emulators:start --only functions
   ```

2. **Test with Firebase Console**:
   - Go to Firebase Console > Functions
   - Click on a function
   - Use the "Test function" feature

## Monitoring

- Check function logs in Firebase Console > Functions > Logs
- Monitor function performance and errors
- Set up alerts for function failures

## Cost Considerations

- Functions are charged based on execution time and memory usage
- FCM messages are free for the first 1 million messages per month
- Consider implementing rate limiting for high-volume scenarios

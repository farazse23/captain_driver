# Captain Truck Driver App 🚚

A comprehensive Flutter application for truck drivers to manage dispatch assignments, track trips, and communicate with dispatchers in real-time.

## 🌟 Features

### 📱 Core Functionality
- **User Authentication** - Secure login with Firebase Auth
- **Dashboard** - Overview of assignments, active trips, and notifications
- **Trip Management** - Assigned, active, and completed trip screens
- **Real-time Updates** - Live trip status updates with image uploads
- **Push Notifications** - Instant notifications for new assignments and updates
- **Profile Management** - Driver profile and settings

### 🎨 UI/UX Features
- **Responsive Design** - Optimized for all screen sizes
- **Material Design** - Modern, intuitive interface
- **Custom Animations** - Smooth transitions and micro-interactions
- **Dark/Light Theme Support** - Adaptive color schemes
- **Offline Capabilities** - Core features work without internet

### 🔧 Technical Features
- **Firebase Integration** - Authentication, Firestore, Storage, Messaging
- **Image Upload** - Photo documentation for trip updates
- **Real-time Database** - Live sync of dispatch data
- **Push Notifications** - FCM for instant updates
- **State Management** - Efficient app state handling
- **Error Handling** - Comprehensive error management

## 🏗️ Architecture

### 📁 Project Structure
```
lib/
├── constants/          # App-wide constants and colors
├── models/            # Data models and entities
├── screens/           # UI screens and pages
│   ├── active_trip/
│   ├── assigned_trip/
│   ├── completed_trip/
│   ├── dashboard/
│   ├── login/
│   └── ...
├── services/          # Business logic and API calls
├── widgets/           # Reusable UI components
└── main.dart         # App entry point
```

### 🔥 Firebase Services
- **Authentication** - User login/logout
- **Firestore** - Real-time database for dispatches and trip data
- **Storage** - Image uploads for trip documentation
- **Cloud Messaging** - Push notifications
- **Cloud Functions** - Server-side logic

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK (latest)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/farazse23/captain_driver.git
   cd captain_driver
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` file to `android/app/`
   - Add your `GoogleService-Info.plist` file to `ios/Runner/`
   - Update Firebase configuration in the app

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Screenshots

### Dashboard
- Overview of assignments and active trips
- Quick access to key features
- Real-time notification display

### Trip Management
- **Assigned Trips** - View new assignments
- **Active Trip** - GPS tracking and real-time updates
- **Completed Trips** - Trip history and documentation

### Trip Updates
- Photo documentation
- Status updates
- Real-time communication

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Set up Firestore database
4. Configure Storage rules
5. Set up Cloud Messaging

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Manual Testing
- Test on different screen sizes
- Verify offline functionality
- Test push notifications
- Validate image uploads

## 📚 Key Dependencies

- **Firebase** - Backend services
- **Provider** - State management
- **HTTP** - API communications
- **Image Picker** - Photo capture
- **Geolocator** - GPS tracking
- **Flutter Local Notifications** - Local notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: Captain Truck Team
- **UI/UX**: Mobile Design Team
- **Backend**: Firebase Integration Team

## 📞 Support

For support, email support@captaintruck.com or create an issue in the repository.

## 🔄 Updates

### Recent Changes
- ✅ Implemented responsive design for all screens
- ✅ Fixed image display issues in trip updates
- ✅ Added comprehensive notification system
- ✅ Improved card layouts for better mobile experience
- ✅ Enhanced error handling and user feedback

### Roadmap
- 🔄 Offline mode improvements
- 🔄 Advanced analytics dashboard
- 🔄 Multi-language support
- 🔄 Voice commands integration
- 🔄 Advanced route optimization

---

Built with ❤️ using Flutter & Firebase

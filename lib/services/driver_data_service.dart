import '../models/driver.dart';
import 'auth_service.dart';

class DriverDataService {
  static final DriverDataService _instance = DriverDataService._internal();
  factory DriverDataService() => _instance;
  DriverDataService._internal();

  Driver? _cachedDriver;
  String? _cachedDriverId;
  bool _isLoading = false;

  Driver? get cachedDriver => _cachedDriver;
  bool get isLoading => _isLoading;

  // Get cached driver data without network call
  Driver? getCachedDriverData() {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user != null && _cachedDriver != null && _cachedDriverId == user.uid) {
      return _cachedDriver;
    }
    return null;
  }

  Future<Driver?> getDriverData({bool forceRefresh = false}) async {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) return null;

    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedDriver != null && _cachedDriverId == user.uid) {
      print('Returning cached driver data');
      return _cachedDriver;
    }

    // Prevent multiple simultaneous requests
    if (_isLoading) {
      print('Already loading driver data, waiting...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedDriver;
    }

    _isLoading = true;

    try {
      print('Loading fresh driver data for: ${user.email}');
      final driverData = await authService.getDriverDetails(user.email!);

      if (driverData != null) {
        _cachedDriver = Driver.fromMap(driverData, user.uid);
        _cachedDriverId = user.uid;
        print('Driver data cached successfully');
        print('Profile image length: ${_cachedDriver?.profileImage.length}');
        print('License image length: ${_cachedDriver?.licenseImage.length}');
      } else {
        print('No driver data found');
      }
    } catch (e) {
      print('Error loading driver data: $e');
    } finally {
      _isLoading = false;
    }

    return _cachedDriver;
  }

  void clearCache() {
    _cachedDriver = null;
    _cachedDriverId = null;
  }

  void updateCachedDriver(Driver driver) {
    _cachedDriver = driver;
  }
}

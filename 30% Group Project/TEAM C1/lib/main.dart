import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E5F),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: baseScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Attendance System',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GPS + BLE Proximity Detection',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Student Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register as Student'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Instructor Access',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InstructorLoginScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.school),
                  label: const Text('Instructor Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InstructorRegisterScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Register as Instructor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_studentIdController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existing = await UserRepository.instance.getUserByStudentId(
        _studentIdController.text,
      );
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student ID already registered')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final user = User(
        studentId: _studentIdController.text,
        name: _nameController.text,
        password: _passwordController.text,
        role: 'Student',
        createdAt: DateTime.now(),
      );

      await UserRepository.instance.addUser(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _register,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.app_registration),
                  label: Text(_isLoading ? 'Registering...' : 'Register'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_studentIdController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Student ID and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await UserRepository.instance.getUserByStudentId(
        _studentIdController.text,
      );
      if (user == null || user.password != _passwordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Student ID or Password')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => StudentApp(user: user)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(title: const Text('Student Login'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.how_to_reg,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Student Login',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Logging in...' : 'Login'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Don\'t have an account? Register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorLoginScreen extends StatefulWidget {
  const InstructorLoginScreen({super.key});

  @override
  State<InstructorLoginScreen> createState() => _InstructorLoginScreenState();
}

class _InstructorLoginScreenState extends State<InstructorLoginScreen> {
  final _instructorIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _instructorIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_instructorIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ID and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await UserRepository.instance.getUserByStudentId(
        _instructorIdController.text,
      );
      if (user == null ||
          user.password != _passwordController.text ||
          user.role != 'Instructor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials or not an instructor'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => InstructorApp(user: user)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(title: const Text('Instructor Login'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Instructor Login',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _instructorIdController,
                decoration: InputDecoration(
                  labelText: 'Instructor ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Logging in...' : 'Login'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorRegisterScreen extends StatefulWidget {
  const InstructorRegisterScreen({super.key});

  @override
  State<InstructorRegisterScreen> createState() =>
      _InstructorRegisterScreenState();
}

class _InstructorRegisterScreenState extends State<InstructorRegisterScreen> {
  final _instructorIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureSecretKey = true;
  bool _isLoading = false;

  static const String _registrationKey = 'INSTRUCTOR2026';

  @override
  void dispose() {
    _instructorIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_instructorIdController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _secretKeyController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_secretKeyController.text != _registrationKey) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid registration key')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existing = await UserRepository.instance.getUserByStudentId(
        _instructorIdController.text,
      );
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instructor ID already registered')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final user = User(
        studentId: _instructorIdController.text,
        name: _nameController.text,
        password: _passwordController.text,
        role: 'Instructor',
        createdAt: DateTime.now(),
      );

      await UserRepository.instance.addUser(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InstructorLoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Instructor Registration'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _instructorIdController,
                decoration: InputDecoration(
                  labelText: 'Instructor ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _secretKeyController,
                obscureText: _obscureSecretKey,
                decoration: InputDecoration(
                  labelText: 'Registration Key',
                  hintText: 'Contact admin for key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSecretKey
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureSecretKey = !_obscureSecretKey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Key: INSTRUCTOR2026',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _register,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.app_registration),
                  label: Text(_isLoading ? 'Registering...' : 'Register'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentApp extends StatefulWidget {
  final User user;
  const StudentApp({required this.user, super.key});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  static const double _requiredAccuracyMeters = 25;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Position? _currentPosition;
  List<ScanResult> _scanResults = [];
  int? _selectedSessionId;
  BeaconSelectionConfig _beaconConfig = const BeaconSelectionConfig(
    value: null,
    mode: BeaconMatchMode.mac,
  );

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startLocationStream();
    _startBleScanning();
    _loadBeaconConfig();
  }

  Future<void> _loadBeaconConfig() async {
    final config = await BeaconConfig.getConfiguredBeaconConfig();
    if (mounted) {
      setState(() => _beaconConfig = config);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final locStatus = await Permission.location.request();
      print('Location permission: $locStatus');
      final btStatus = await Permission.bluetooth.request();
      print('Bluetooth permission: $btStatus');
      final scanStatus = await Permission.bluetoothScan.request();
      print('Bluetooth scan permission: $scanStatus');
      final connectStatus = await Permission.bluetoothConnect.request();
      print('Bluetooth connect permission: $connectStatus');
      final nearbyStatus = await Permission.nearbyWifiDevices.request();
      print('Nearby WiFi devices permission: $nearbyStatus');
    } catch (e) {
      print('Permission error: $e');
    }
  }

  void _startLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) => setState(() => _currentPosition = pos));
  }

  void _startBleScanning() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    _scanSubscription ??= FlutterBluePlus.scanResults.listen(
      (results) => setState(() => _scanResults = results),
    );
  }

  String _getProximity(int rssi) {
    if (rssi >= -60) return 'Immediate';
    if (rssi >= -80) return 'Near';
    return 'Far';
  }

  Future<void> _checkIn() async {
    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a session')));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Waiting for GPS...')));
      return;
    }
    if (_currentPosition!.accuracy > _requiredAccuracyMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Waiting for better GPS accuracy (±${_requiredAccuracyMeters.toStringAsFixed(0)} m)...',
          ),
        ),
      );
      return;
    }

    final config = await BeaconConfig.getConfiguredBeaconConfig();
    ScanResult? beacon;

    if (config.value != null) {
      final target = _normalizeBeaconValue(config.value!);
      if (config.mode == BeaconMatchMode.mac || config.mode == BeaconMatchMode.both) {
        for (final result in _scanResults) {
          if (_normalizeBeaconValue(result.device.remoteId.str) == target) {
            beacon = result;
            break;
          }
        }
      }
      if (beacon == null && (config.mode == BeaconMatchMode.name || config.mode == BeaconMatchMode.both)) {
        for (final result in _scanResults) {
          if (_normalizeBeaconValue(result.device.name) == target) {
            beacon = result;
            break;
          }
        }
      }
    }

    if (config.value != null && beacon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configured beacon not detected')),
      );
      return;
    }

    beacon ??= _scanResults
          .where((r) => r.rssi >= -80)
          .fold<ScanResult?>(
            null,
            (prev, curr) => (curr.rssi > (prev?.rssi ?? -100)) ? curr : prev,
          );

    if (beacon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No beacon nearby')));
      return;
    }

    final record = AttendanceRecord(
      timestamp: DateTime.now(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      studentId: widget.user.studentId,
      studentName: widget.user.name,
      beaconId: beacon.device.remoteId.str,
      beaconName: beacon.device.name,
      proximity: _getProximity(beacon.rssi),
      validated: beacon.rssi >= -80,
      sessionId: _selectedSessionId,
    );

    await AttendanceRepository.instance.addRecord(record);
    if (mounted) {
      final isConfigured = config.value != null && _matchesConfiguredBeacon(beacon, config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in successful!${isConfigured ? ' (auto-selected)' : ''} (${_getProximity(beacon.rssi)})',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check In - ${widget.user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latitude',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _currentPosition?.latitude.toStringAsFixed(6) ??
                          'Waiting...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Longitude',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _currentPosition?.longitude.toStringAsFixed(6) ??
                          'Waiting...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accuracy',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _currentPosition == null
                          ? 'Waiting...'
                          : '±${_currentPosition!.accuracy.toStringAsFixed(0)} m',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Beacons (${_scanResults.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    OutlinedButton.icon(
                      onPressed: _startBleScanning,
                      icon: const Icon(Icons.bluetooth_searching, size: 18),
                      label: const Text('Scan now'),
                    ),
                  ],
                ),
                const Divider(),
                () {
                  final hasConfig = _beaconConfig.value != null;
                  final filtered = hasConfig
                      ? _scanResults
                          .where(
                            (r) => _matchesConfiguredBeacon(r, _beaconConfig),
                          )
                          .toList()
                      : _scanResults;
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No beacons detected'),
                    );
                  }
                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                            final isPreferred = _beaconConfig.value != null &&
                                _matchesConfiguredBeacon(result, _beaconConfig);
                            final borderColor = isPreferred
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!;
                            final backgroundColor = isPreferred
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08)
                                : Colors.white;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  final name = result.device.name.trim();
                                  final value = name.isNotEmpty
                                      ? name
                                      : result.device.remoteId.str;
                                  final mode = name.isNotEmpty
                                      ? BeaconMatchMode.name
                                      : BeaconMatchMode.mac;
                                  await BeaconConfig.setConfiguredBeaconConfig(
                                    value,
                                    mode,
                                  );
                                  await _loadBeaconConfig();
                                  if (mounted) {
                                    final modeLabel =
                                        mode == BeaconMatchMode.name
                                            ? 'name'
                                            : 'MAC';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Preferred beacon saved ($modeLabel)',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          result.device.name.isEmpty
                                              ? result.device.remoteId.str
                                              : result.device.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _StatusBadge(
                                        _getProximity(result.rssi),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'RSSI: ${result.rssi}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                    ),
                  );
                }(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Session>>(
            future: SessionRepository.instance.getSessions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final sessions = snapshot.data ?? [];
              return DropdownMenu<int>(
                label: const Text('Select Session'),
                onSelected: (val) => setState(() => _selectedSessionId = val),
                dropdownMenuEntries: [
                  const DropdownMenuEntry(
                    value: -1,
                    label: 'Choose a session...',
                  ),
                  ...sessions.map(
                    (s) => DropdownMenuEntry(
                      value: s.id!,
                      label: '${s.name} (${s.code})',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _checkIn,
            icon: const Icon(Icons.check_circle),
            label: const Text('Check In Now'),
          ),
        ],
      ),
    );
  }
}

class InstructorApp extends StatefulWidget {
  final User user;
  const InstructorApp({required this.user, super.key});

  @override
  State<InstructorApp> createState() => _InstructorAppState();
}

class _InstructorAppState extends State<InstructorApp> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardPage(),
      const LocationBeaconPage(),
      const AttendancePage(),
      const SessionsPage(),
      const ReportsPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instructor: ${widget.user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          NavigationDestination(icon: Icon(Icons.list), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AttendanceRepository.instance.updates,
      builder: (context, _, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadDashboardData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? {};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _DashboardCard(
                  title: 'Total Check-ins',
                  value: '${data['total'] ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  title: 'This Month',
                  value: '${data['thisMonth'] ?? 0}',
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  title: 'Validated',
                  value: '${data['validated'] ?? 0}',
                  icon: Icons.verified,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  title: 'Immediate %',
                  value: '${data['immediate'] ?? 0}%',
                  icon: Icons.signal_cellular_alt,
                  color: Colors.teal,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class LocationBeaconPage extends StatefulWidget {
  const LocationBeaconPage({super.key});

  @override
  State<LocationBeaconPage> createState() => _LocationBeaconPageState();
}

class _LocationBeaconPageState extends State<LocationBeaconPage> {
  static const double _requiredAccuracyMeters = 25;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Position? _currentPosition;
  List<ScanResult> _scanResults = [];
  int? _selectedSessionId;
  BeaconSelectionConfig _beaconConfig = const BeaconSelectionConfig(
    value: null,
    mode: BeaconMatchMode.mac,
  );

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startLocationStream();
    _startBleScanning();
    _loadBeaconConfig();
  }

  Future<void> _loadBeaconConfig() async {
    final config = await BeaconConfig.getConfiguredBeaconConfig();
    if (mounted) {
      setState(() => _beaconConfig = config);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final locStatus = await Permission.location.request();
      print('Location permission: $locStatus');
      final btStatus = await Permission.bluetooth.request();
      print('Bluetooth permission: $btStatus');
      final scanStatus = await Permission.bluetoothScan.request();
      print('Bluetooth scan permission: $scanStatus');
      final connectStatus = await Permission.bluetoothConnect.request();
      print('Bluetooth connect permission: $connectStatus');
      final nearbyStatus = await Permission.nearbyWifiDevices.request();
      print('Nearby WiFi devices permission: $nearbyStatus');
    } catch (e) {
      print('Permission error: $e');
    }
  }

  void _startLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) => setState(() => _currentPosition = pos));
  }

  void _startBleScanning() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    _scanSubscription ??= FlutterBluePlus.scanResults.listen(
      (results) => setState(() => _scanResults = results),
    );
  }

  String _getProximity(int rssi) {
    if (rssi >= -60) return 'Immediate';
    if (rssi >= -80) return 'Near';
    return 'Far';
  }

  Future<void> _recordCheckIn() async {
    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a session')));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Waiting for GPS...')));
      return;
    }
    if (_currentPosition!.accuracy > _requiredAccuracyMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Waiting for better GPS accuracy (±${_requiredAccuracyMeters.toStringAsFixed(0)} m)...',
          ),
        ),
      );
      return;
    }

    final config = await BeaconConfig.getConfiguredBeaconConfig();
    ScanResult? beacon;

    if (config.value != null) {
      final target = _normalizeBeaconValue(config.value!);
      if (config.mode == BeaconMatchMode.mac || config.mode == BeaconMatchMode.both) {
        for (final result in _scanResults) {
          if (_normalizeBeaconValue(result.device.remoteId.str) == target) {
            beacon = result;
            break;
          }
        }
      }
      if (beacon == null && (config.mode == BeaconMatchMode.name || config.mode == BeaconMatchMode.both)) {
        for (final result in _scanResults) {
          if (_normalizeBeaconValue(result.device.name) == target) {
            beacon = result;
            break;
          }
        }
      }
    }

    if (config.value != null && beacon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configured beacon not detected')),
      );
      return;
    }

    beacon ??= _scanResults.isEmpty ? null : _scanResults.first;

    final record = AttendanceRecord(
      timestamp: DateTime.now(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      studentId: null,
      studentName: null,
      beaconId: beacon?.device.remoteId.str ?? 'manual',
      beaconName: beacon?.device.name ?? 'Manual',
      proximity: beacon != null ? _getProximity(beacon.rssi) : 'Unknown',
      validated: beacon != null && beacon.rssi >= -80,
      sessionId: _selectedSessionId,
    );
    await AttendanceRepository.instance.addRecord(record);
    if (mounted) {
      final isConfigured = beacon != null && config.value != null && _matchesConfiguredBeacon(beacon, config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in recorded${isConfigured ? ' (auto-selected)' : ''}',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GPS Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latitude',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _currentPosition?.latitude.toStringAsFixed(6) ??
                        'Acquiring...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Longitude',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _currentPosition?.longitude.toStringAsFixed(6) ??
                        'Acquiring...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Accuracy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _currentPosition == null
                        ? 'Acquiring...'
                        : '±${_currentPosition!.accuracy.toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Beacons (${_scanResults.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  OutlinedButton.icon(
                    onPressed: _startBleScanning,
                    icon: const Icon(Icons.bluetooth_searching, size: 18),
                    label: const Text('Scan now'),
                  ),
                ],
              ),
              const Divider(),
              _scanResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No beacons'),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _scanResults.length,
                        itemBuilder: (context, index) {
                          final r = _scanResults[index];
                          final isPreferred = _beaconConfig.value != null &&
                              _matchesConfiguredBeacon(r, _beaconConfig);
                          final borderColor = isPreferred
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300]!;
                          final backgroundColor = isPreferred
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08)
                              : Colors.white;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap: () async {
                                final name = r.device.name.trim();
                                final value = name.isNotEmpty
                                    ? name
                                    : r.device.remoteId.str;
                                final mode = name.isNotEmpty
                                    ? BeaconMatchMode.name
                                    : BeaconMatchMode.mac;
                                await BeaconConfig.setConfiguredBeaconConfig(
                                  value,
                                  mode,
                                );
                                await _loadBeaconConfig();
                                if (mounted) {
                                  final modeLabel =
                                      mode == BeaconMatchMode.name
                                          ? 'name'
                                          : 'MAC';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Preferred beacon saved ($modeLabel)',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.device.name.isEmpty
                                            ? r.device.remoteId.str
                                            : r.device.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _StatusBadge(_getProximity(r.rssi)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RSSI: ${r.rssi}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Session>>(
          future: SessionRepository.instance.getSessions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return DropdownMenu<int>(
              label: const Text('Session'),
              onSelected: (val) => setState(() => _selectedSessionId = val),
              dropdownMenuEntries: (snapshot.data ?? [])
                  .map((s) => DropdownMenuEntry(value: s.id!, label: s.name))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _recordCheckIn,
          icon: const Icon(Icons.add_circle),
          label: const Text('Record Check-in'),
        ),
      ],
    );
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AttendanceRepository.instance.updates,
      builder: (context, _, _) {
        return FutureBuilder<List<AttendanceRecord>>(
          future: AttendanceRepository.instance.getRecords(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${records.length} Records',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          AttendanceRepository.instance.exportToCsv(records),
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        title: Text(r.studentName ?? 'Unknown Student'),
                        subtitle: Text(
                          'ID: ${r.studentId ?? 'N/A'}\nBeacon: ${r.beaconName}\n${r.timestamp}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () {
                                if (r.id != null) {
                                  AttendanceRepository.instance.deleteRecord(
                                    r.id!,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SessionRepository.instance.updates,
      builder: (context, _, _) {
        return FutureBuilder<List<Session>>(
          future: SessionRepository.instance.getSessions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final sessions = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sessions.length} Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.icon(
                      onPressed: _showAddSession,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sessions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                s.code,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              if (s.id != null) {
                                SessionRepository.instance.deleteSession(s.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSession() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await SessionRepository.instance.addSession(
                Session(
                  name: nameCtrl.text,
                  code: codeCtrl.text,
                  createdAt: DateTime.now(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AttendanceRepository.instance.updates,
      builder: (context, _, _) {
        return FutureBuilder<List<AttendanceRecord>>(
          future: AttendanceRepository.instance.getRecords(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            final byProx = <String, int>{'Immediate': 0, 'Near': 0, 'Far': 0};
            for (final r in records) {
              byProx[r.proximity] = (byProx[r.proximity] ?? 0) + 1;
            }
            final byMonth = <String, int>{};
            for (final r in records) {
              final key =
                  '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}';
              byMonth[key] = (byMonth[key] ?? 0) + 1;
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By Proximity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      ...byProx.entries.map((e) {
                        final pct = records.isEmpty
                            ? 0
                            : ((e.value / records.length) * 100)
                                  .toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(e.key), Text('${e.value} ($pct%)')],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By Month',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      ...byMonth.entries.map((e) {
                        final pct = records.isEmpty
                            ? 0
                            : ((e.value / records.length) * 100)
                                  .toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(e.key), Text('${e.value} ($pct%)')],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _beaconController;
  String? _savedBeaconId;
  BeaconMatchMode _matchMode = BeaconMatchMode.mac;

  @override
  void initState() {
    super.initState();
    _beaconController = TextEditingController();
    _loadBeaconId();
  }

  Future<void> _loadBeaconId() async {
    final config = await BeaconConfig.getConfiguredBeaconConfig();
    setState(() {
      _savedBeaconId = config.value;
      _matchMode = config.mode;
      _beaconController.text = config.value ?? '';
    });
  }

  Future<void> _saveBeaconId() async {
    final id = _beaconController.text.trim();
    await BeaconConfig.setConfiguredBeaconConfig(
      id.isEmpty ? null : id,
      _matchMode,
    );
    setState(() => _savedBeaconId = id.isEmpty ? null : id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            id.isEmpty ? 'Beacon value cleared' : 'Beacon value saved: $id',
          ),
        ),
      );
    }
  }

  String _matchModeLabel(BeaconMatchMode mode) {
    switch (mode) {
      case BeaconMatchMode.mac:
        return 'MAC address';
      case BeaconMatchMode.name:
        return 'Device name';
      case BeaconMatchMode.both:
        return 'MAC or name';
    }
  }

  @override
  void dispose() {
    _beaconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beacon Configuration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                'Enter the beacon ID or name to auto-select it when detected:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              DropdownMenu<BeaconMatchMode>(
                label: const Text('Match by'),
                initialSelection: _matchMode,
                onSelected: (val) {
                  if (val != null) {
                    setState(() => _matchMode = val);
                  }
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: BeaconMatchMode.mac,
                    label: 'MAC address',
                  ),
                  DropdownMenuEntry(
                    value: BeaconMatchMode.name,
                    label: 'Device name',
                  ),
                  DropdownMenuEntry(
                    value: BeaconMatchMode.both,
                    label: 'MAC or name',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beaconController,
                decoration: InputDecoration(
                  labelText: 'Beacon ID or Name',
                  hintText: 'e.g., AA:BB:CC:DD:EE:FF or Beacon-01',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.router),
                ),
              ),
              const SizedBox(height: 12),
              if (_savedBeaconId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saved (${_matchModeLabel(_matchMode)}): $_savedBeaconId',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _saveBeaconId,
                child: const Text('Save Beacon'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Role', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    'Instructor',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                'Attendance System v1.0',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'GPS + BLE attendance tracking',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class User {
  int? id;
  String studentId;
  String name;
  String password;
  String role;
  DateTime createdAt;

  User({
    this.id,
    required this.studentId,
    required this.name,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'name': name,
    'password': password,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };

  static User fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    studentId: map['student_id'] ?? '',
    name: map['name'] ?? '',
    password: map['password'] ?? '',
    role: map['role'] ?? 'Student',
    createdAt: DateTime.parse(
      map['created_at'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

class AttendanceRecord {
  int? id;
  DateTime timestamp;
  double latitude;
  double longitude;
  String? studentId;
  String? studentName;
  String beaconId;
  String beaconName;
  String proximity;
  bool validated;
  int? sessionId;

  AttendanceRecord({
    this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.studentId,
    this.studentName,
    required this.beaconId,
    required this.beaconName,
    required this.proximity,
    required this.validated,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'student_id': studentId,
    'student_name': studentName,
    'beacon_id': beaconId,
    'beacon_name': beaconName,
    'proximity': proximity,
    'validated': validated ? 1 : 0,
    'session_id': sessionId,
  };

  static AttendanceRecord fromMap(Map<String, dynamic> map) => AttendanceRecord(
    id: map['id'],
    timestamp: DateTime.parse(map['timestamp']),
    latitude: _parseDouble(map['latitude']),
    longitude: _parseDouble(map['longitude']),
    studentId: map['student_id'],
    studentName: map['student_name'],
    beaconId: map['beacon_id'] ?? '',
    beaconName: map['beacon_name'] ?? '',
    proximity: map['proximity'] ?? '',
    validated: map['validated'] == 1,
    sessionId: map['session_id'],
  );
}

class Session {
  int? id;
  String name;
  String code;
  DateTime createdAt;

  Session({
    this.id,
    required this.name,
    required this.code,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'created_at': createdAt.toIso8601String(),
  };

  static Session fromMap(Map<String, dynamic> map) => Session(
    id: map['id'],
    name: map['name'] ?? '',
    code: map['code'] ?? '',
    createdAt: DateTime.parse(
      map['created_at'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

class UserRepository {
  static final UserRepository _instance = UserRepository._();
  factory UserRepository() => _instance;
  UserRepository._();

  static UserRepository get instance => _instance;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = '${(await getDatabasesPath())}/users.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL)''');
      },
    );
    return _db!;
  }

  Future<void> addUser(User user) async {
    final db = await _database;
    await db.insert('users', user.toMap());
  }

  Future<User?> getUserByStudentId(String studentId) async {
    final db = await _database;
    final maps = await db.query(
      'users',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await _database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<void> deleteUser(int id) async {
    final db = await _database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

class AttendanceRepository {
  static final AttendanceRepository _instance = AttendanceRepository._();
  factory AttendanceRepository() => _instance;
  AttendanceRepository._();

  static AttendanceRepository get instance => _instance;

  Database? _db;
  final updates = ValueNotifier<int>(0);

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = '${(await getDatabasesPath())}/attendance.db';
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        student_id TEXT,
        student_name TEXT,
        beacon_id TEXT NOT NULL,
        beacon_name TEXT NOT NULL,
        proximity TEXT NOT NULL,
        validated INTEGER NOT NULL,
        session_id INTEGER)''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE attendance ADD COLUMN student_id TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE attendance ADD COLUMN student_name TEXT');
          } catch (_) {}
        }
      },
    );
    return _db!;
  }

  Future<void> addRecord(AttendanceRecord record) async {
    final db = await _database;
    await db.insert('attendance', record.toMap());
    updates.value++;
  }

  Future<void> deleteRecord(int id) async {
    final db = await _database;
    await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
    updates.value++;
  }

  Future<List<AttendanceRecord>> getRecords() async {
    final db = await _database;
    final maps = await db.query('attendance', orderBy: 'timestamp DESC');
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<void> exportToCsv(List<AttendanceRecord> records) async {
    final dir = await getApplicationDocumentsDirectory();
    final csv = StringBuffer(
      'Timestamp,StudentId,StudentName,Latitude,Longitude,Beacon,Proximity,Validated,Session\n',
    );
    for (final r in records) {
      csv.writeln(
        '${r.timestamp},${r.studentId ?? ""},${r.studentName ?? ""},${r.latitude},${r.longitude},${r.beaconName},${r.proximity},${r.validated},${r.sessionId ?? ""}',
      );
    }
    final file = File(
      '${dir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv.toString());
  }
}

class SessionRepository {
  static final SessionRepository _instance = SessionRepository._();
  factory SessionRepository() => _instance;
  SessionRepository._();

  static SessionRepository get instance => _instance;

  Database? _db;
  final updates = ValueNotifier<int>(0);

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = '${(await getDatabasesPath())}/sessions.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        created_at TEXT NOT NULL)''');
      },
    );
    return _db!;
  }

  Future<void> addSession(Session session) async {
    final db = await _database;
    await db.insert('sessions', session.toMap());
    updates.value++;
  }

  Future<void> deleteSession(int id) async {
    final db = await _database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    updates.value++;
  }

  Future<List<Session>> getSessions() async {
    final db = await _database;
    final maps = await db.query('sessions', orderBy: 'created_at DESC');
    return maps.map((m) => Session.fromMap(m)).toList();
  }
}

class _DashboardCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge(this.label);

  @override
  Widget build(BuildContext context) {
    final color = label == 'Immediate'
        ? Colors.green
        : label == 'Near'
        ? Colors.orange
        : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum BeaconMatchMode { mac, name, both }

class BeaconSelectionConfig {
  final String? value;
  final BeaconMatchMode mode;

  const BeaconSelectionConfig({required this.value, required this.mode});
}

class BeaconConfig {
  static const String _configFileName = 'beacon_config.txt';

  static Future<BeaconSelectionConfig> getConfiguredBeaconConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_configFileName');
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isEmpty) {
          return const BeaconSelectionConfig(
            value: null,
            mode: BeaconMatchMode.mac,
          );
        }
        final separatorIndex = content.indexOf('|');
        if (separatorIndex == -1) {
          return BeaconSelectionConfig(
            value: content,
            mode: BeaconMatchMode.mac,
          );
        }
        final rawMode = content.substring(0, separatorIndex).trim();
        final rawValue = content.substring(separatorIndex + 1).trim();
        return BeaconSelectionConfig(
          value: rawValue.isEmpty ? null : rawValue,
          mode: _parseMode(rawMode),
        );
      }
    } catch (e) {
      print('Error reading beacon config: $e');
    }
    return const BeaconSelectionConfig(value: null, mode: BeaconMatchMode.mac);
  }

  static Future<void> setConfiguredBeaconConfig(
    String? value,
    BeaconMatchMode mode,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_configFileName');
      if (value == null || value.isEmpty) {
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        await file.writeAsString('${mode.name}|$value');
      }
    } catch (e) {
      print('Error writing beacon config: $e');
    }
  }

  static BeaconMatchMode _parseMode(String rawMode) {
    switch (rawMode.toLowerCase()) {
      case 'name':
        return BeaconMatchMode.name;
      case 'both':
        return BeaconMatchMode.both;
      case 'mac':
      default:
        return BeaconMatchMode.mac;
    }
  }
}

double _parseDouble(dynamic v) => (v is double)
    ? v
    : (v is int)
    ? v.toDouble()
    : double.tryParse(v.toString()) ?? 0.0;

String _normalizeBeaconValue(String value) => value.trim().toLowerCase();

bool _matchesConfiguredBeacon(
  ScanResult result,
  BeaconSelectionConfig config,
) {
  final target = _normalizeBeaconValue(config.value ?? '');
  if (target.isEmpty) return false;

  final mac = _normalizeBeaconValue(result.device.remoteId.str);
  final name = _normalizeBeaconValue(result.device.name);

  switch (config.mode) {
    case BeaconMatchMode.mac:
      return mac == target;
    case BeaconMatchMode.name:
      return name == target;
    case BeaconMatchMode.both:
      return mac == target || name == target;
  }
}

Future<Map<String, dynamic>> _loadDashboardData() async {
  final records = await AttendanceRepository.instance.getRecords();
  final now = DateTime.now();
  final thisMonth = records
      .where(
        (r) => r.timestamp.year == now.year && r.timestamp.month == now.month,
      )
      .length;
  final validated = records.where((r) => r.validated).length;
  final immediate = records.where((r) => r.proximity == 'Immediate').length;
  final immediatePct = records.isEmpty
      ? 0
      : ((immediate / records.length) * 100).toInt();
  return {
    'total': records.length,
    'thisMonth': thisMonth,
    'validated': validated,
    'immediate': immediatePct,
  };
}


import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  NativeEventEmitter,
  NativeModules,
  Platform,
  PermissionsAndroid,
  TouchableOpacity,
  ListRenderItem,
  Alert,
  StatusBar,
  TextInput,
  Modal,
  KeyboardAvoidingView,
  ScrollView,
} from 'react-native';
import { SafeAreaView, SafeAreaProvider } from 'react-native-safe-area-context';
import BleManager from 'react-native-ble-manager';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { launchCamera } from 'react-native-image-picker';
import { Image } from 'react-native';

// Define types
interface Peripheral {
  id: string;
  name?: string;
  rssi: number;
}

interface AttendanceLog {
  id: string;
  userName: string;
  matrixNumber: string;
  photoUri: string;
  timestamp: string;
  type: 'CHECK_IN' | 'CHECK_OUT';
  beaconId: string;
  location: string;
}

interface UserProfile {
  fullName: string;
  matrixNumber: string;
}

const BleManagerModule = NativeModules.BleManager;

// Polyfill missing methods for NativeEventEmitter if necessary
if (BleManagerModule && Platform.OS === 'android') {
  if (typeof BleManagerModule.addListener !== 'function') {
    BleManagerModule.addListener = () => {};
  }
  if (typeof BleManagerModule.removeListeners !== 'function') {
    BleManagerModule.removeListeners = () => {};
  }
}

const bleManagerEmitter = new NativeEventEmitter(BleManagerModule);

const STORAGE_KEY = '@attendance_logs';
const USER_PROFILE_KEY = '@attendance_user_profile';
const BEACON_NAME = ''; // Empty string means "Detect everything" for debugging
const PROXIMITY_THRESHOLD = -55; // Approx 1 meter for typical BLE beacons

// Map Beacon ID to Location Name
const BEACON_LOCATIONS: { [key: string]: string } = {
  '41:86:67:91:5A:F6': 'Makmal Komputer 3 by Mr. Shahadan',
  'DEFAULT': 'Makmal Komputer 3 by Mr. Shahadan',
};

const App = () => {
  const [isScanning, setIsScanning] = useState(false);
  const [peripherals, setPeripherals] = useState<Map<string, Peripheral>>(new Map());
  const [attendanceLogs, setAttendanceLogs] = useState<AttendanceLog[]>([]);
  const [isCheckedIn, setIsCheckedIn] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [isProfileModalVisible, setIsProfileModalVisible] = useState(false);
  const [tempFullName, setTempFullName] = useState('');
  const [tempMatrixNumber, setTempMatrixNumber] = useState('');
  const [debugLogs, setDebugLogs] = useState<string[]>([]);
  const pollingTimer = React.useRef<NodeJS.Timeout | null>(null);

  const addLog = useCallback((msg: string) => {
    console.log(msg);
    setDebugLogs(prev => [msg.substring(0, 100), ...prev].slice(0, 10));
  }, []);

  // Load logs and user name on mount
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [storedLogs, storedProfile] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEY),
        AsyncStorage.getItem(USER_PROFILE_KEY),
      ]);

      if (storedProfile) {
        const profile = JSON.parse(storedProfile);
        setUserProfile(profile);
      } else {
        openProfileModal();
      }

      if (storedLogs) {
        const parsedLogs = JSON.parse(storedLogs);
        setAttendanceLogs(parsedLogs);
        if (parsedLogs.length > 0) {
          setIsCheckedIn(parsedLogs[0].type === 'CHECK_IN');
        }
      }
    } catch (e) {
      console.error('Failed to load data', e);
    }
  };

  const openProfileModal = () => {
    // We clear the temp values if we want the student to see the placeholders,
    // or keep them if we want to edit existing info.
    // Given the user wants clear indicators when empty, let's ensure placeholders are helpful.
    setTempFullName(userProfile?.fullName || '');
    setTempMatrixNumber(userProfile?.matrixNumber || '');
    setIsProfileModalVisible(true);
  };

  const saveProfile = async () => {
    if (tempFullName.trim().length < 2 || tempMatrixNumber.trim().length < 5) {
      Alert.alert('Invalid Details', 'Please enter your full name and valid matrix number.');
      return;
    }
    try {
      const profile = { fullName: tempFullName.trim(), matrixNumber: tempMatrixNumber.trim() };
      await AsyncStorage.setItem(USER_PROFILE_KEY, JSON.stringify(profile));
      setUserProfile(profile);
      setIsProfileModalVisible(false);
    } catch (e) {
      console.error('Failed to save profile', e);
    }
  };

  const saveLog = async (type: 'CHECK_IN' | 'CHECK_OUT', beaconId: string, photoUri: string) => {
    const location = BEACON_LOCATIONS[beaconId] || BEACON_LOCATIONS['DEFAULT'];
    const newLog: AttendanceLog = {
      id: Date.now().toString(),
      userName: userProfile?.fullName || 'Unknown',
      matrixNumber: userProfile?.matrixNumber || 'N/A',
      photoUri: photoUri,
      timestamp: new Date().toLocaleString(),
      type,
      beaconId,
      location,
    };
    
    const updatedLogs = [newLog, ...attendanceLogs];
    setAttendanceLogs(updatedLogs);
    setIsCheckedIn(type === 'CHECK_IN');
    
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedLogs));
    } catch (e) {
      console.error('Failed to save log', e);
    }
  };

  const handleDiscoverPeripheral = useCallback((peripheral: Peripheral) => {
    // Loosen name filter to catch variations or advertising names
    const name = peripheral.name || (peripheral as any).advertising?.localName || 'Unknown Device';
    
    addLog(`Found: ${peripheral.id} (${name})`);
    
    // For debugging: accept all devices if BEACON_NAME is empty or if it matches
    const searchName = name.toUpperCase();
    const targetName = (BEACON_NAME || '').toUpperCase();
    
    if (!targetName || searchName.includes(targetName)) {
      setPeripherals((prev) => {
        const next = new Map(prev);
        // Only update if RSSI changed or it's a new device to avoid unnecessary re-renders
        const existing = next.get(peripheral.id);
        if (!existing || existing.rssi !== peripheral.rssi) {
          next.set(peripheral.id, {
            ...peripheral,
            name: name
          });
          return next;
        }
        return prev;
      });
    }
  }, []);

  const handleStopScan = useCallback(() => {
    setIsScanning(false);
    if (pollingTimer.current) {
      clearInterval(pollingTimer.current);
      pollingTimer.current = null;
    }
    addLog('Scan Stopped');
  }, [addLog]);

  useEffect(() => {
    addLog('App init...');
    BleManager.start({ showAlert: false })
      .then(() => addLog('BLE Ready'))
      .catch(err => addLog(`BLE Error: ${err}`));

    const discoverListener = bleManagerEmitter.addListener(
      'BleManagerDiscoverPeripheral',
      (peripheral: Peripheral) => {
        // Log every single discovery event to see if anything is happening
        addLog(`Evt: ${peripheral.id.substring(0, 5)}...`);
        handleDiscoverPeripheral(peripheral);
      }
    );
    const stopListener = bleManagerEmitter.addListener(
      'BleManagerStopScan',
      () => {
        addLog('Scan Stopped');
        handleStopScan();
      }
    );

    return () => {
      addLog('Cleanup...');
      discoverListener.remove();
      stopListener.remove();
      if (pollingTimer.current) {
        clearInterval(pollingTimer.current);
      }
    };
  }, [handleDiscoverPeripheral, handleStopScan, addLog]);

  const requestPermissions = async () => {
    if (Platform.OS === 'android') {
      const apiLevel = parseInt(Platform.Version.toString(), 10);
      addLog(`Android API: ${apiLevel}`);

      if (apiLevel < 31) {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
        );
        addLog(`Loc Perm: ${granted}`);
        return granted === PermissionsAndroid.RESULTS.GRANTED;
      } else {
        const scanGranted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN);
        const connectGranted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT);
        const locationGranted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION);

        addLog(`Scan:${scanGranted} Loc:${locationGranted}`);

        return (
          scanGranted === PermissionsAndroid.RESULTS.GRANTED &&
          connectGranted === PermissionsAndroid.RESULTS.GRANTED &&
          locationGranted === PermissionsAndroid.RESULTS.GRANTED
        );
      }
    }
    return true;
  };

  const startScan = async () => {
    if (!isScanning) {
      const hasPermission = await requestPermissions();
      if (!hasPermission) {
        Alert.alert('Permissions Required', 'Bluetooth and Location permissions are needed to find beacons.');
        return;
      }

      // Ensure Bluetooth is actually ON before scanning
      try {
        addLog('Enabling BT...');
        await BleManager.enableBluetooth();
        // Check state after enabling
        const state = await BleManager.checkState();
        addLog(`BT State: ${state}`);
        if (state !== 'on') {
          Alert.alert('Bluetooth Required', 'Please turn on Bluetooth to scan for beacons.');
          return;
        }
      } catch (error) {
        addLog(`BT Error: ${error}`);
      }

      addLog('Starting scan...');
      BleManager.scan({
        serviceUUIDs: [],
        seconds: 0, // Scan indefinitely
        allowDuplicates: true, // Crucial for live RSSI updates
        scanMode: 2, // Low Latency
        matchMode: 1, // Aggressive
      }) 
        .then(() => {
          addLog('Scan Active (Live)');
          setIsScanning(true);
          
          // Start polling for updates every 1 second
          if (pollingTimer.current) clearInterval(pollingTimer.current);
          pollingTimer.current = setInterval(async () => {
            try {
              const discovered = await BleManager.getDiscoveredPeripherals();
              discovered.forEach(p => handleDiscoverPeripheral(p as any));
            } catch (e) {
              console.error('Polling error', e);
            }
          }, 1000);
        })
        .catch((err) => {
          addLog(`Scan Fail: ${err}`);
          setIsScanning(false);
        });
    }
  };

  const handleAttendance = (peripheral: Peripheral) => {
    if (peripheral.rssi < PROXIMITY_THRESHOLD) {
      Alert.alert('Too Far', 'Please move closer to the beacon to check in/out.');
      return;
    }

    const type = isCheckedIn ? 'CHECK_OUT' : 'CHECK_IN';
    
    Alert.alert(
      'Strict Attendance',
      `${type === 'CHECK_IN' ? 'Check In' : 'Check Out'} requires a selfie for verification.`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Take Selfie', 
          onPress: () => {
            launchCamera({
              mediaType: 'photo',
              cameraType: 'front',
              saveToPhotos: false,
              quality: 0.5,
            }, (response) => {
              if (response.didCancel) {
                addLog('User cancelled photo');
              } else if (response.errorCode) {
                addLog(`Camera Error: ${response.errorMessage}`);
              } else if (response.assets && response.assets.length > 0) {
                const photoUri = response.assets[0].uri || '';
                saveLog(type, peripheral.id, photoUri);
              }
            });
          }
        }
      ]
    );
  };

  const clearLogs = async () => {
    Alert.alert('Clear History', 'Are you sure you want to delete all logs?', [
      { text: 'No' },
      { 
        text: 'Yes', 
        onPress: async () => {
          await AsyncStorage.removeItem(STORAGE_KEY);
          setAttendanceLogs([]);
          setIsCheckedIn(false);
        }
      }
    ]);
  };

  const activeBeacon = useMemo(() => {
    return Array.from(peripherals.values()).sort((a, b) => b.rssi - a.rssi)[0];
  }, [peripherals]);

  const checkDiscovered = async () => {
    try {
      const discovered = await BleManager.getDiscoveredPeripherals();
      addLog(`Pull: ${discovered.length} found`);
      discovered.forEach(p => handleDiscoverPeripheral(p as any));
    } catch (err) {
      addLog(`Pull Error: ${err}`);
    }
  };

  const renderLogItem: ListRenderItem<AttendanceLog> = ({ item }) => (
    <View style={styles.logCard}>
      <View style={styles.logLeft}>
        <View style={[styles.statusIndicator, item.type === 'CHECK_IN' ? styles.inBg : styles.outBg]}>
          <Text style={styles.statusTextShort}>{item.type === 'CHECK_IN' ? 'IN' : 'OUT'}</Text>
        </View>
        {item.photoUri ? (
          <Image source={{ uri: item.photoUri }} style={styles.logSelfie} />
        ) : null}
      </View>
      <View style={styles.logInfo}>
        <Text style={styles.logUserName}>{item.userName}</Text>
        <Text style={styles.logMatrix}>{item.matrixNumber}</Text>
        <Text style={styles.logTime}>{item.timestamp}</Text>
        <Text style={styles.logLocation}>{item.location}</Text>
      </View>
    </View>
  );

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="light-content" backgroundColor="#1e293b" />
        
        {/* Profile Registration Modal */}
        <Modal visible={isProfileModalVisible} animationType="slide" transparent={true}>
          <View style={styles.modalOverlay}>
            <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.modalContent}>
              <Text style={styles.modalTitle}>Registration</Text>
              <Text style={styles.modalSub}>Enter your details for attendance verification</Text>
              <TextInput
                style={styles.input}
                placeholder="Full Name (e.g. John Doe)"
                placeholderTextColor="#94a3b8"
                value={tempFullName}
                onChangeText={setTempFullName}
                autoFocus
              />
              <TextInput
                style={styles.input}
                placeholder="Matrix Number (e.g. 2024219422)"
                placeholderTextColor="#94a3b8"
                value={tempMatrixNumber}
                onChangeText={setTempMatrixNumber}
              />
              <TouchableOpacity style={styles.saveBtn} onPress={saveProfile}>
                <Text style={styles.saveBtnText}>Save & Start</Text>
              </TouchableOpacity>
            </KeyboardAvoidingView>
          </View>
        </Modal>

        {/* Header Section */}
        <View style={styles.header}>
          <View style={styles.headerTop}>
            <Text style={styles.headerTitle}>Beacon Attendance</Text>
            <TouchableOpacity onPress={openProfileModal}>
              <Text style={styles.userEdit}>Edit Profile</Text>
            </TouchableOpacity>
          </View>
          <Text style={styles.welcomeText}>Welcome, {userProfile?.fullName || 'User'}</Text>
          <Text style={styles.matrixText}>{userProfile?.matrixNumber || ''}</Text>
          <View style={styles.statusBadge}>
            <View style={[styles.dot, isCheckedIn ? styles.dotIn : styles.dotOut]} />
            <Text style={styles.statusLabel}>{isCheckedIn ? 'Currently: CHECKED IN' : 'Currently: CHECKED OUT'}</Text>
          </View>
        </View>

        {/* Action Section */}
        <View style={styles.actionSection}>
          {activeBeacon ? (
            <View style={styles.activeBeaconCard}>
              <Text style={styles.locationTitle}>{BEACON_LOCATIONS[activeBeacon.id] || BEACON_LOCATIONS['DEFAULT']}</Text>
              <Text style={styles.beaconIdText}>Beacon: {activeBeacon.id}</Text>
              
              <View style={styles.signalContainer}>
                <View style={styles.signalBarContainer}>
                  <View style={[styles.signalBar, { width: `${Math.min(100, Math.max(10, (activeBeacon.rssi + 100) * 1.5))}%`, backgroundColor: activeBeacon.rssi >= PROXIMITY_THRESHOLD ? '#22c55e' : '#ef4444' }]} />
                </View>
                <Text style={[styles.rssiText, activeBeacon.rssi >= PROXIMITY_THRESHOLD ? styles.rssiGood : styles.rssiBad]}>
                  {activeBeacon.rssi} dBm - {activeBeacon.rssi >= PROXIMITY_THRESHOLD ? 'Ready' : 'Move Closer'}
                </Text>
              </View>

              <TouchableOpacity 
                style={[styles.actionButton, isCheckedIn ? styles.btnOut : styles.btnIn, activeBeacon.rssi < PROXIMITY_THRESHOLD && styles.btnDisabled]} 
                onPress={() => handleAttendance(activeBeacon)}
                disabled={activeBeacon.rssi < PROXIMITY_THRESHOLD}
              >
                <Text style={styles.actionButtonText}>
                  {isCheckedIn ? 'TAP TO CHECK OUT' : 'TAP TO CHECK IN'}
                </Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.scanContainer}>
              <Text style={styles.scanInstruction}>
                {isScanning ? 'Searching for Beacons...' : 'Near a classroom? Start scanning to record your attendance.'}
              </Text>
              <TouchableOpacity 
                style={[styles.scanButton, isScanning && styles.btnDisabled]} 
                onPress={startScan}
                disabled={isScanning}
              >
                <Text style={styles.scanButtonText}>
                  {isScanning ? 'SCANNING...' : 'START SCAN'}
                </Text>
              </TouchableOpacity>
              
              {isScanning && (
                <View style={{marginTop: 20, width: '100%'}}>
                  <Text style={{fontSize: 12, color: '#64748b', marginBottom: 10, textAlign: 'center'}}>
                    Devices found: {peripherals.size}
                  </Text>
                </View>
              )}
            </View>
          )}
        </View>

        {/* Logs Section */}
        <View style={styles.logsSection}>
          <View style={styles.logsHeader}>
            <Text style={styles.logsTitle}>Recent Logs</Text>
            {attendanceLogs.length > 0 && (
              <TouchableOpacity onPress={clearLogs}>
                <Text style={styles.clearBtn}>Clear</Text>
              </TouchableOpacity>
            )}
          </View>
          <FlatList
            data={attendanceLogs}
            renderItem={renderLogItem}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.logsList}
            ListEmptyComponent={
              <Text style={styles.emptyLogs}>No records found.</Text>
            }
          />
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8fafc' },
  
  // Modal Styles
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'center', padding: 20 },
  modalContent: { backgroundColor: 'white', borderRadius: 20, padding: 30, alignItems: 'center' },
  modalTitle: { fontSize: 24, fontWeight: '800', color: '#1e293b', marginBottom: 8 },
  modalSub: { fontSize: 14, color: '#64748b', marginBottom: 24, textAlign: 'center' },
  input: { width: '100%', borderBottomWidth: 2, borderBottomColor: '#3b82f6', fontSize: 18, paddingVertical: 10, color: '#1e293b', marginBottom: 30 },
  saveBtn: { backgroundColor: '#3b82f6', width: '100%', paddingVertical: 15, borderRadius: 12, alignItems: 'center' },
  saveBtnText: { color: 'white', fontSize: 16, fontWeight: 'bold' },

  // Header Styles
  header: { backgroundColor: '#1e293b', padding: 24, paddingBottom: 30 },
  headerTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  headerTitle: { fontSize: 20, fontWeight: '800', color: '#f8fafc' },
  userEdit: { color: '#3b82f6', fontSize: 12, fontWeight: '600' },
  welcomeText: { fontSize: 24, fontWeight: '700', color: 'white', marginBottom: 4 },
  matrixText: { fontSize: 14, color: '#94a3b8', marginBottom: 16 },
  statusBadge: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#334155', alignSelf: 'flex-start', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20 },
  dot: { width: 8, height: 8, borderRadius: 4, marginRight: 8 },
  dotIn: { backgroundColor: '#22c55e' },
  dotOut: { backgroundColor: '#ef4444' },
  statusLabel: { color: '#f8fafc', fontSize: 11, fontWeight: '700', letterSpacing: 0.5 },
  
  // Action Section
  actionSection: { padding: 20, marginTop: -20 },
  activeBeaconCard: { backgroundColor: 'white', padding: 24, borderRadius: 20, elevation: 10, shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8, alignItems: 'center' },
  locationTitle: { fontSize: 22, fontWeight: '800', color: '#1e293b', marginBottom: 4 },
  beaconIdText: { fontSize: 12, color: '#94a3b8', marginBottom: 20 },
  
  signalContainer: { width: '100%', alignItems: 'center', marginBottom: 24 },
  signalBarContainer: { width: '100%', height: 6, backgroundColor: '#f1f5f9', borderRadius: 3, marginBottom: 8, overflow: 'hidden' },
  signalBar: { height: '100%', borderRadius: 3 },
  rssiText: { fontSize: 12, fontWeight: '700' },
  rssiGood: { color: '#22c55e' },
  rssiBad: { color: '#ef4444' },

  actionButton: { width: '100%', paddingVertical: 16, borderRadius: 15, alignItems: 'center', elevation: 2 },
  btnIn: { backgroundColor: '#22c55e' },
  btnOut: { backgroundColor: '#ef4444' },
  btnDisabled: { backgroundColor: '#cbd5e1', elevation: 0 },
  actionButtonText: { color: 'white', fontWeight: '900', fontSize: 16, letterSpacing: 1 },
  
  scanContainer: { alignItems: 'center', padding: 20 },
  scanInstruction: { textAlign: 'center', color: '#64748b', marginBottom: 20, fontSize: 15, lineHeight: 22 },
  scanButton: { backgroundColor: '#3b82f6', paddingHorizontal: 40, paddingVertical: 14, borderRadius: 30, elevation: 4 },
  scanButtonText: { color: 'white', fontWeight: 'bold', fontSize: 16 },
  
  // Logs Section
  logsSection: { flex: 1, backgroundColor: 'white', borderTopLeftRadius: 30, borderTopRightRadius: 30, padding: 24, paddingBottom: 0 },
  logsHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  logsTitle: { fontSize: 18, fontWeight: '800', color: '#1e293b' },
  clearBtn: { color: '#ef4444', fontSize: 13, fontWeight: '600' },
  logsList: { paddingBottom: 20 },
  logCard: { backgroundColor: '#f1f5f9', borderRadius: 16, padding: 16, marginBottom: 12, flexDirection: 'row', alignItems: 'center' },
  logLeft: { alignItems: 'center', marginRight: 16 },
  logSelfie: { width: 60, height: 60, borderRadius: 30, marginTop: 8, backgroundColor: '#cbd5e1' },
  statusIndicator: { width: 40, height: 24, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
  inBg: { backgroundColor: '#dcfce7' },
  outBg: { backgroundColor: '#fee2e2' },
  statusTextShort: { fontSize: 10, fontWeight: '800', color: '#1e293b' },
  logInfo: { flex: 1 },
  logUserName: { fontSize: 16, fontWeight: '700', color: '#1e293b' },
  logMatrix: { fontSize: 12, color: '#64748b', marginBottom: 2 },
  logTime: { fontSize: 12, color: '#64748b' },
  logLocation: { fontSize: 11, fontWeight: '600', color: '#3b82f6', marginTop: 2 },
  emptyLogs: { textAlign: 'center', color: '#94a3b8', marginTop: 40, fontSize: 14 },
});

export default App;

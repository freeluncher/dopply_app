#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <esp_system.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// Sensor dan BPM logic
const int sensorPin = 34;
int sensorValue = 0;
int lastSensorValue = 0;
const int deltaThreshold = 10; // Lebih sensitif: threshold lebih kecil
const int noiseFloor = 900;    // Lebih sensitif: noise floor lebih rendah
unsigned long lastBeatTime = 0;
unsigned long currentTime = 0;
int bpm = 0;
bool beatDetected = false;
unsigned long beatTimeout = 3000; // 3 detik tanpa detak → BPM = 0
unsigned long monitoringStartTime = 0;

// BLE DEFINITIONS
#define LED_BUILTIN 2
#define BLE_SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_COMMAND_CHARACTERISTIC_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_TIME_CHARACTERISTIC_UUID    "6e400004-b5a3-f393-e0a9-e50e24dcca9e" // NEW: for time sync
BLECharacteristic *pCharacteristic;
BLECharacteristic *pCommandCharacteristic;
BLECharacteristic *pTimeCharacteristic; // NEW
bool bleDeviceConnected = false;
bool monitoringActive = false; // Default: tidak aktif, hanya aktif saat tombol start
unsigned long lastNotifyTime = 0;
const unsigned long notifyInterval = 1000; // 1 detik
int lastSentBpm = -1;

// --- BEST PRACTICE OPTIMIZATION PATCH ---
// 1. Non-blocking loop: Hindari delay(), gunakan millis() untuk interval sampling sensor
// 2. Filter sederhana (moving average) untuk sensor
// 3. Pisahkan logic BLE, sensor, dan LCD
// 4. LCD update hanya jika ada perubahan tampilan
// 5. Komentar dan struktur lebih rapi

// --- Tambah filter moving average sederhana ---
#define FILTER_SIZE 3          // Filter lebih responsif
int sensorBuffer[FILTER_SIZE] = {0};
int filterIndex = 0;
int filterSum = 0;

unsigned long lastSampleTime = 0;
const unsigned long sampleInterval = 15; // Sampling lebih cepat (sekitar 66Hz)

String lastLcdLine1 = "";
String lastLcdLine2 = "";

void updateLcd(const String& line1, const String& line2) {
  if (line1 != lastLcdLine1 || line2 != lastLcdLine2) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(line1);
    lcd.setCursor(0, 1);
    lcd.print(line2);
    lastLcdLine1 = line1;
    lastLcdLine2 = line2;
  }
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      bleDeviceConnected = true;
      digitalWrite(LED_BUILTIN, HIGH);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Terhubung BLE");
      Serial.println("[ESP32] BLE device connected");
      Serial.println("[ESP32] STATUS: CONNECTED");
    };
    void onDisconnect(BLEServer* pServer) {
      bleDeviceConnected = false;
      digitalWrite(LED_BUILTIN, LOW);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Terputus BLE");
      Serial.println("[ESP32] BLE device disconnected");
      Serial.println("[ESP32] STATUS: DISCONNECTED");
      // delay(1000);
      // ESP.restart(); // Dihilangkan agar tidak restart otomatis, lebih smooth reconnect
    }
};

// --- STABILIZATION PATCH ---
// 1. Tambah debounce detak (detak harus turun di bawah threshold sebelum bisa deteksi lagi)
// 2. Validasi BPM agar hanya nilai fisiologis (misal 60-200), jika di luar rentang, abaikan
// 3. Tambah low-pass filter sederhana untuk BPM
// 4. Reset BPM dan filter jika monitoring dimulai/berhenti

float bpmFiltered = 0;
const float bpmAlpha = 0.3; // smoothing factor (0.0-1.0)
bool readyForNextBeat = true;

void resetMonitoringState() {
  bpm = 0;
  bpmFiltered = 0;
  lastBeatTime = 0;
  for (int i = 0; i < FILTER_SIZE; i++) sensorBuffer[i] = 0;
  filterSum = 0;
  filterIndex = 0;
  lastSensorValue = 0;
  readyForNextBeat = true;
}

class CommandCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    if (value == "start") {
      monitoringActive = true;
      resetMonitoringState();
      monitoringStartTime = millis(); // Catat waktu mulai monitoring
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Monitoring ON");
      Serial.println("[ESP32] Monitoring started via BLE");
    } else if (value == "stop") {
      monitoringActive = false;
      resetMonitoringState();
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Monitoring OFF");
      Serial.println("[ESP32] Monitoring stopped via BLE");
    }
  }
};

// Tambahkan characteristic baru untuk sync waktu monitoring (opsional, bisa diabaikan jika Flutter pakai waktu lokal)
class TimeCharacteristicCallbacks: public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *pCharacteristic) {
    // Kirim waktu monitoring (ms sejak start) ke Flutter
    unsigned long elapsed = monitoringActive ? (millis() - monitoringStartTime) : 0;
    char timeStr[16];
    sprintf(timeStr, "%lu", elapsed);
    pCharacteristic->setValue((uint8_t*)timeStr, strlen(timeStr));
  }
};

void setup() {
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Ready");
  Serial.println("[ESP32] STATUS: STANDBY");

  // BLE INIT
  BLEDevice::init("Dopply-FetalMonitor");
  Serial.println("[ESP32] BLEDevice initialized, advertising as Dopply-FetalMonitor");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(BLE_SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      BLE_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic->addDescriptor(new BLE2902());
  // Tambahkan command characteristic
  pCommandCharacteristic = pService->createCharacteristic(
    BLE_COMMAND_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());
  // Tambahkan time characteristic (opsional)
  pTimeCharacteristic = pService->createCharacteristic(
    BLE_TIME_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ
  );
  pTimeCharacteristic->setCallbacks(new TimeCharacteristicCallbacks());
  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("[ESP32] BLE advertising started");
}

void loop() {
  currentTime = millis();
  // --- Non-blocking sensor sampling ---
  if (currentTime - lastSampleTime >= sampleInterval) {
    lastSampleTime = currentTime;
    // Moving average filter
    filterSum -= sensorBuffer[filterIndex];
    sensorBuffer[filterIndex] = analogRead(sensorPin);
    filterSum += sensorBuffer[filterIndex];
    filterIndex = (filterIndex + 1) % FILTER_SIZE;
    sensorValue = filterSum / FILTER_SIZE;

    int delta = sensorValue - lastSensorValue;
    lastSensorValue = sensorValue;

    // Abaikan sinyal lemah (noise)
    if (sensorValue < noiseFloor) {
      beatDetected = false;
      readyForNextBeat = true;
    }

    // Deteksi lonjakan (detak) dengan debounce
    if (delta > deltaThreshold && readyForNextBeat && !beatDetected) {
      unsigned long interval = currentTime - lastBeatTime;
      if (interval > 250) { // Hapus validasi rentang BPM, cukup interval saja
        bpm = 60000 / interval;
        // Low-pass filter BPM
        if (bpmFiltered == 0) bpmFiltered = bpm;
        else bpmFiltered = bpmAlpha * bpm + (1 - bpmAlpha) * bpmFiltered;
        lastBeatTime = currentTime;
        updateLcd("Detak terdeteksi", String("BPM: ") + (int)bpmFiltered);
        Serial.print("Detak terdeteksi! BPM: ");
        Serial.println((int)bpmFiltered);
        beatDetected = true;
        readyForNextBeat = false;
      }
    }
    // Debounce: tunggu delta turun sebelum deteksi detak berikutnya
    if (delta < 5) {
      beatDetected = false;
      readyForNextBeat = true;
    }

    // Jika tidak ada detak dalam waktu tertentu, setel BPM ke 0
    if ((currentTime - lastBeatTime) > beatTimeout && bpm != 0) {
      bpm = 0;
      updateLcd("Tidak terdeteksi", "BPM: 0");
      Serial.println("Tidak ada detak. BPM = 0");
    }

    // BLE NOTIFY BPM (hanya jika BPM berubah, BPM=0 satu kali, atau interval lewat)
    static bool bpmZeroSent = false;
    int bpmToSend = (bpmFiltered > 0) ? (int)bpmFiltered : bpm;
    if (bleDeviceConnected && monitoringActive) {
      bool bpmChanged = (bpmToSend != lastSentBpm);
      bool timeToNotify = (millis() - lastNotifyTime >= notifyInterval);
      if (bpmChanged || (bpmToSend == 0 && !bpmZeroSent) || timeToNotify) {
        // Format data: "<elapsed_ms>,<bpm>" agar Flutter dapat waktu monitoring
        unsigned long elapsed = millis() - monitoringStartTime;
        char dataStr[32];
        sprintf(dataStr, "%lu,%d", elapsed, bpmToSend);
        pCharacteristic->setValue((uint8_t*)dataStr, strlen(dataStr));
        pCharacteristic->notify();
        Serial.print("[ESP32] Send: ");
        Serial.println(dataStr);
        lastNotifyTime = millis();
        lastSentBpm = bpmToSend;
        if (bpmToSend == 0) bpmZeroSent = true;
        else bpmZeroSent = false;
      }
    }
    Serial.print("Sensor: ");
    Serial.print(sensorValue);
    Serial.print(" | Delta: ");
    Serial.println(delta);
  }
  // Tidak ada delay() di akhir loop
}
// --- END PATCH ---


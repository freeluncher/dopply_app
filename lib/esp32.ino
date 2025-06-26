// Dopply ESP32 Fetal Heart Rate Monitor
// - Membaca sensor detak jantung analog
// - Menampilkan status & BPM ke LCD I2C
// - Mengirim BPM via BLE (Bluetooth Low Energy) ke aplikasi

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <esp_system.h>

// --- LCD & Sensor ---
LiquidCrystal_I2C lcd(0x27, 16, 2); // LCD I2C address 0x27, 16 kolom, 2 baris
const int sensorPin = 27;           // Pin sensor analog
int rawSensorValue = 0;             // Nilai mentah dari sensor
int filteredSensor = 0;             // Nilai sensor setelah filter
int lastFilteredSensor = 0;         // Nilai filter sebelumnya
const int deltaThreshold = 20;      // Ambang perubahan detak
const int noiseFloor = 1050;        // Nilai minimum untuk noise sensor
unsigned long lastBeatTime = 0;     // Waktu detak terakhir
unsigned long currentTime = 0;      // Waktu saat ini
int bpm = 0;                        // Beats per minute (detak per menit)
bool beatDetected = false;          // Status detak terdeteksi
unsigned long beatTimeout = 3000;   // Timeout jika tidak ada detak (ms)

// --- Kalman Filter ---
float kalman_Q = 0.05;  // Variansi proses (semakin kecil = lebih halus)
float kalman_R = 1.0;   // Variansi sensor
float kalman_P = 1.0;   // Error estimasi
float kalman_K;         // Kalman gain
float kalman_X = 0.0;   // Estimasi awal

// --- BLE ---
#define LED_BUILTIN 2
#define BLE_SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
BLECharacteristic *pCharacteristic;
bool bleDeviceConnected = false;

// Callback BLE untuk status koneksi
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    bleDeviceConnected = true;
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.println("[ESP32] BLE device connected");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("BLE: CONNECTED   ");
    lcd.setCursor(0, 1);
    lcd.print("Dopply Monitor   ");
  }

  void onDisconnect(BLEServer* pServer) {
    bleDeviceConnected = false;
    digitalWrite(LED_BUILTIN, LOW);
    Serial.println("[ESP32] BLE device disconnected");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("BLE: DISCONNECT ");
    lcd.setCursor(0, 1);
    lcd.print("Wait/Scan Again ");
    pServer->getAdvertising()->start(); // Mulai advertising lagi
    delay(500);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("BLE: ADVERTISING");
    lcd.setCursor(0, 1);
    lcd.print("Dopply Monitor   ");
  }
};

void setup() {
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  lcd.begin();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("BLE: STANDBY    ");
  lcd.setCursor(0, 1);
  lcd.print("Dopply Monitor  ");
  Serial.println("[ESP32] STATUS: STANDBY");

  // Inisialisasi BLE
  BLEDevice::init("Dopply-FetalMonitor");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(BLE_SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    BLE_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("[ESP32] BLE advertising started");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("BLE: ADVERTISING");
  lcd.setCursor(0, 1);
  lcd.print("Dopply Monitor   ");
}

unsigned long lastSendTime = 0;

void loop() {
  // Baca sensor analog
  rawSensorValue = analogRead(sensorPin);
  currentTime = millis();

  // --- Kalman Filter untuk menghaluskan data sensor ---
  kalman_P = kalman_P + kalman_Q;
  kalman_K = kalman_P / (kalman_P + kalman_R);
  kalman_X = kalman_X + kalman_K * (rawSensorValue - kalman_X);
  kalman_P = (1 - kalman_K) * kalman_P;
  filteredSensor = (int)kalman_X;

  int delta = filteredSensor - lastFilteredSensor;
  lastFilteredSensor = filteredSensor;

  // Reset deteksi jika noise
  if (filteredSensor < noiseFloor) {
    beatDetected = false;
  }

  // Deteksi detak jantung berdasarkan perubahan sinyal
  if (delta > deltaThreshold && !beatDetected) {
    beatDetected = true;
    unsigned long interval = currentTime - lastBeatTime;
    if (interval > 300) { // Hindari noise sangat cepat
      bpm = 60000 / interval;
      lastBeatTime = currentTime;

      Serial.print("Detak terdeteksi! BPM: ");
      Serial.println(bpm);

      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Detak terdeteksi");
      lcd.setCursor(0, 1);
      lcd.print("BPM: ");
      lcd.print(bpm);
    }
  }

  // Reset beatDetected jika sinyal stabil
  if (delta < 5) {
    beatDetected = false;
  }

  // Jika tidak ada detak dalam beatTimeout, set BPM = 0
  if ((currentTime - lastBeatTime) > beatTimeout && bpm != 0) {
    bpm = 0;
    Serial.println("Tidak ada detak. BPM = 0");

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Tidak terdeteksi");
    lcd.setCursor(0, 1);
    lcd.print("BPM: 0");
  }

  // Kirim BPM via BLE setiap 1 detik jika terkoneksi
  if (bleDeviceConnected && (millis() - lastSendTime > 1000)) {
    String bpmStr = String(bpm);
    pCharacteristic->setValue(bpmStr.c_str());
    pCharacteristic->notify();
    Serial.print("[ESP32] Send BPM: ");
    Serial.println(bpmStr);
    lastSendTime = millis();
  }

  delay(10); // Loop delay
}
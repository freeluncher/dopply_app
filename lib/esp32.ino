#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <esp_system.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// BLE DEFINITIONS
#define LED_BUILTIN 2
#define BLE_SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

BLECharacteristic *pCharacteristic;
bool bleDeviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      bleDeviceConnected = true;
      digitalWrite(LED_BUILTIN, HIGH); // LED biru ON
      Serial.println("[ESP32] BLE device connected");
      Serial.println("[ESP32] STATUS: CONNECTED");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("BLE: CONNECTED   ");
      lcd.setCursor(0, 1);
      lcd.print("Dopply Monitor   ");
    }
    void onDisconnect(BLEServer* pServer) {
      bleDeviceConnected = false;
      digitalWrite(LED_BUILTIN, LOW); // LED biru OFF
      Serial.println("[ESP32] BLE device disconnected");
      Serial.println("[ESP32] STATUS: DISCONNECTED");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("BLE: DISCONNECT ");
      lcd.setCursor(0, 1);
      lcd.print("Wait/Scan Again ");
      pServer->getAdvertising()->start(); // Restart advertising
      Serial.println("[ESP32] BLE advertising restarted");
      delay(500); // Tampilkan status sebentar
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
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("BLE: STANDBY    ");
  lcd.setCursor(0, 1);
  lcd.print("Dopply Monitor  ");
  Serial.println("[ESP32] STATUS: STANDBY");

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

int lastBpmSent = 0;
unsigned long lastSendTime = 0;

void loop() {
  // Tidak ada logic sensor/monitoring, hanya BLE connect/disconnect
  delay(100);
  if (bleDeviceConnected) {
    unsigned long now = millis();
    if (now - lastSendTime > 1000) { // setiap 1 detik
      int bpm = random(110, 160); // simulasi BPM janin
      String bpmStr = String(bpm);
      pCharacteristic->setValue(bpmStr.c_str());
      pCharacteristic->notify();
      Serial.print("[ESP32] Send BPM: ");
      Serial.println(bpmStr);
      lastSendTime = now;
    }
  }
}


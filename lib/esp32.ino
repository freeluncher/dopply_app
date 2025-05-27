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
    }
    void onDisconnect(BLEServer* pServer) {
      bleDeviceConnected = false;
      digitalWrite(LED_BUILTIN, LOW); // LED biru OFF
      Serial.println("[ESP32] BLE device disconnected");
      Serial.println("[ESP32] STATUS: DISCONNECTED");
      pServer->getAdvertising()->start(); // Restart advertising
      Serial.println("[ESP32] BLE advertising restarted");
    }
};

void setup() {
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
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
}

void loop() {
  // Tidak ada logic sensor/monitoring, hanya BLE connect/disconnect
  delay(100);
}


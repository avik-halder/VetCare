#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <MPU6050.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <HTTPClient.h>
#include <cmath>

// ======== Wi-Fi Credentials ========
const char* ssid = "Anik";
const char* password = "12345670";

// ======== Sensor Pins =========
const int mq4Pin = 36;
const int pulsePin = 39;
const int ds18b20Pin = 4;
const int phPin = 34;

// ======== Sensor Objects ========
MPU6050 mpu;
OneWire oneWire(ds18b20Pin);
DallasTemperature ds18b20(&oneWire);
WebServer server(80);

// ======== Timing for POST ========
unsigned long lastSent = 0;
const unsigned long sendInterval = 5000;  // Send every 5 seconds

// ======== HTML Builder ========
String buildWebPage() {
  int gasValue = analogRead(mq4Pin);
  float gasVoltage = gasValue * (3.3 / 4095.0);

  int pulseValue = analogRead(pulsePin);

  int phRaw = analogRead(phPin);
  float phVoltage = phRaw * (3.3 / 4095.0);
  float phValue = -4.36 * phVoltage + 14.72;

  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  ds18b20.requestTemperatures();
  float temperatureC = ds18b20.getTempCByIndex(0);

  String html = "<!DOCTYPE html><html><head><meta http-equiv='refresh' content='2'>";
  html += "<title>Cattle Health Monitoring</title></head><body style='font-family:Arial'>";
  html += "<h2>Cattle Health Monitoring Dashboard</h2><hr>";
  html += "<p><b>MQ-4 (Methane Gas):</b> " + String(gasValue) + " (" + String(gasVoltage, 2) + " V)</p>";
  html += "<p><b>Pulse Sensor:</b> " + String(pulseValue) + "</p>";
  html += "<p><b>pH Value:</b> " + String(phValue, 2) + " (" + String(phVoltage, 2) + " V)</p>";
  html += "<p><b>Temperature:</b> ";
  html += (temperatureC == DEVICE_DISCONNECTED_C) ? "Sensor Error" : (String(temperatureC, 2) + " °C");
  html += "</p>";
  html += "<p><b>Accelerometer:</b> X=" + String(ax) + " Y=" + String(ay) + " Z=" + String(az) + "</p>";
  html += "<p><b>Gyroscope:</b> X=" + String(gx) + " Y=" + String(gy) + " Z=" + String(gz) + "</p>";
  html += "<hr><p><i>Auto-refresh every 2 seconds</i></p></body></html>";

  return html;
}

// ======== Send Sensor Data to FastAPI ========
void sendSensorData() {
  int mqValue = analogRead(mq4Pin);
  int pulse = analogRead(pulsePin);

  int phRaw = analogRead(phPin);
  float phVoltage = phRaw * (3.3 / 4095.0);
  float phValue = -4.36 * phVoltage + 14.72;

  ds18b20.requestTemperatures();
  float temp = ds18b20.getTempCByIndex(0);

  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  float accelMag = sqrt(ax * ax + ay * ay + az * az);
  float gyroMag = sqrt(gx * gx + gy * gy + gz * gz);

  // Create JSON payload
  String json = "{";
  json += "\"Temp\":" + String(temp, 2) + ",";
  json += "\"MQ\":" + String(mqValue) + ",";
  json += "\"Accel_X\":" + String(ax) + ",";
  json += "\"Accel_Y\":" + String(ay) + ",";
  json += "\"Accel_Z\":" + String(az) + ",";
  json += "\"Gyro_X\":" + String(gx) + ",";
  json += "\"Gyro_Y\":" + String(gy) + ",";
  json += "\"Gyro_Z\":" + String(gz) + ",";
  json += "\"pH\":" + String(phValue, 2) + ",";
  json += "\"Pulse\":" + String(pulse) + ",";
  json += "\"Accel_Mag\":" + String(accelMag, 2) + ",";
  json += "\"Gyro_Mag\":" + String(gyroMag, 2);
  json += "}";

  HTTPClient http;
  http.begin("http://192.168.43.62:8000/store-sensor");  // TODO: Replace with actual IP
  http.addHeader("Content-Type", "application/json");

  int response = http.POST(json);
  Serial.print("POST /store-sensor => ");
  Serial.println(response);

  http.end();
}

// ======== Setup ========
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Starting...");

  ds18b20.begin();
  Wire.begin(21, 22);  // SDA, SCL
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("MPU6050 connection failed!");
    while (true);
  }

  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nFailed to connect. Restarting...");
    ESP.restart();
  }

  server.on("/", []() {
    server.send(200, "text/html", buildWebPage());
  });
  server.begin();
  Serial.println("Web server started.");
}

// ======== Loop ========
void loop() {
  server.handleClient();

  if (millis() - lastSent >= sendInterval) {
    sendSensorData();
    lastSent = millis();
  }
}

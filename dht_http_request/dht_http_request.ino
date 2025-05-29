#include <WiFi.h>
#include "DHT.h"
#include <HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* pass = "YOUR_WIFI_PWD";

// DHT sensor setup
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Relay sensor setup
#define RELAY_PIN 25
float tempThreshold = 32.00;
float humThreshold = 90.00;

// OLED setup
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Variables
float hum = 0, temp = 0;
String relay_status = "";
unsigned long sendDataPrevMillis = 0;
unsigned long thresholdLastCheck = 0;
String serverName = "YOUR_SERVER_NAME";

void setup() {
  Serial.begin(115200);
  delay(100);

  // Relay pin
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Relay OFF initially

  // OLED Init
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    while (true);
  }
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Connecting WiFi...");
  display.display();

  // Connect WiFi
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("WiFi Connected");
  display.println(WiFi.localIP());
  display.display();

  Serial.println("WiFi connected");
  dht.begin();
}

void loop() {
  if (millis() - sendDataPrevMillis > 10000 || sendDataPrevMillis == 0) {
    getDHT();
    sendDataPrevMillis = millis();

    if (WiFi.status() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;
      String httpReqStr = serverName + "post_dht11.php?id=101&temp=" + temp + "&hum=" + hum + "&relay_status=" + relay_status;
      http.begin(client, httpReqStr.c_str());
      int httpResponseCode = http.GET();
      if (httpResponseCode > 0) {
        Serial.print("HTTP Response code: ");
        Serial.println(httpResponseCode);
        String payload = http.getString();
        Serial.println(payload);
      } else {
        Serial.print("Error code: ");
        Serial.println(httpResponseCode);
      }
      http.end();
    }
  }

  if (millis() - thresholdLastCheck > 60000 || thresholdLastCheck == 0) {
    fetchThresholds();
    thresholdLastCheck = millis();
  }
}

void getDHT() {
  delay(2000);

  temp = dht.readTemperature();
  hum = dht.readHumidity();

  if (!isnan(temp) && !isnan(hum)) {
    Serial.printf("Temp: %.2f°C | Humidity: %.2f%%\n", temp, hum);

    if (temp > tempThreshold || hum > humThreshold) {
      digitalWrite(RELAY_PIN, LOW); // Relay ON
      relay_status = "ON";
      Serial.println("Relay Status: ON");
    } else {
      digitalWrite(RELAY_PIN, HIGH); // Relay OFF
      relay_status = "OFF";
      Serial.println("Relay Status: OFF");
    }

    updateOLED();

  } else {
    Serial.println("DHT sensor read failed.");
  }

  delay(200);
}

void fetchThresholds() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client;
    HTTPClient http;
    http.begin(client, serverName + "get_threshold.php");
    int httpCode = http.GET();

    if (httpCode > 0) {
      String payload = http.getString();
      Serial.println("Threshold payload: " + payload);
      DynamicJsonDocument doc(256);
      deserializeJson(doc, payload);
      tempThreshold = doc["temp_threshold"];
      humThreshold = doc["hum_threshold"];
    } else {
      Serial.println("Failed to fetch thresholds");
    }
    http.end();
  }
}

void updateOLED() {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(1);

  display.print("Temp: ");
  display.print(temp);
  display.println(" C");

  display.print("Hum : ");
  display.print(hum);
  display.println(" %");

  display.print("Relay: ");
  display.println(relay_status);

  if (relay_status == "ON") {
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.println("ALERT: HIGH T/H");
  } else {
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.println("Status: SAFE");
  }

  display.display();
}

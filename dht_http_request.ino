#include <WiFi.h>
#include <dht.h>
#include <HTTPClient.h>
#include <WiFiClient.h>

#define D4 2  //DHT11 Sensor connected to D4
const char* ssid = "myUUM_Guest";
const char* pass = "";
int hum = 0, temp = 0;
//String relay = "Off", prevRelay = "On";
// String timestamp = "", datestamp = "", hourstamp = "";
unsigned long sendDataPrevMillis = 0;
int count = 0;
String serverName = "http://iottraininggoh.threelittlecar.com/";
dht DHT;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  delay(100);
  WiFi.begin(ssid, pass);
  delay(100);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  timeClient.begin();
}

void loop() {
  // put your main code here, to run repeatedly:
  if (millis() - sendDataPrevMillis > 10000 || sendDataPrevMillis == 0) {
    count++;
    getDHT();
    sendDataPrevMillis = millis();

    if (WiFi.status() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;
      String httpReqStr = serverName + "dht11.php?id=101temp=" + temp + "&hum=" + hum;
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
      // Free resources
      http.end();
    }
  }
}


void getDHT() {
  int chk = DHT.read11(D4);
  Serial.print("Temperature=");
  Serial.println(DHT.temperature);
  hum = DHT.humidity;
  temp = DHT.temperature;
  Serial.print("Humidity=");
  Serial.println(DHT.humidity);
  delay(200);
}
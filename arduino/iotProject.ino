#include <FirebaseESP8266.h>
#include <ESP8266WiFi.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>


#define SSID ".@PineApple_E4Xu9"
#define PASSWORD "11111111"

#define FIREBASE_HOST "https://smart-band-cf871-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define FIREBASE_AUTH "JX15qmqlfmSvSZB8aXDpxUYGXQyzSOBpoX6vUJIK"

#define BAUDRATE	115200

#define TMPPin A0 //TMP36 attached to ESP8266 ESP-12E ADC

// #define REPORTING_PERIOD_MS 1000

MAX30105 particleSensor;
unsigned long previousMillis = 0;   // Stores the last time the action was executed
unsigned long interval = 5000; // Interval in milliseconds (5 seconds)

LiquidCrystal_I2C lcd(0x27, 16, 2);

int currentPage = 0;    // Current page index
int maxPages = 3;       // Total number of pages

unsigned long previousMillisLCD = 0;    // Stores the previous time value
unsigned long intervalLCD = 5000; // Interval in milliseconds to change pages automatically


// กำหนดตัวแปรเก็บค่าเวลา ชั่วโมง-นาที-วินาที
int hourNow, minuteNow, secondNow;

//Setup to sense up to 18 inches, max LED brightness
byte ledBrightness = 0xFF; //Options: 0=Off to 255=50mA
byte sampleAverage = 4; //Options: 1, 2, 4, 8, 16, 32
byte ledMode = 2; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
byte sampleRate = 400; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
int pulseWidth = 411; //Options: 69, 118, 215, 411
int adcRange = 2048; //Options: 2048, 4096, 8192, 16384

const byte RATE_SIZE = 4; //Increase this for more averaging. 4 is good.
byte rates[RATE_SIZE]; //Array of heart rates
byte rateSpot = 0;
long lastBeat = 0; //Time at which the last beat occurred

float beatsPerMinute;
int beatAvg;

FirebaseData firebaseData;
float tempC;
float tempF;
double heartrate;

// กำหนดค่า offset time เนื่องจากเวลาของเซิฟเวอร์นี้เป็นเวลา UTC เราต้องทำให้เป็นเวลาของประเทศไทย
// เวลาของประเทศไทย = UTC+7 ชั่วโมง ต้องกำหนด offset time = 7 ชั่วโมง
const long utcOffsetInSeconds = 25200; // หน่วยเป็นวินาที จะได้ 7*60*60 = 25200
//Week Days
String weekDays[7]={"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

//Month names
String months[12]={"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

// กำหนด object ของ WiFiUDP ชื่อว่า ntpUDP
WiFiUDP ntpUDP;
// กำหนด object ของ NTPClient ชื่อว่า timeClient มีรูปแบบ ("WiFiUDP Object","NTP Server Address","offset time")
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds);

bool isHeartRate = true, isTemp = true, isPowerSaver = false, isLight = true, isVibration = true;

String msg = "";

void setup() {
    Serial.begin(BAUDRATE);
    initHeartRate();
    initLCD();

    connectWifi();
    Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
    // เริ่มการทำงานของ NTPClient
    timeClient.begin();
    // pinMode(D4, OUTPUT);
    // digitalWrite(D4, LOW);
    getFirebaseData();
    lcd.clear();
}

void loop() {
  // Check if the interval has passed to automatically change pages
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillisLCD >= intervalLCD) {
    previousMillisLCD = currentMillis;
    currentPage = (currentPage + 1) % maxPages;
    displayPage(currentPage);
  }
    getTemp();
    getHeartRate();
    updateFirebaseRT(currentMillis);
}

void displayPage(int page) {
  lcd.clear(); // Clear the LCD screen

  // Display different content based on the page index
  switch (page) {
    case 0:
      showClock();
      break;
    case 1:
      showTemp();
      break;
    case 2:
      showHeartRate();
      break;
    case 3:
      showNotification();
      break;
    // Add more cases for additional pages if needed
  }
}

void showNotification() {
  lcd.setCursor(0, 0);
  lcd.autoscroll();
  lcd.print(msg);
}

void showTemp() {
  lcd.setCursor(3, 0);
  lcd.print("Temperature");
  lcd.setCursor(5, 1);
  lcd.print(String(tempC) + " C");
}

void showHeartRate() {
  lcd.setCursor(3, 0);
  lcd.print("HeartRate");
  lcd.setCursor(3, 1);
  lcd.print("Avg BPM=" + String(beatAvg));
}

void showClock() {
// ร้องขอ timestamps ด้วยคำสั่ง update
  timeClient.update();

  minuteNow = timeClient.getMinutes();
  hourNow = timeClient.getHours();

  time_t epochTime = timeClient.getEpochTime();
  String weekDay = weekDays[timeClient.getDay()];

  //Get a time structure
  struct tm *ptm = gmtime ((time_t *)&epochTime); 

  int monthDay = ptm->tm_mday;

  int currentMonth = ptm->tm_mon+1;

  String currentMonthName = months[currentMonth-1];

  int currentYear = ptm->tm_year+1900;

  //Print complete date:
  String currentDate = String(weekDay) + "," + String(monthDay) + " " + String(currentMonthName) + " " + String(currentYear);


// แสดงเวลาออกทางจอ LCD
  // บรรทัดแรกแสดงข้อความ(ข้อความเดิมตลอด)
  lcd.setCursor(1, 0);
  lcd.print(currentDate);
  // บรรทัดที่สองแสดงเวลา
  lcd.setCursor(5, 1);
  if(hourNow < 10)(lcd.print("0"));
  lcd.print(hourNow);
  lcd.print(":");
  if(minuteNow < 10)(lcd.print("0"));
  lcd.print(minuteNow);
}

void connectWifi() {
    Serial.println(WiFi.localIP());
    WiFi.begin(SSID, PASSWORD);
    Serial.print("Connecting to ");
    Serial.print(SSID);
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(500);
    }
    Serial.println();
    Serial.print("connected: ");
    Serial.println(WiFi.localIP());
    // Register event handlers for Wi-Fi events
    WiFi.onStationModeDisconnected(onStationDisconnected);
    WiFi.onStationModeGotIP(onStationGotIP);
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Connected!");
    lcd.setCursor(2,1);
    lcd.print(WiFi.localIP());
}

void updateFirebaseRT(long currentMillis) {
  // Check if the specified interval has elapsed
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis; // Update the previous time
    FirebaseJson temperature;
    temperature.set("C", tempC);
    temperature.set("F", tempF);

    FirebaseJson heartrate;
    heartrate.set("BPM", beatsPerMinute);
    heartrate.set("Avg BPM", beatAvg);

    FirebaseJson data;
    data.set("body_temp", temperature);
    data.set("heart_rate", heartrate);
    data.set("timestamp", timeClient.getEpochTime());

    if(Firebase.updateNode(firebaseData, "/" + String(WiFi.macAddress()), data)) {
      Serial.println("Updated"); 
    } else {
      Serial.println("Error : " + firebaseData.errorReason());
    }

    if(Firebase.pushJSON(firebaseData, "/" + String(WiFi.macAddress()) + "/records", data)) {
    Serial.println("Pushed : " + firebaseData.pushName()); 
} else {
    Serial.println("Error : " + firebaseData.errorReason());
}

    }
}

void initHeartRate() {
  // Initialize sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) //Use default I2C port, 400kHz speed
  {
    Serial.println("MAX30105 was not found. Please check wiring/power. ");
    while (1);
  }
  Serial.println("Place your index finger on the sensor with steady pressure.");

  //particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange); //Configure sensor with these settings
  particleSensor.setup();
  particleSensor.setPulseAmplitudeGreen(0); //Turn off Green LED
  particleSensor.setPulseAmplitudeRed(0x0A); //Turn Red LED to low to indicate sensor is running
}

void getHeartRate() {
    // Make sure to call update as fast as possible
    long irValue = particleSensor.getIR();

        if (checkForBeat(irValue) == true)
  {
    //We sensed a beat!
    long delta = millis() - lastBeat;
    lastBeat = millis();

    beatsPerMinute = 60 / (delta / 1000.0);

    if (beatsPerMinute < 255 && beatsPerMinute > 20)
    {
      rates[rateSpot++] = (byte)beatsPerMinute; //Store this reading in the array
      rateSpot %= RATE_SIZE; //Wrap variable

      //Take average of readings
      beatAvg = 0;
      for (byte x = 0 ; x < RATE_SIZE ; x++)
        beatAvg += rates[x];
      beatAvg /= RATE_SIZE;
    }
  }

  Serial.print(" IR=" + String(irValue) + ", BPM=" + String(beatsPerMinute) + ", Avg BPM=" + String(beatAvg));
  if (irValue < 50000)
    Serial.print(" No finger?");
  Serial.println();
}

void getTemp() {
  if(isTemp) {
    int tmpValue = analogRead(TMPPin);
    float voltage = tmpValue * 3.3;// converting that reading to voltage
    voltage /= 1024.0;
    tempC = ((voltage - 0.5) * 100);  //converting from 10 mv per degree wit 500 mV offset
    //to degrees ((voltage - 500mV) times 100)
    tempF = (tempC * 9.0 / 5.0) + 32.0;  //now convert to Fahrenheit
    
    // Serial.println(" Temp= " + String(tempC) + " C, " + String(tempF) + " F ");
    } else {
      //nothing
    }
}

void onStationDisconnected(const WiFiEventStationModeDisconnected& event) {
  Serial.println("Disconnected from Wi-Fi network");
  Serial.print("Reason: ");
  Serial.println(event.reason);
  
  // Attempt to reconnect to Wi-Fi network
  WiFi.begin(SSID, PASSWORD);
}

void onStationGotIP(const WiFiEventStationModeGotIP& event) {
  Serial.print("Connected to Wi-Fi network. IP address: ");
  Serial.println(WiFi.localIP());
}

void getFirebaseData() {
      Firebase.setStreamCallback(firebaseData, streamCallback, streamTimeoutCallback);
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/vibration")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/heart_rate")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/lcd/current_page")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/lcd/light")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/lcd/msg")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/lcd/page_time")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/temp")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
    if (!Firebase.beginStream(firebaseData, "/" + String(WiFi.macAddress()) + "/sensors/main/power_saver")) {
        Serial.println("Error : " + firebaseData.errorReason());
    }
}

void streamCallback(StreamData data) {
    // Value in Firebase RTDB has updated
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/vibration" && data.dataType() == "boolean") {
      isVibration = data.boolData();
      Serial.println(data.boolData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/heart_rate" && data.dataType() == "boolean") {
      isHeartRate = data.boolData();
      Serial.println(data.boolData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/lcd/current_page" && data.dataType() == "string") {
      currentPage = String(data.stringData()).toInt();
      Serial.println(data.stringData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/lcd/light" && data.dataType() == "boolean") {
      isLight = data.boolData();
      if(isLight) {
        lcd.backlight();
      } else {
        lcd.noBacklight();
      }
      Serial.println(data.boolData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/lcd/msg" && data.dataType() == "string") {
      msg = data.stringData();
      currentPage = 3;
      Serial.println(data.stringData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/lcd/page_time" && data.dataType() == "string") {
      intervalLCD = String(data.stringData()).toInt();
      Serial.println(data.stringData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/temp" && data.dataType() == "boolean") {
      isTemp = data.boolData();
      Serial.println(data.boolData());
    }
    if(data.streamPath() == "/" + String(WiFi.macAddress()) + "/sensors/main/power_saver" && data.dataType() == "boolean") {
      isPowerSaver = data.boolData();
      Serial.println(data.boolData());
    }
}

void streamTimeoutCallback(bool timeout) {
    if (timeout) {
        Serial.println("Stream timeout, resume streaming...");
    }
}

void initLCD() {
  lcd.begin();
  lcd.backlight();
  lcd.setCursor(0, 0); // กำหนดให้ เคอร์เซอร์ อยู่ตัวอักษรตำแหน่งที่0 แถวที่ 1 เตรียมพิมพ์ข้อความ
  lcd.print("Initialize....."); //พิมพ์ข้อความ "Initialize....."
  lcd.setCursor(0, 1); // กำหนดให้ เคอร์เซอร์ อยู่ตัวอักษรกำแหน่งที3 แถวที่ 2 เตรียมพิมพ์ข้อความ
  lcd.print("Waiting for WiFi"); //พิมพ์ข้อความ "Waiting for connection"
}
// Feather9x_RX
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messaging client (receiver)
// with the RH_RF95 class. RH_RF95 class does not provide for addressing or
// reliability, so you should only use RH_RF95 if you do not need the higher
// level messaging abilities.
// It is designed to work with the other example Feather9x_TX

#include <SPI.h>

// #define _SIMULATION_

#ifndef _SIMULATION_
#include "MY_RH_RF95.h"
#else
#include "RH_RF95_simulation.h"
#endif


#define SW_VERSION "0.2"

/* for Feather32u4 RFM9x
  #define RFM95_CS 8
  #define RFM95_RST 4
  #define RFM95_INT 7
*/
// for feather m0 RFM9x
#define RFM95_CS 8
#define RFM95_RST 4
#define RFM95_INT 3

#if defined(ESP8266)
/* for ESP w/featherwing */
#define RFM95_CS 2    // "E"
#define RFM95_RST 16  // "D"
#define RFM95_INT 15  // "B"
#elif defined(ESP32)
/* ESP32 feather w/wing */
#define RFM95_RST 27  // "A"
#define RFM95_CS 33   // "B"
#define RFM95_INT 12  // next to A
#elif defined(NRF52)
/* nRF52832 feather w/wing */
#define RFM95_RST 7   // "A"
#define RFM95_CS 11   // "B"
#define RFM95_INT 31  // "C"
#elif defined(TEENSYDUINO)
/* Teensy 3.x w/wing */
#define RFM95_RST 9  // "A"
#define RFM95_CS 10  // "B"
#define RFM95_INT 4  // "C"
#endif
// Change to 434.0 or other frequency, must match RX's freq!
#define RF95_FREQ 915.0

#define SPREADING_FACTOR 11  // 8 - 11
#define BANDWIDTH_KHZ 125    // 125/250/500

// Singleton instance of the radio driver

volatile uint8_t rxTestCounterCurrent;
volatile uint8_t rxTestCounterPrevious;
volatile uint32_t loopCounter;
volatile uint8_t regValue;
volatile int8_t sRegValue;

float frequency = RF95_FREQ;
uint8_t spreadingFactor = SPREADING_FACTOR;
long bandwidth_khz = BANDWIDTH_KHZ;
bool doDisplayMessage = true;

// Blinky on receipt
#ifdef _SIMULATION_
#define LED 13
#else
#define LED 7u
#endif

MY_RH_RF95 rf95(RFM95_CS, RFM95_INT);

static void GetConfiguration();
static void PrintResults();

void setup() {
  Serial.print("version ");
  Serial.println(SW_VERSION);

  pinMode(LED, OUTPUT);
  pinMode(RFM95_RST, OUTPUT);
  digitalWrite(RFM95_RST, HIGH);

  Serial.begin(115200);
  // Serial.begin(9600);
  while (!Serial)
    delay(1);

  Serial.println("Start Feather LoRa Receiver");

  // manual reset
  digitalWrite(RFM95_RST, LOW);
  delay(10);
  digitalWrite(RFM95_RST, HIGH);
  delay(10);

  if (!rf95.init()) {
    Serial.println("LoRa radio init failed");
    while (1)
      ;
  }

  Serial.println("LoRa radio init OK!");

  // Defaults after init are 434.0MHz, modulation GFSK_Rb250Fd250, +13dbM
  if (!rf95.setFrequency(frequency)) {
    Serial.println("setFrequency failed");
    while (1)
      ;
  }

  Serial.print("Set Freq to: ");
  Serial.println(frequency);

  // Defaults after init are 434.0MHz, 13dBm, Bw = 125 kHz, Cr = 4/5, Sf = 128chips/symbol, CRC on

  rf95.setTxPower(9, false);

  Serial.print("Spreading Factor: ");
  Serial.println(spreadingFactor);

  Serial.print("Bandwidth [KHz]: ");
  Serial.println(bandwidth_khz);

  rf95.setSpreadingFactor(spreadingFactor);
  //rf95.setPayloadCRC(false);
  rf95.setSignalBandwidth(bandwidth_khz*1000);
  //  rf95.setSignalBandwidth(62500);
  //  rf95.setCodingRate4(6);  //Coding Rate 4/8
  rf95.setCodingRate4(5);  //Coding Rate 4/8
}

void loop() {
  if (doDisplayMessage) {
    uint8_t buf[RH_RF95_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);

    if (rf95.recv(buf, &len)) {
      // RH_RF95::printBuffer("Received: ", buf, len);
      Serial.print("Recived: ");
      Serial.println((char*)buf);
    }
  }

  rf95.setModeRx();

  GetConfiguration();

  static long int prev_ms = millis();

  if (millis() - prev_ms < 1000)
    return;

  prev_ms = millis();

  PrintResults();
}

void GetConfiguration() {
  if (Serial.available()) {
    String teststr = Serial.readString();  //read string from serial
    teststr.trim();                        // remove any \r \n whitespace at the end of the String

    if (teststr == "reset") {
      rf95.resetRxGood();
      rf95.resetRxBad();
      // delay(10);

      Serial.println(teststr + " OK");
    } else {
      String partialString = teststr.substring(0, 3);

      if (partialString == "bw=") {
        partialString = teststr.substring(3, teststr.length());

        bandwidth_khz = partialString.toInt();
        Serial.print("Set Signal Bandwidth to ");
        Serial.println(bandwidth_khz);
        // delay(10);

        rf95.setSignalBandwidth(bandwidth_khz*1000);
        Serial.println(teststr + " OK");
      } else if (partialString == "sf=") {
        partialString = teststr.substring(3, teststr.length());

        Serial.print("Set Spreading Factor to ");
        Serial.println(partialString.toInt());
        // delay(10);

        rf95.setSpreadingFactor(spreadingFactor = partialString.toInt());
      } else if (partialString == "dm=") {
        doDisplayMessage = teststr.substring(3, teststr.length()) != "0";
        // delay(10);
        rf95.setSpreadingFactor(spreadingFactor = partialString.toInt());
      } else {
        Serial.println(teststr + " is not valid: 'bw=<SignalBandwidth>' | 'sf=<>'SpreadingFactor");
      }
    }
  }
}

void PrintResults() {
  static char json_str[250];

  snprintf(json_str,
           sizeof(json_str),
           "{\"spreading_factor\":%u, \"bandwidth\":%ld, \"rssi\":%d, \"rx_good\":%u, \"rx_bad\":%u, \"snr\":%d, \"seconds\":%lu}",
           (unsigned int)spreadingFactor,
           bandwidth_khz,
           rf95.lastRssi(),
           rf95.rxGood(),
           rf95.rxBad(),
           rf95.lastSNR(),
           millis() / 1000);

  Serial.println(json_str);
}

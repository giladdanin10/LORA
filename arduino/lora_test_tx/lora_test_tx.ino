// Feather9x_TX
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messaging client (transmitter)
// with the RH_RF95 class. RH_RF95 class does not provide for addressing or
// reliability, so you should only use RH_RF95 if you do not need the higher
// level messaging abilities.
// It is designed to work with the other example Feather9x_RX

#include <SPI.h>

// #define _SIMULATION_

#ifndef _SIMULATION_
#include "MY_RH_RF95.h"
#else
#include "RH_RF95_simulation.h"
#endif

#define SW_VERSION "0.1"

// First 3 here are boards w/radio BUILT-IN. Boards using FeatherWing follow.
#if defined(__AVR_ATmega32U4__)  // Feather 32u4 w/Radio
#define RFM95_CS 8
#define RFM95_INT 7
#define RFM95_RST 4

#elif defined(ADAFRUIT_FEATHER_M0) || defined(ADAFRUIT_FEATHER_M0_EXPRESS) || defined(ARDUINO_SAMD_FEATHER_M0)  // Feather M0 w/Radio
#define RFM95_CS 8
#define RFM95_INT 3
#define RFM95_RST 4

#elif defined(ARDUINO_ADAFRUIT_FEATHER_RP2040_RFM)  // Feather RP2040 w/Radio
#define RFM95_CS 16
#define RFM95_INT 21
#define RFM95_RST 17

#elif defined(__AVR_ATmega328P__)  // Feather 328P w/wing
#define RFM95_CS 4                 //
#define RFM95_INT 3                //
#define RFM95_RST 2                // "A"

#elif defined(ESP8266)  // ESP8266 feather w/wing
#define RFM95_CS 2      // "E"
#define RFM95_INT 15    // "B"
#define RFM95_RST 16    // "D"

#elif defined(ARDUINO_ADAFRUIT_FEATHER_ESP32S2) || defined(ARDUINO_NRF52840_FEATHER) || defined(ARDUINO_NRF52840_FEATHER_SENSE)
#define RFM95_CS 10   // "B"
#define RFM95_INT 9   // "A"
#define RFM95_RST 11  // "C"

#elif defined(ESP32)  // ESP32 feather w/wing
#define RFM95_CS 33   // "B"
#define RFM95_INT 27  // "A"
#define RFM95_RST 13

#elif defined(ARDUINO_NRF52832_FEATHER)  // nRF52832 feather w/wing
#define RFM95_CS 11                      // "B"
#define RFM95_INT 31                     // "C"
#define RFM95_RST 7                      // "A"

#elif defined(__AVR_ATmega2560__)  //
#define RFM95_CS 8
#define RFM95_RST 4
#define RFM95_INT 3

#endif

/* Some other possible setups include:

// Feather 32u4:
#define RFM95_CS   8
#define RFM95_RST  4
#define RFM95_INT  7

// Feather M0:
#define RFM95_CS   8
#define RFM95_RST  4
#define RFM95_INT  3

// Arduino shield:
#define RFM95_CS  10
#define RFM95_RST  9
#define RFM95_INT  7

// Feather 32u4 w/wing:
#define RFM95_RST 11  // "A"
#define RFM95_CS  10  // "B"
#define RFM95_INT  2  // "SDA" (only SDA/SCL/RX/TX have IRQ!)

// Feather m0 w/wing:
#define RFM95_RST 11  // "A"
#define RFM95_CS  10  // "B"
#define RFM95_INT  6  // "D"
*/

// Change to 434.0 or other frequency, must match RX's freq!
#define RF95_FREQ 915.0

#define SPREADING_FACTOR 11  // 8 - 11
#define BANDWIDTH_KHZ 125    // 125/250/500
#define POWER_LEVEL 23

// Singleton instance of the radio driver
MY_RH_RF95 rf95(RFM95_CS, RFM95_INT);

float frequency = RF95_FREQ;
uint8_t spreadingFactor = SPREADING_FACTOR;
long bandwidth_khz = BANDWIDTH_KHZ;
uint8_t powerCnfg = POWER_LEVEL;

unsigned long delayBetweenMessages = 1000;

static void GetConfiguration();
static void PrintResults();

void setup() {
  pinMode(RFM95_RST, OUTPUT);
  digitalWrite(RFM95_RST, HIGH);

  Serial.begin(115200);
  while (!Serial) delay(1);
  delay(100);

  Serial.println("Feather LoRa TX Test!");

  // manual reset
  digitalWrite(RFM95_RST, LOW);
  delay(10);
  digitalWrite(RFM95_RST, HIGH);
  delay(10);

  while (!rf95.init()) {
    Serial.println("LoRa radio init failed");
    Serial.println("Uncomment '#define SERIAL_DEBUG' in RH_RF95.cpp for detailed debug info");
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
  Serial.println(RF95_FREQ);

  // Defaults after init are 434.0MHz, 13dBm, Bw = 125 kHz, Cr = 4/5, Sf = 128chips/symbol, CRC on

  // The default transmitter power is 13dBm, using PA_BOOST.
  // If you are using RFM95/96/97/98 modules which uses the PA_BOOST transmitter pin, then
  // you can set transmitter powers from 5 to 23 dBm:
  rf95.setTxPower(23, false);

  Serial.print("Spreading Factor: ");
  Serial.println(spreadingFactor);

  Serial.print("Bandwidth [KHz]: ");
  Serial.println(bandwidth_khz);

  rf95.setSpreadingFactor(spreadingFactor);
  //rf95.setPayloadCRC(false);
  rf95.setSignalBandwidth(bandwidth_khz * 1000);
  //  rf95.setSignalBandwidth(62500);
  //  rf95.setCodingRate4(6);  //Coding Rate 4/8
  rf95.setCodingRate4(5);  //Coding Rate 4/8
}

int16_t packetnum = 0;  // packet counter, we increment per xmission

void loop() {
  GetConfiguration();

  static long int prev_ms = millis();

  if (millis() - prev_ms < delayBetweenMessages)
    return;

  prev_ms = millis();

  // Serial.println("Transmitting...");  // Send a message to rf95_server

  char radiopacket[20] = "Hello World";
  itoa(packetnum++, radiopacket + 13, 10);
  radiopacket[19] = 0;
  Serial.print("Send: ");
  Serial.println(radiopacket);

  // Serial.println("Sending...");
  // delay(10);
  rf95.send((uint8_t *)radiopacket, 20);

  // Serial.println("Waiting for packet to complete...");
  // delay(10);
  rf95.waitPacketSent();

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

        Serial.print("Set Signal Bandwidth to ");
        Serial.println(partialString.toInt() * 1000);
        // delay(10);

        rf95.setSignalBandwidth((bandwidth_khz = partialString.toInt()) * 1000);
        Serial.println(teststr + " OK");
      } else if (partialString == "sf=") {
        partialString = teststr.substring(3, teststr.length());

        Serial.print("Set Spreading Factor to ");
        Serial.println(partialString.toInt());
        // delay(10);

        rf95.setSpreadingFactor(spreadingFactor = partialString.toInt());
        Serial.println(teststr + " OK");
      } else if (partialString == "pw=") {
        partialString = teststr.substring(3, teststr.length());

        Serial.print("Set power ");
        Serial.println(partialString.toInt());
        // delay(10);

        rf95.setTxPower(powerCnfg = partialString.toInt(),false);
        Serial.println(teststr + " OK");
      }
        else if (partialString == "dl=") {
        partialString = teststr.substring(3, teststr.length());

        Serial.print("Set delay between messages ");
        Serial.println(partialString.toInt());
        // delay(10);

        delayBetweenMessages = partialString.toInt();
        Serial.println(teststr + " OK");
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
           "{\"spreading_factor\":%u, \"bandwidth\":%ld, \"tx_good\":%u}",
           (unsigned int)spreadingFactor,
           bandwidth_khz,
           rf95.txGood());

  Serial.println(json_str);
}

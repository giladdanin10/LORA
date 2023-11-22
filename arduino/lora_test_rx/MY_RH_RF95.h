// RH_RF95.h
//
221123
#ifndef MY_RH_RF95_h
#define MYRH_RF95_h

#include <RH_RF95.h>

class MY_RH_RF95 : public RH_RF95 {
public:
  MY_RH_RF95(uint8_t slaveSelectPin = SS, uint8_t interruptPin = 2, RHGenericSPI& spi = hardware_spi) 
  : RH_RF95(slaveSelectPin, interruptPin, spi) {}

  virtual void resetRxBad() {
    _rxBad = 0;
  }
  virtual void resetRxGood() {
    _rxGood = 0;
  }
};

#endif

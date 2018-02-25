/* -------------------------------------------------------------
 *  Project: GreenMouse
 *  Version: 1.0.0.0b
 *  
 *  Information:
 *  Устройство-Эмулятор мыши , клавиатуры и других устройств. 
 * -------------------------------------------------------------
 */

#include <Arduino.h>
#include <Wire.h>
#include "HID-Project.h"

void setup() {
  SetupDevice();
}

void loop() {
  LoopDevice();
  delay(1);
}

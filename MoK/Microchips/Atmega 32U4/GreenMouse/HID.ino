/* -------------------------------------------------------------
 *  Установка HID устройств.
 * -------------------------------------------------------------
 */

uint8_t rawhidData[255];

void SetupHID() {
  RawHID.begin(rawhidData, sizeof(rawhidData));
  Consumer.begin();
  Gamepad.begin();
  Keyboard.begin();
  Mouse.begin();
  System.begin();
  Serial.begin(115200);
}

void LoopHID() {
  
}

/* -------------------------------------------------------------
 *  Project: GreenMouse
 *  Version: 1.0.0.0b
 *  
 *  Information:
 *  Устройство-Эмулятор мыши , клавиатуры и других устройств. 
 * ------------------------------------------------------------- 
 */

#include <Arduino.h>
#include "HID-Project.h"

#define DeviceID                36 // Version 1
#define DeviceType              1  // TypeDevice
#define DeviceKey               1000

#define MOUSE                   1
#define KEYBOARD                2
#define IDentifier              240

#define Left                    0
#define Right                   1
#define Middle                  2

#define UP                      2
#define DOWN                    4
#define WHELL                   8
#define MOVE                    16
                              
struct MoK{
  byte cType;
  long cKey;
  long cMethod;
  long cParam;
};

struct _HID {
  uint8_t HID[255];
  byte Recv[128];
  int iByte;
};

struct _KEY {
  byte ID;
  long Key;
  byte Type;
};

struct Device {
  MoK MoK;
  _KEY KEY;
  _HID HID;
};

Device Device;

void setup() {
  Serial.begin(9600);
  RawHID.begin(Device.HID.HID, sizeof(Device.HID.HID));
  Keyboard.begin();
  Mouse.begin();
  Device.KEY.ID   = DeviceID;
  Device.KEY.Key  = DeviceKey;
  Device.KEY.Type = DeviceType;
}

void loop() {
  Device.HID.iByte = RawHID.available();
  if (Device.HID.iByte > 0) {
    for (int i = 0; i < 128; i ++ ) {
      Device.HID.Recv[i] = RawHID.read();
    }
    memcpy(&Device.MoK, &Device.HID.Recv[0], sizeof(MoK) );
    _Device();
    //Serial.println("-- Debug --");
    //Serial.print("MoK.cType = ");Serial.println(Device.MoK.cType);
    //Serial.print("MoK.cKey = ");Serial.println(Device.MoK.cKey);
    //Serial.print("MoK.cMethod = ");Serial.println(Device.MoK.cMethod);
    //Serial.print("MoK.cParam = ");Serial.println(Device.MoK.cParam);
  }
}

void _Mouse() {
  if (Device.MoK.cMethod == DOWN ) {
    switch ( Device.MoK.cKey ) {
      case Left:
        Mouse.press(MOUSE_LEFT);
        break;
      case Middle:
        Mouse.press(MOUSE_MIDDLE);
        break;
      case Right:
        Mouse.press(MOUSE_RIGHT);
        break;
    }
  }
  if (Device.MoK.cMethod == UP ) {
    switch ( Device.MoK.cKey ) {
      case Left:
        Mouse.release(MOUSE_LEFT);
        break;
      case Middle:
        Mouse.release(MOUSE_MIDDLE);
        break;
      case Right:
        Mouse.release(MOUSE_RIGHT);
        break;
    }
  }
  if (Device.MoK.cMethod == WHELL) {
    Mouse.move(0, 0, Device.MoK.cKey);
  }
  if (Device.MoK.cMethod == MOVE) {
    Mouse.move(Device.MoK.cKey, Device.MoK.cParam, 0);
  }
}

void _Keyboard() {
  if (Device.MoK.cMethod == DOWN ) {
    Keyboard.press(Device.MoK.cKey);
  }
  if (Device.MoK.cMethod == UP ) {
    Keyboard.release(Device.MoK.cKey);
  }
}

void _Device() {
  switch ( Device.MoK.cType ) {
    case MOUSE:
       _Mouse();
      break;
    case KEYBOARD:
      _Keyboard();
      break;
    case IDentifier:
      memcpy(&Device.HID.Recv[0], &Device.KEY, sizeof(_KEY) );
      RawHID.write(&Device.HID.Recv[0], 128);
      break;
  }
}


/* -------------------------------------------------------------
 *  Управление мышки / флешки с программы.
 * -------------------------------------------------------------
 */
 
#define CONTROL_HID_MOUSE              0x01
#define CONTROL_HID_KEYBOARD           0x02
#define CONTROL_HID_GAMEPAD            0x03
#define CONTROL_HID_CONSUMER           0x04
#define CONTROL_HID_SYSTEM             0x05
#define CONTROL_HID_SHELL              0x06

#define MOUSEEVENTF_MOVE               0x01
#define MOUSEEVENTF_LEFTDOWN           0x02
#define MOUSEEVENTF_LEFTUP             0x04
#define MOUSEEVENTF_MIDDLEDOWN         0x20
#define MOUSEEVENTF_MIDDLEUP           0x40
#define MOUSEEVENTF_RIGHTDOWN          0x08
#define MOUSEEVENTF_RIGHTUP            0x10
#define MOUSEEVENTF_WHEEL              0x80

#define KEYBOARD_KEY_DOWN              0x04
#define KEYBOARD_KEY_UP                0x02

#define GAMEPAD_XAXIS                  0x01
#define GAMEPAD_YAXIS                  0x02
#define GAMEPAD_RELEASE_ALL            0x03
#define GAMEPAD_PRESS                  0x04
#define GAMEPAD_RELEASE                0x05
#define GAMEPAD_PAD1                   0x06
#define GAMEPAD_PAD2                   0x07

#define CONSUMER_WRITE                 0x01
#define CONSUMER_PRESS                 0x02
#define CONSUMER_RELEASE               0x03
#define CONSUMER_RELEASE_ALL           0x04

#define SYSTEM_WRITE                   0x01
#define SYSTEM_PRESS                   0x02
#define SYSTEM_RELEASE                 0x03
#define SYSTEM_RELEASE_ALL             0x04

byte rRead;
byte recv[64];

void SetupRaw() {
  
}

void LoopRaw() {
  auto bytesAvailable = RawHID.available();
  if (bytesAvailable > 0) {
    for (int counter = 0; counter < 64; counter ++ ) {
      recv[counter] = RawHID.read();
    }
    RawFunc();
  }
  
}

void RawFunc() {
  switch (recv[0]) {
    case CONTROL_HID_MOUSE: // Mouse
      switch (recv[1]) {
        // LEFT
        case MOUSEEVENTF_LEFTDOWN:
          Mouse.press(MOUSE_LEFT);
          break;
        case MOUSEEVENTF_LEFTUP:
          Mouse.release(MOUSE_LEFT);
          break;
        // MIDDLE
        case MOUSEEVENTF_MIDDLEDOWN:
          Mouse.press(MOUSE_MIDDLE);
          break;
        case MOUSEEVENTF_MIDDLEUP:
          Mouse.release(MOUSE_MIDDLE);
          break;
        // RIGHT
        case MOUSEEVENTF_RIGHTDOWN:
          Mouse.press(MOUSE_RIGHT);
          break;
        case MOUSEEVENTF_RIGHTUP:
          Mouse.release(MOUSE_RIGHT);
          break;
        // Wheel Scroll
        case MOUSEEVENTF_WHEEL:
          Mouse.move(0,0,recv[2]);
          break;
        // Mouse Move And Scroll
        case MOUSEEVENTF_MOVE:
          Mouse.move(recv[2], recv[3], recv[4]);
          break;
      }
      break;
    case CONTROL_HID_KEYBOARD:
      switch (recv[1]) {
        case KEYBOARD_KEY_DOWN:
          Keyboard.press(recv[2]);
          break;
        case KEYBOARD_KEY_UP:
          Keyboard.release(recv[2]);
          break;
      }
      break;
    case CONTROL_HID_GAMEPAD:
      switch (recv[1]) {
        case GAMEPAD_XAXIS:
          Gamepad.xAxis(random(0xFFFF));
          break;
        case GAMEPAD_YAXIS:
          Gamepad.yAxis(random(0xFFFF));
          break;
        case GAMEPAD_RELEASE_ALL:
          Gamepad.releaseAll();
          break;
        case GAMEPAD_PRESS:
          Gamepad.press(recv[2]);
          break;
        case GAMEPAD_RELEASE:
          Gamepad.release(recv[2]);
          break;
        case GAMEPAD_PAD1:
          Gamepad.dPad1(recv[2]);
          break;
        case GAMEPAD_PAD2:
          Gamepad.dPad2(recv[2]);
          break;
      }
      break;
    case CONTROL_HID_CONSUMER:
      switch (recv[1]) {
        case CONSUMER_WRITE:
          Consumer.write(recv[2]);
          break;
        case CONSUMER_PRESS:
          Consumer.press(recv[2]);
          break;
        case CONSUMER_RELEASE:
          Consumer.release(recv[2]);
          break;
        case CONSUMER_RELEASE_ALL:
          Consumer.releaseAll();
          break;
      }
      break;
    case CONTROL_HID_SYSTEM:
      switch (recv[1]) {
        case SYSTEM_WRITE:
          System.write(recv[2]);
          break;
        case SYSTEM_PRESS:
          System.press(recv[2]);
          break;
        case SYSTEM_RELEASE:
          System.release();
          break;
        case SYSTEM_RELEASE_ALL:
          System.releaseAll();
          break;
      }
      break;
  }
}


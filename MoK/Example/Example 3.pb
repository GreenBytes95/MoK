XIncludeFile "..\MoK.pb"

UseModule MoK

Precedency(#Profile0)

Delay(1000)

Global _temp.l = -1

While 1
  If Device(#DeviceHID) <> _temp
    _temp = Device(#DeviceHID)
    If DeviceID(#DeviceID) = 0
      _temp = 0
    EndIf
    If _temp = 1
      Debug "ID: " + Str(DeviceID(#DeviceID))
      Debug "Key: " + Str(DeviceID(#DeviceKey))
      Debug "Type: " + Str(DeviceID(#DeviceType))
    EndIf
  EndIf
  
  Delay(10)
  
Wend
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 19
; EnableXP
XIncludeFile "..\MoK.pb"

UseModule MoK

Precedency(#Profile0)

Delay(1000)

Global _temp.l = -1

While 1
  If Device() <> _temp
    _temp = Device()
    If _temp = 1
      Debug USB::GetKey(MoK\USB)
    EndIf
  EndIf
  
  Delay(10)
  
Wend
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 14
; EnableXP
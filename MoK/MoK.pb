; #INDEX# =======================================================================================================================
; Title .........: MouseKey
; Language ......: Русский
; Description ...: Функции для работы с эмуляцией кнопок мыши.
; Author ........: GreenBytes ( https://vk.com/greenbytes )
; Dll ...........: win32u.dll, user32.dll, inpout32.dll
; ===============================================================================================================================

; #VERSION# =====================================================================================================================
; Version ..... .: 1.0.0.0
;{===============================================================================================================================

; #INFO# ========================================================================================================================
; Version ..... .: 1.0.0.1
; Description ...: Обновлены функции:
;                 
; ===============================================================================================================================

;}#END-VERSION# =================================================================================================================

XIncludeFile "..\HID\HID.pbi"

DeclareModule MoK
  ;-----------------------------------------------------------
  ;-       MouseKey Constants
  ;{----------------------------------------------------------
  
  #Left = 0;
  #Right = 1;
  #Middle = 2;
  #MoveX = 3 ;
  #MoveY = 4;
  
  #PROFILE = 0;
  #API = 1;
  #APIEx = 2;
  #PS2 = 3;
  #HOOK = 4;
  #GAME = 5;
  #HID = 6;
  
  #Up = 2;
  #Down = 4;
  #Whell = 8;
  #Move = 16;
  #Click = #UP | #Down
  
  #KeyboardPS2    =   2
  #MousePS2       =   4
  #DeviceHID      =   8
  #DeviceDigiUSB  =   16
  
  #USB_PID=$8036
  #USB_VID=$2341
  
  ;}----------------------------------------------------------
  ;-       MouseKey ImportC
  ;{----------------------------------------------------------
  
  ImportC "Bin\memorymodule.lib"
    MemoryLoadLibrary(MemoryPointer)
    MemoryGetProcAddress(hModule, FunctionName.p-ascii)
    MemoryFreeLibrary(hModule)
  EndImport
  
  ;}----------------------------------------------------------
  ;-       MouseKey Structure
  ;{----------------------------------------------------------
  
  Structure IO
    hIO.l
    Inp32.l
    Out32.l
    IsInpOutDriverOpen.l
    Key.b
  EndStructure
  
  Structure PSP_DEVICE_INTERFACE_DETAIL_DATA
    cbSize.l
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
      DevicePath.l
    CompilerElse 
      DevicePath.c
    CompilerEndIf
  EndStructure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Global
  ;{----------------------------------------------------------
  
  Global mIN.INPUT, kIN.INPUT, InpOut32.IO, PROFILE.l = #API, Win32u.l, User32.l, HookType.l, GameType.l, hHID.l
  
  ;}----------------------------------------------------------
  ;-       MouseKey Declare
  ;{----------------------------------------------------------
  
  Declare.l PROFILE(Type.l = #API)
  Declare.l Mouse(cKey.l = #Left, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  Declare.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  
  ;}----------------------------------------------------------
  ;-       MouseKey Init
  ;{----------------------------------------------------------
  
  Win32u = OpenLibrary(#PB_Any, "win32u.dll") 
  User32 = OpenLibrary(#PB_Any, "user32.dll") 
  If GetFunction(Win32u, "gDispatchTableValues") <> 0 ; Win 10 
    PokeL(?NtUserSendInput_gDispatchTableValues, GetFunction(Win32u, "gDispatchTableValues") + $110)
    HookType = #PB_OS_Windows_10
  EndIf
  
  GameType = OSVersion()
  
  mIN\type = #INPUT_MOUSE
  kIN\type = #INPUT_KEYBOARD
  
  ;}----------------------------------------------------------
EndDeclareModule

Module MoK
  ;-----------------------------------------------------------
  ;-       MouseKey Module -> HID -> Prototype
  ;{----------------------------------------------------------
  
  Global LibHid = OpenLibrary(#PB_Any, "hid.dll")
  Global LibSetupApi = OpenLibrary(#PB_Any, "setupapi.dll")
  
  Prototype HidD_GetHidGuid(*HidGuid.GUID) : Global HidD_GetHidGuid.HidD_GetHidGuid = GetFunction(LibHID, "HidD_GetHidGuid")
  Prototype SetupDiEnumDeviceInterfaces(*DeviceInfoSet, DeviceInfoData, *InterfaceClassGuid.GUID, MemberIndex, *DeviceInterfaceData.SP_DEVICE_INTERFACE_DATA) : Global SetupDiEnumDeviceInterfaces.SetupDiEnumDeviceInterfaces = GetProcAddress_(LibSetupApi,"SetupDiEnumDeviceInterfaces")
  Prototype SetupDiGetDeviceInterfaceDetail(*DeviceInfoSet, *DeviceInterfaceData.SP_DEVICE_INTERFACE_DATA, DeviceInterfaceDetailData, DeviceInterfaceDetailDataSize, *RequiredSize, *DeviceInfoData) : Global SetupDiGetDeviceInterfaceDetail.SetupDiGetDeviceInterfaceDetail = GetProcAddress_(LibSetupApi,"SetupDiGetDeviceInterfaceDetailA")
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> HID -> Procedure
  ;{----------------------------------------------------------
  
  Procedure.l OpenHID()
    Protected HidGuid.GUID, devInfoData.SP_DEVICE_INTERFACE_DATA, Length.l
    Protected *detailData.PSP_DEVICE_INTERFACE_DETAIL_DATA, Required, hDevice.l
    HidD_GetHidGuid(@HidGuid)
    Protected hDevInfo=SetupDiGetClassDevs_(@HidGuid, 0, 0, #DIGCF_PRESENT | #DIGCF_ALLCLASSES | #DIGCF_DEVICEINTERFACE)
    If Not hDevInfo : ProcedureReturn 0 : EndIf
    For i=0 To 255
      If Not SetupDiEnumDeviceInterfaces(hDevInfo, 0, @HidGuid, i, @devInfoData) : Break : EndIf
      If SetupDiGetDeviceInterfaceDetail(hDevInfo, @devInfoData, 0, 0,@Length, 0)
        *detailData=AllocateMemory(Length)
        *detailData\cbSize=SizeOf(PSP_DEVICE_INTERFACE_DETAIL_DATA)
        SetupDiGetDeviceInterfaceDetail(hDevInfo, @devInfoData, *detailData, Length+1, @Required, 0)
        DevicePath.s=PeekS(@*detailData\DevicePath)
        FreeMemory(*detailData)
        Debug DevicePath
      EndIf
    Next
  EndProcedure
  
  ;OpenHID()
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Init
  ;{----------------------------------------------------------
  
  Procedure.l IsIO()
    If InpOut32\hIO = 0
      InpOut32\hIO = MemoryLoadLibrary(?IO)
      InpOut32\Inp32 = MemoryGetProcAddress(InpOut32\hIO, "Inp32")
      InpOut32\Out32 = MemoryGetProcAddress(InpOut32\hIO, "Out32")
      InpOut32\IsInpOutDriverOpen = CallFunctionFast(MemoryGetProcAddress(InpOut32\hIO, "IsInpOutDriverOpen"))
    EndIf
    ProcedureReturn InpOut32\IsInpOutDriverOpen
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Procedure
  ;{----------------------------------------------------------
  
  Procedure PS2SendWaint(Arg.b, Arg2.b)
    If Arg <> $00 And Arg2 <> $00
      CallFunctionFast(InpOut32\Out32, Arg, Arg2)
    EndIf
    While (CallFunctionFast(InpOut32\Inp32, $64) & 2)
      !NOP
    Wend
  EndProcedure
  
  Procedure PS2SendClick(send.b, xZ.l = 0, whell.b = 0)
    PS2SendWaint($00, $00)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, send)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, $00)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, $00)
    If xZ = 1
      PS2SendWaint($64, $D3)
      PS2SendWaint($60, whell)
    EndIf
  EndProcedure
  
  Procedure.l MouseDecode(Key.l, Type.l = 0)
    Select Type
      Case 0
        Select Key
          Case #MOUSEEVENTF_LEFTDOWN
            ProcedureReturn #MOUSEEVENTF_LEFTUP
          Case #MOUSEEVENTF_MIDDLEDOWN
            ProcedureReturn #MOUSEEVENTF_MIDDLEUP
          Case #MOUSEEVENTF_RIGHTDOWN
            ProcedureReturn #MOUSEEVENTF_RIGHTUP
          Case $0080
            ProcedureReturn $0100
        EndSelect
      Case 1
        Select Key
          Case #MOUSEEVENTF_LEFTDOWN
            ProcedureReturn %00001001
          Case #MOUSEEVENTF_RIGHTDOWN
            ProcedureReturn %00001010
          Case #MOUSEEVENTF_MIDDLEDOWN
            ProcedureReturn %00001100
        EndSelect
    EndSelect
  EndProcedure
  
  Procedure.l MouseTrace(cKey.l)
    Select cKey
      Case #Left
        ProcedureReturn #MOUSEEVENTF_LEFTDOWN
      Case #Middle
        ProcedureReturn #MOUSEEVENTF_MIDDLEDOWN
      Case #Right
        ProcedureReturn #MOUSEEVENTF_RIGHTDOWN
    EndSelect
    ProcedureReturn cKey
  EndProcedure
  
  Procedure GetType()
    ProcedureReturn PROFILE
  EndProcedure
  
  Procedure.l SelectTypeAdress(Type.l)
    If Type = 0 : ProcedureReturn PeekL(?mType) : EndIf
    ProcedureReturn PeekL(?mType + (4 * (Type - 1)))
  EndProcedure
  
  Procedure.l SelectTypeAdressKeyBoard(Type.l)
    If Type = 0 : ProcedureReturn PeekL(?kType) : EndIf
    ProcedureReturn PeekL(?kType + (4 * (Type - 1)))
  EndProcedure
  
  Procedure.l NtUserSendInput_(cInputs.l, pInputs.l, cbSize.l)
    Select HookType
      Case #PB_OS_Windows_10
        ProcedureReturn CallFunctionFast(?NtUserSendInput, cInputs.l, pInputs.l, cbSize.l)
    EndSelect
    SendInput_(cInputs.l, pInputs.l, cbSize.l)
  EndProcedure  
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Mouse
  ;{----------------------------------------------------------
  
  Procedure.l m_API(cKey.l, delay.l, Method.l)
    If Method & #Down
      mIN\mi\dwFlags = cKey
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      mIN\mi\dwFlags = MouseDecode(cKey)
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Whell
      mIN\mi\dwFlags = #MOUSEEVENTF_WHEEL
      mIN\mi\mouseData = delay
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Move
      mIN\mi\dwFlags = #MOUSEEVENTF_MOVE
      If cKey = #MoveX
        mIN\mi\dx = delay
        mIN\mi\dy = 0
      ElseIf cKey = #MoveY
        mIN\mi\dy = delay
        mIN\mi\dx = 0
      EndIf
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l m_APIEx(cKey.l, delay.l, Method.l)
    Protected hWnd = GetDesktopWindow_()
    If Method & #Down
      SetForegroundWindow_(hWnd)
      SetFocus_(hWnd)
      mIN\mi\dwFlags = cKey
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      SetForegroundWindow_(hWnd)
      SetFocus_(hWnd)
      mIN\mi\dwFlags = MouseDecode(cKey)
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Whell
      mIN\mi\dwFlags = #MOUSEEVENTF_WHEEL
      mIN\mi\mouseData = delay
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Move
      mIN\mi\dwFlags = #MOUSEEVENTF_MOVE
      If cKey = #MoveX
        mIN\mi\dx = delay
        mIN\mi\dy = 0
      ElseIf cKey = #MoveY
        mIN\mi\dy = delay
        mIN\mi\dx = 0
      EndIf
      SendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l m_PS2(cKey.l, delay.l, Method.l)
    If IsIO() = 0 : ProcedureReturn 0 : EndIf
    If Method & #Down
      PS2SendClick(MouseDecode(cKey, 1), 1)
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      PS2SendClick(%00001000, 1)
    EndIf
    If Method & #Whell
      PS2SendClick(%00001000, 1, delay)
    EndIf
  EndProcedure
  
  Procedure.l m_Hook(cKey.l, delay.l, Method.l)
    If Method & #Down
      mIN\mi\dwFlags = cKey
      NtUserSendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      mIN\mi\dwFlags = MouseDecode(cKey)
      NtUserSendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Whell
      mIN\mi\dwFlags = #MOUSEEVENTF_WHEEL
      mIN\mi\mouseData = delay
      NtUserSendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
    If Method & #Move
      mIN\mi\dwFlags = #MOUSEEVENTF_MOVE
      If cKey = #MoveX
        mIN\mi\dx = delay
        mIN\mi\dy = 0
      ElseIf cKey = #MoveY
        mIN\mi\dy = delay
        mIN\mi\dx = 0
      EndIf
      NtUserSendInput_(1, @mIN, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l m_Game(cKey.l, delay.l, Method.l)
    If GameType > #PB_OS_Windows_7
      ProcedureReturn m_API(cKey.l, delay.l, Method.l)
    Else
      ProcedureReturn m_APIEx(cKey.l, delay.l, Method.l)
    EndIf
  EndProcedure
  
  Procedure.l m_HID(cKey.l, delay.l, Method.l)
    If Not hHID : hHID = HID::OpenDevice(#USB_PID, #USB_VID) : EndIf
    If Not hHID : ProcedureReturn 0 : EndIf
    Protected *aMem = AllocateMemory(65 + 2)
    If Method & #Down
      PokeB(*aMem + 1, $01) ; Mouse
      PokeB(*aMem + 2, cKey)  ; Key
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    If Method & #Up
      If Not hHID : ProcedureReturn 0 : EndIf
      If delay > 0 : Delay(delay) : EndIf
      PokeB(*aMem + 1, $01) ; Mouse
      PokeB(*aMem + 2, MouseDecode(cKey))  ; Key
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    If Method & #Whell
      PokeB(*aMem + 1, $01) ; Mouse
      PokeB(*aMem + 2, $80)  ; Key
      PokeB(*aMem + 3, delay) 
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    If Method & #Move
      PokeB(*aMem + 1, $01) ; Mouse
      PokeB(*aMem + 2, $01) ; Key
      If cKey = #MoveX
        PokeB(*aMem + 3, delay) 
      ElseIf cKey = #MoveY
        PokeB(*aMem + 4, delay) 
      EndIf
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    FreeMemory(*aMem)
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Keyboard
  ;{----------------------------------------------------------
  
  Procedure.l k_API(cKey.l, delay.l, Method.l)
    kIN\ki\wVk = cKey
    If Method & #Down
      kIN\ki\dwFlags = 0
      SendInput_(1, @kIN, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      kIN\ki\dwFlags = #KEYEVENTF_KEYUP
      SendInput_(1, @kIN, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l k_PS2(cKey.l, delay.l, Method.l)
    If IsIO() = 0 : ProcedureReturn 0 : EndIf
    If Method & #Down
      PS2SendWaint($00, $00)
      PS2SendWaint($64, $D2)
      PS2SendWaint($60, MapVirtualKey_(cKey, 0))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      PS2SendWaint($00, $00)
      PS2SendWaint($64, $D2)
      PS2SendWaint($60, (MapVirtualKey_(cKey, 0) | $80))
    EndIf
  EndProcedure
  
  Procedure.l k_Hook(cKey.l, delay.l, Method.l)
    kIN\ki\wVk = cKey
    If Method & #Down
      kIN\ki\dwFlags = 0
      NtUserSendInput_(1, @kIN, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      kIN\ki\dwFlags = #KEYEVENTF_KEYUP
      NtUserSendInput_(1, @kIN, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l k_Game(cKey.l, delay.l, Method.l)
    If GameType > #PB_OS_Windows_7
      ProcedureReturn k_API(cKey.l, delay.l, Method.l)
    Else
      ProcedureReturn k_PS2(cKey.l, delay.l, Method.l)
    EndIf
  EndProcedure
  
  Procedure.l k_HID(cKey.l, delay.l, Method.l)
    If Not hHID : hHID = HID::OpenDevice(#USB_PID, #USB_VID) : EndIf
    If Not hHID : ProcedureReturn 0 : EndIf
    Protected *aMem = AllocateMemory(65 + 2)
    If Method & #Down
      PokeB(*aMem + 1, $02) ; CONTROL_HID_MOUSE
      PokeB(*aMem + 2, $04)  ; KEYBOARD_KEY_DOWN
      PokeB(*aMem + 3, cKey) ; Key
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    If Method & #Up
      If Not hHID : ProcedureReturn 0 : EndIf
      If delay > 0 : Delay(delay) : EndIf
      PokeB(*aMem + 1, $02) ; CONTROL_HID_MOUSE
      PokeB(*aMem + 2, $02)  ; KEYBOARD_KEY_UP
      PokeB(*aMem + 3, cKey) ; Key
      If HID::WriteDevice(hHID, *aMem, 65) = 0
        HID::CloseDevice(hHID)
        hHID = 0
      EndIf
    EndIf
    FreeMemory(*aMem)
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Is [Function]
  ;{----------------------------------------------------------
  
  Procedure IsDevice()
    Protected fDevice.l
    If Not hHID : hHID = HID::OpenDevice(#USB_PID, #USB_VID) : EndIf
    If hHID <> 0 : fDevice = fDevice | #DeviceHID : EndIf
    
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Declare
  ;{----------------------------------------------------------
  
  Procedure.l PROFILE(Type.l = #API)
    PROFILE = Type
    ProcedureReturn PROFILE
  EndProcedure
  
  Procedure.l Mouse(cKey.l = #Left, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
    If Type.l = #PROFILE : Type.l = GetType() : EndIf
    CallFunctionFast(SelectTypeAdress(Type.l), MouseTrace(cKey), delay, Method)
  EndProcedure
  
  Procedure.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
    If Type.l = #PROFILE : Type.l = GetType() : EndIf
    CallFunctionFast(SelectTypeAdressKeyBoard(Type.l), cKey, delay, Method)
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> DataSection
  ;{----------------------------------------------------------
  
  DataSection
    IO:
    IncludeBinary "Bin\IO.s"
    mType:
    Data.l @m_API()
    Data.l @m_APIEx()
    Data.l @m_PS2()
    Data.l @m_Hook()
    Data.l @m_Game()
    Data.l @m_HID()
    kType:
    Data.l @k_API()
    Data.l @k_API()
    Data.l @k_PS2()
    Data.l @k_Hook()
    Data.l @k_Game()
    Data.l @k_HID()
    NtUserSendInput:
    Data.b $B8, $84, $10, $00, $00, $BA
    NtUserSendInput_gDispatchTableValues: 
    Data.b $90, $90, $90, $90, $FF, $D2, $C2, $0C, $00, $90
  EndDataSection
  

   
  ;}----------------------------------------------------------
EndModule

; #INDEX# =======================================================================================================================
; Compile .........: Компиляция эмулятора в DLL
; ===============================================================================================================================
CompilerIf #PB_Compiler_DLL And Not #PB_Compiler_Debugger
  
  HID::HID_Init()
  
  ProcedureDLL.l PROFILE(Type.l = MoK::#API)
    ProcedureReturn MoK::PROFILE(Type.l)
  EndProcedure
  
  ProcedureDLL.l Mouse(cKey.l = MoK::#Left, delay.l = 32, Method.l = MoK::#Click, Type.l = MoK::#PROFILE)
    ProcedureReturn MoK::Mouse(cKey.l, delay.l, Method.l, Type.l)
  EndProcedure
  
  ProcedureDLL.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = MoK::#Click, Type.l = MoK::#PROFILE)
    ProcedureReturn MoK::Mouse(cKey.l, delay.l, Method.l, Type.l)
  EndProcedure
  
CompilerEndIf

; HID::HID_Init()
; Delay(3000)
; MoK::Mouse(MoK::#Left, 64, MoK::#Click, MoK::#HID)
; Delay(32)
; MoK::Keyboard(#VK_3, 32, MoK::#Click, MoK::#HID)
; Delay(32)
; MoK::Keyboard(#VK_1, 32, MoK::#Click, MoK::#HID)

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 19
; FirstLine = 8
; Folding = ---------
; EnableAsm
; EnableThread
; EnableXP
; EnableAdmin
; EnableOnError
; Executable = Bin\MoK.dll.exe
; CompileSourceDirectory
; EnablePurifier
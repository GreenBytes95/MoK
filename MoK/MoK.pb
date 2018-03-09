; #INDEX# =======================================================================================================================
; Title .........: MouseKey
; Version .......: 3.0
; Language ......: Русский
; Description ...: Функции для работы с эмуляцией кнопок мыши и клавиатуры.
; Author ........: GreenBytes ( https://vk.com/greenbytes )
; Dll ...........: win32u.dll, user32.dll, inpout32.dll
; ===============================================================================================================================


DeclareModule MoK
  ;-----------------------------------------------------------
  ;-       MouseKey Constants
  ;{----------------------------------------------------------
  
  #Left           = 0;
  #Right          = 1;
  #Middle         = 2;
  
  #Up             = 2;
  #Down           = 4;
  #Whell          = 8;
  #Move           = 16;
  #Click          = #UP | #Down;
  
  #PROFILE        = 0;
  #API            = 1;
  #APIEx          = 2;
  #PS2            = 3;
  #DeviceHID      = 4;
  
  #Profile0       = 0;
  #Profile1       = 1;
  #Profile2       = 2;
  #Profile3       = 3;
  #Profile4       = 4;
  
  #HIDPS2KEYBOARD = 2;
  #HIDPS2MOUSE    = 4;
  
  #Mouse          = 1;
  #Keyboard       = 2;
  
  #HID_PID        = $8036;
  #HID_VID        = $2341;
  
  #HID_RX_TX_SIZE = 128 + 2;
  
  #IDentifier     = 240
  
  #DeviceID       = 0
  #DeviceKey      = 1
  #DeviceType     = 2
  
  ;}----------------------------------------------------------
  ;-       MouseKey -> HID -> Constants
  ;{----------------------------------------------------------
  
  #SPDRP_ADDRESS = $1C
  #SPDRP_BUSNUMBER = $15
  #SPDRP_BUSTYPEGUID = $13
  #SPDRP_CAPABILITIES = $F
  #SPDRP_CHARACTERISTICS = $1B
  #SPDRP_CLASS = $7
  #SPDRP_CLASSGUID = $8
  #SPDRP_COMPATIBLEIDS = $2
  #SPDRP_CONFIGFLAGS = $A
  #SPDRP_DEVICEDESC = $0
  #SPDRP_DEVTYPE = $19
  #SPDRP_DRIVER = $9
  #SPDRP_ENUMERATOR_NAME = $16
  #SPDRP_EXCLUSIVE = $1A
  #SPDRP_FRIENDLYNAME = $C
  #SPDRP_HARDWAREID = $1
  #SPDRP_LEGACYBUSTYPE = $14
  #SPDRP_LOCATION_INFORMATION = $D
  #SPDRP_LOWERFILTERS = $12
  #SPDRP_MAXIMUM_PROPERTY = $1C
  #SPDRP_MFG = $B
  #SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = $E
  #SPDRP_SECURITY = $17
  #SPDRP_SECURITY_SDS = $18
  #SPDRP_SERVICE = $4
  #SPDRP_UI_NUMBER = $10
  #SPDRP_UI_NUMBER_DESC_FORMAT = $1E
  #SPDRP_UNUSED0 = $3
  #SPDRP_UNUSED1 = $5
  #SPDRP_UNUSED2 = $6
  #SPDRP_UPPERFILTERS = $11
  #SPDRP_LOCATION_PATHS = $23
  
  ;}----------------------------------------------------------
  ;-       MouseKey -> HID -> Structure
  ;{----------------------------------------------------------
  
  Structure PSP_DEVICE_INTERFACE_DETAIL_DATA
    cbSize.l
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
      DevicePath.l
    CompilerElse 
      DevicePath.c
    CompilerEndIf
  EndStructure
  
  Structure HIDD_ATTRIBUTES
    Size.l
    VendorID.u
    ProductID.u
    VersionNumber.w
  EndStructure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Structure
  ;{----------------------------------------------------------
  
  Structure _KEY
    __NOP.a
    ID.a
    Key.l
    Type.a
    _NOP.a[#HID_RX_TX_SIZE - 1 - 4 - 1 - 2]
  EndStructure
  
  Structure IO
    hIO.l
    Inp32.l
    Out32.l
    IsInpOutDriverOpen.l
    Key.b
  EndStructure
  
  Structure MouseGreen
    cNOP.a
    cType.a
    cKey.l
    cMethod.l
    cParam.l
  EndStructure
  
  Structure MouseHID
    Mouse.MouseGreen
    hid_size.a[#HID_RX_TX_SIZE - SizeOf(MouseGreen)]
  EndStructure
  
  Structure HID
    MouseHID.MouseHID
    lib_hid.l
    lib_setupapi.l
    func_HidD_GetHidGuid.l
    func_HidD_GetAttributes.l
    func_SetupDiEnumDeviceInterfaces.l
    func_SetupDiEnumDeviceInfo.l
    func_SetupDiGetDeviceInterfaceDetailW.l
    func_SetupDiGetDeviceInterfaceDetailA.l
  EndStructure
  
  Structure Info
    MouseProfile.l
    KeyboardProfile.l
    Precedency.l
    OpenHID.l
    API.INPUT
  EndStructure
  
  Structure MoK
    IO.IO
    HID.HID
    Info.Info
  EndStructure
 
  
  ;}----------------------------------------------------------
  ;-       MouseKey Global
  ;{----------------------------------------------------------
  
  Global MoK.MoK
  
  ;}----------------------------------------------------------
  ;-       MouseKey Declare
  ;{----------------------------------------------------------
  
  Declare.l Precedency(Precedency.l = #Profile0)
  Declare.l Device(cDevice.l = #DeviceHID)
  Declare.l DeviceID(mType.l = #DeviceID)
  Declare.l Mouse(cKey.l = #Left, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  Declare.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  
  ;}----------------------------------------------------------
  ;-       MouseKey Init
  ;{----------------------------------------------------------
  
  
  
  ;}----------------------------------------------------------
EndDeclareModule

Module MoK
  ;-----------------------------------------------------------
  ;-       MouseKey Module -> HID -> Init
  ;{----------------------------------------------------------
  
  Procedure.l _InitHID()
    If MoK\HID\lib_hid = 0 
      MoK\HID\lib_hid = OpenLibrary(#PB_Any, "hid.dll")
      If MoK\HID\lib_setupapi = 0 : MoK\HID\lib_setupapi = OpenLibrary(#PB_Any, "setupapi.dll") : EndIf
      If MoK\HID\lib_hid = 0 Or MoK\HID\lib_setupapi = 0 : ProcedureReturn 0 : EndIf
      MoK\HID\func_HidD_GetHidGuid                  = GetFunction(MoK\HID\lib_hid, "HidD_GetHidGuid")
      MoK\HID\func_HidD_GetAttributes               = GetFunction(MoK\HID\lib_hid, "HidD_GetAttributes")
      MoK\HID\func_SetupDiEnumDeviceInterfaces      = GetFunction(MoK\HID\lib_setupapi, "SetupDiEnumDeviceInterfaces")
      MoK\HID\func_SetupDiEnumDeviceInfo            = GetFunction(MoK\HID\lib_setupapi, "SetupDiEnumDeviceInfo")
      MoK\HID\func_SetupDiGetDeviceInterfaceDetailA = GetFunction(MoK\HID\lib_setupapi, "SetupDiGetDeviceInterfaceDetailA")
      MoK\HID\func_SetupDiGetDeviceInterfaceDetailW = GetFunction(MoK\HID\lib_setupapi, "SetupDiGetDeviceInterfaceDetailW")
    EndIf
    If MoK\HID\lib_hid <> 0 : ProcedureReturn 1 : EndIf
    ProcedureReturn 0
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> HID -> Procedure
  ;{----------------------------------------------------------
  
  Procedure.l _SearchPS2()
    If Not _InitHID() : ProcedureReturn 0 : EndIf
    
    Protected HidGuid.Guid, hDevInfo.l, i.l, Result.l, _isKeyBoard.l, _isMouse.l
    Protected devInfoData.SP_DEVICE_INTERFACE_DATA, DataSize.l
    Protected Dim String.a(100)
    
    devInfoData\cbSize = SizeOf(SP_DEVICE_INTERFACE_DATA)
    
    CallFunctionFast(MoK\HID\func_HidD_GetHidGuid, @HidGuid)
    
    hDevInfo = SetupDiGetClassDevs_(@HidGuid, 0, 0, #DIGCF_PRESENT | #DIGCF_ALLCLASSES)
    
    If hDevInfo = #INVALID_HANDLE_VALUE : ProcedureReturn 0 : EndIf
    For i=0 To 255
      
      Result = CallFunctionFast(MoK\HID\func_SetupDiEnumDeviceInfo, hDevInfo, i, @devInfoData)
      If Result = 0 : Break : EndIf
      SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_DEVICEDESC, 0, @String(0), 100, 0)
      If FindString(PeekS(@String(0), 100, #PB_Unicode), "PS/2") > 0
        If _isKeyBoard = 0 And FindString(PeekS(@String(0), 100, #PB_Unicode), "клавиатура PS/2") > 0 : _isKeyBoard = 1 : EndIf
        If _isMouse = 0 And FindString(PeekS(@String(0), 100, #PB_Unicode), "PS/2 sмышь") > 0 : _isMouse = 1 : EndIf
      EndIf
    Next
    SetupDiDestroyDeviceInfoList_(hDevInfo)
    If _isKeyBoard : Result = #HIDPS2KEYBOARD : EndIf
    If _isMouse : Result = Result | #HIDPS2MOUSE : EndIf
    ProcedureReturn Result
  EndProcedure
  
  Procedure.l _OpenHID()
    If Not _InitHID() : ProcedureReturn 0 : EndIf
    Protected HidGuid.Guid, hDevInfo.l, i.l, Result.l, Required.l, DevicePath.s
    Protected devInfoData.SP_DEVICE_INTERFACE_DATA, DataSize.l
    Protected *detailData.PSP_DEVICE_INTERFACE_DETAIL_DATA, hDevice.l, Security.SECURITY_ATTRIBUTES, Attributes.HIDD_ATTRIBUTES
    
    Security\nLength=SizeOf(SECURITY_ATTRIBUTES)
    Security\bInheritHandle=1
    Security\lpSecurityDescriptor = 0
    
    devInfoData\cbSize = SizeOf(SP_DEVICE_INTERFACE_DATA)
    
    CallFunctionFast(MoK\HID\func_HidD_GetHidGuid, @HidGuid)
    
    hDevInfo = SetupDiGetClassDevs_(@HidGuid, 0, 0, #DIGCF_PRESENT | #DIGCF_DEVICEINTERFACE)
    
    If hDevInfo = #INVALID_HANDLE_VALUE : ProcedureReturn 0 : EndIf
    
    For i=0 To 255
      Result = CallFunctionFast(MoK\HID\func_SetupDiEnumDeviceInterfaces, hDevInfo, 0, @HidGuid, i, @devInfoData)
      If Not Result : Break : EndIf
      Result = CallFunctionFast( MoK\HID\func_SetupDiGetDeviceInterfaceDetailW, hDevInfo, @devInfoData, 0, 0, @DataSize, 0)
      If Not DataSize : Continue : EndIf
      *detailData = AllocateMemory(DataSize)
      *detailData\cbSize = SizeOf(PSP_DEVICE_INTERFACE_DETAIL_DATA)
      Result = CallFunctionFast( MoK\HID\func_SetupDiGetDeviceInterfaceDetailW, hDevInfo, @devInfoData, *detailData, DataSize+1, @Required, 0)
      DevicePath.s=PeekS(@*detailData\DevicePath)
      FreeMemory(*detailData)
      hDevice=CreateFile_(@DevicePath, #GENERIC_READ | #GENERIC_WRITE, #FILE_SHARE_READ| #FILE_SHARE_WRITE, @Security, #OPEN_EXISTING, 0, 0)
      If hDevice = #INVALID_HANDLE_VALUE : Continue : EndIf
      Attributes\Size = SizeOf(HIDD_ATTRIBUTES)
      Result = CallFunctionFast(MoK\HID\func_HidD_GetAttributes , hDevice, @Attributes)
      If Attributes\ProductID = #HID_PID And Attributes\VendorID = #HID_VID
        SetupDiDestroyDeviceInfoList_(hDevInfo)
        If Not MoK\Info\OpenHID
          MoK\Info\OpenHID = hDevice
        Else
          CloseHandle_(hDevice)
        EndIf
        ProcedureReturn 1
      Else
        CloseHandle_(hDevice)
      EndIf
    Next
    SetupDiDestroyDeviceInfoList_(hDevInfo)
    ProcedureReturn 0
  EndProcedure
  
  Procedure.l _ClouseHID()
    If MoK\Info\OpenHID = 0 : ProcedureReturn 0 : EndIf
    CloseHandle_(MoK\Info\OpenHID)
    Precedency(MoK\Info\Precedency)
    MoK\Info\OpenHID = 0;
    ProcedureReturn 1
  EndProcedure
  
  Procedure.l _ReadHID(*Buffer, Len)
    If MoK\Info\OpenHID = 0 : ProcedureReturn 0 : EndIf
    Protected Written.l
    ReadFile_(MoK\Info\OpenHID, *Buffer, Len, @Written, 0)
    ProcedureReturn Written
  EndProcedure

  Procedure.l _WriteHID(*Buffer, Len)
    If MoK\Info\OpenHID = 0 : ProcedureReturn 0 : EndIf
    Protected Written.l
    WriteFile_(MoK\Info\OpenHID, *Buffer, Len, @Written,  0)
    ProcedureReturn Written
  EndProcedure
  
  
  ;}----------------------------------------------------------
  ;-       MouseKey ImportC
  ;{----------------------------------------------------------
  
  ImportC "Bin\memorymodule.lib"
    MemoryLoadLibrary(MemoryPointer)
    MemoryGetProcAddress(hModule, FunctionName.p-ascii)
    MemoryFreeLibrary(hModule)
  EndImport
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Init
  ;{----------------------------------------------------------
  
  Procedure.l _InitIO()
    If MoK\IO\hIO = 0
      MoK\IO\hIO = MemoryLoadLibrary(?IO)
      MoK\IO\Inp32 = MemoryGetProcAddress(MoK\IO\hIO, "Inp32")
      MoK\IO\Out32 = MemoryGetProcAddress(MoK\IO\hIO, "Out32")
      MoK\IO\IsInpOutDriverOpen = CallFunctionFast(MemoryGetProcAddress(MoK\IO\hIO, "IsInpOutDriverOpen"))
    EndIf
    ProcedureReturn MoK\IO\IsInpOutDriverOpen
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Procedure
  ;{----------------------------------------------------------
  
  Procedure.l MouseAdreass(Type.l = 0)
    If Type = 0 : ProcedureReturn PeekL(?MouseType) : EndIf
    ProcedureReturn PeekL(?MouseType + (4 * (Type - 1)))
  EndProcedure
  
  Procedure.l KeyboardAdreass(Type.l = 0)
    If Type = 0 : ProcedureReturn PeekL(?KeyboardType) : EndIf
    ProcedureReturn PeekL(?KeyboardType + (4 * (Type - 1)))
  EndProcedure
  
  Procedure.l MouseTrace(cKey.l, cType.l)
    Select cType
      Case #API
        Select cKey
          Case #Left
            ProcedureReturn #MOUSEEVENTF_LEFTDOWN
          Case #Middle
            ProcedureReturn #MOUSEEVENTF_MIDDLEDOWN
          Case #Right
            ProcedureReturn #MOUSEEVENTF_RIGHTDOWN
        EndSelect
      Case #APIEx
        Select cKey
          Case #Left
            ProcedureReturn #MOUSEEVENTF_LEFTDOWN
          Case #Middle
            ProcedureReturn #MOUSEEVENTF_MIDDLEDOWN
          Case #Right
            ProcedureReturn #MOUSEEVENTF_RIGHTDOWN
        EndSelect
      Case #PS2
        Select Key
          Case #Left
            ProcedureReturn %00001001
          Case #Right
            ProcedureReturn %00001010
          Case #Middle
            ProcedureReturn %00001100
        EndSelect
    EndSelect
    ProcedureReturn cKey
  EndProcedure
  
  Procedure.l MouseDecode(Key.l, Type.l = 0)
    Select Type
      Case #API
        Select Key
          Case #Left
            ProcedureReturn #MOUSEEVENTF_LEFTUP
          Case #Middle
            ProcedureReturn #MOUSEEVENTF_MIDDLEUP
          Case #Right
            ProcedureReturn #MOUSEEVENTF_RIGHTUP
          Case $0080
            ProcedureReturn $0100
        EndSelect
      Case #PS2
        Select Key
          Case #Left
            ProcedureReturn %00001000
          Case #Right
            ProcedureReturn %00001000
          Case #Middle
            ProcedureReturn %00001000
        EndSelect
        ProcedureReturn %00001000
    EndSelect
  EndProcedure
  
  Procedure.l SendInputHID(cType.l, cKey.l, cMethod.l, cParam.l)
    MoK\HID\MouseHID\Mouse\cType    = cType;
    MoK\HID\MouseHID\Mouse\cKey     = cKey;
    MoK\HID\MouseHID\Mouse\cMethod  = cMethod;
    MoK\HID\MouseHID\Mouse\cParam   = cParam;
    
    CopyMemory( @MoK\HID\MouseHID\Mouse, @MoK\HID\MouseHID\hid_size, SizeOf(MouseGreen) )
    
    If Not _WriteHID(@MoK\HID\MouseHID\hid_size, #HID_RX_TX_SIZE - 1)
      _ClouseHID()
      ProcedureReturn 0
    EndIf
    ProcedureReturn 1
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> IO -> PS/2
  ;{----------------------------------------------------------
  
  Procedure PS2SendWaint(Arg.a, Arg2.a)
    If Arg <> $00 And Arg2 <> $00
      CallFunctionFast(MoK\IO\Out32, Arg, Arg2)
    EndIf
    While (CallFunctionFast(MoK\IO\Inp32, $64) & 2)
      !NOP
    Wend
  EndProcedure
  
  Procedure PS2SendClick(send.b, whell.a = 0)
    PS2SendWaint($00, $00)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, send)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, $00)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, $00)
    PS2SendWaint($64, $D3)
    PS2SendWaint($60, whell)
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Mouse
  ;{----------------------------------------------------------
  
  Procedure.l MouseAPI(cKey.l, delay.l, Method.l)
    MoK\Info\API\type = #INPUT_MOUSE
    If Method & #Down
      MoK\Info\API\mi\dwFlags = MouseTrace(cKey, #API)
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      MoK\Info\API\mi\dwFlags = MouseDecode(cKey, #API)
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Whell
      MoK\Info\API\mi\dwFlags = #MOUSEEVENTF_WHEEL
      MoK\Info\API\mi\mouseData = cKey
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Move
      MoK\Info\API\mi\dwFlags = #MOUSEEVENTF_MOVE
      MoK\Info\API\mi\dx = cKey
      MoK\Info\API\mi\dy = delay
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l MouseAPIEx(cKey.l, delay.l, Method.l)
    Protected hWnd = GetDesktopWindow_()
    MoK\Info\API\type = #INPUT_MOUSE
    If Method & #Down
      SetForegroundWindow_(hWnd)
      SetFocus_(hWnd)
      MoK\Info\API\mi\dwFlags = MouseTrace(cKey, #API)
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      SetForegroundWindow_(hWnd)
      SetFocus_(hWnd)
      MoK\Info\API\mi\dwFlags = MouseDecode(cKey, #API)
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Whell
      MoK\Info\API\mi\dwFlags = #MOUSEEVENTF_WHEEL
      MoK\Info\API\mi\mouseData = cKey
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Move
      MoK\Info\API\mi\dwFlags = #MOUSEEVENTF_MOVE
      MoK\Info\API\mi\dx = cKey
      MoK\Info\API\mi\dy = delay
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l MousePS2(cKey.l, delay.l, Method.l)
    If _InitIO() = 0 : ProcedureReturn 0 : EndIf
    If Method & #Down
      PS2SendClick(MouseTrace(cKey, #PS2), 0)
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      PS2SendClick(MouseDecode(cKey, #PS2), 0)
    EndIf
    If Method & #Whell
      PS2SendClick(MouseDecode(cKey, #PS2), 0)
    EndIf
    If Method & #Move
      
    EndIf
  EndProcedure
  
  Procedure.l MouseHID(cKey.l, delay.l, Method.l)
    If Not MoK\Info\OpenHID : ProcedureReturn 0 : EndIf
    If Method & #Down
      SendInputHID(#Mouse, cKey, #Down, 0)
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      SendInputHID(#Mouse, cKey, #Up, 0)
    EndIf
    If Method & #Whell
      SendInputHID(#Mouse, cKey, #Whell, 0)
    EndIf
    If Method & #Move
      SendInputHID(#Mouse, cKey, #Move, delay)
    EndIf
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Keyboard
  ;{----------------------------------------------------------
  
  Procedure.l KeyboardAPI(cKey.l, delay.l, Method.l)
    MoK\Info\API\type = #INPUT_KEYBOARD
    MoK\Info\API\ki\wVk = cKey
    If Method & #Down
      MoK\Info\API\ki\dwFlags = 0
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      MoK\Info\API\ki\dwFlags = #KEYEVENTF_KEYUP
      SendInput_(1, @MoK\Info\API, SizeOf(INPUT))
    EndIf
  EndProcedure
  
  Procedure.l KeyboardAPIEx(cKey.l, delay.l, Method.l)
    ProcedureReturn KeyboardAPI(cKey, delay, Method)
  EndProcedure
  
  Procedure.l KeyboardPS2(cKey.l, delay.l, Method.l)
    If _InitIO() = 0 : ProcedureReturn 0 : EndIf
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
  
  Procedure.l KeyboardHID(cKey.l, delay.l, Method.l)
    If Not MoK\Info\OpenHID : ProcedureReturn 0 : EndIf
    If Method & #Down
      SendInputHID(#Keyboard, cKey, #Down, 0)
    EndIf
    If Method & #Up
      If delay > 0 : Delay(delay) : EndIf
      SendInputHID(#Keyboard, cKey, #Up, 0)
    EndIf
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Is [Function]
  ;{----------------------------------------------------------
  
   
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Declare
  ;{----------------------------------------------------------
  
  Procedure.l Precedency(Precedency.l = #Profile0)
    MoK\Info\MouseProfile          = 0
    MoK\Info\KeyboardProfile       = 0
    MoK\Info\Precedency            = Precedency
    If _OpenHID() <> 0
      MoK\Info\MouseProfile        = #DeviceHID
      MoK\Info\KeyboardProfile     = #DeviceHID
    EndIf
    Select Precedency
      Case #Profile0
        If OSVersion() >= #PB_OS_Windows_10
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #API
          EndIf
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #API
          EndIf
        EndIf
        If _SearchPS2() & #HIDPS2KEYBOARD
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #PS2
          EndIf
        EndIf
        If Not MoK\Info\KeyboardProfile
          MoK\Info\KeyboardProfile     = #APIEx
        EndIf
        If Not MoK\Info\MouseProfile
          MoK\Info\MouseProfile        = #APIEx
        EndIf
      Case #Profile1
        If OSVersion() >= #PB_OS_Windows_10
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #API
          EndIf
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #API
          EndIf
        EndIf
        If _SearchPS2() & #HIDPS2KEYBOARD
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #PS2
          EndIf
        EndIf
        If _SearchPS2() & #HIDPS2MOUSE
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #PS2
          EndIf
        EndIf
        If Not MoK\Info\KeyboardProfile
          MoK\Info\KeyboardProfile     = #APIEx
        EndIf
        If Not MoK\Info\MouseProfile
          MoK\Info\MouseProfile        = #APIEx
        EndIf
      Case #Profile2
        If _SearchPS2() & #HIDPS2KEYBOARD
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #PS2
          EndIf
        EndIf
        If _SearchPS2() & #HIDPS2MOUSE
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #PS2
          EndIf
        EndIf
        If OSVersion() >= #PB_OS_Windows_10
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #API
          EndIf
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #API
          EndIf
        EndIf
        If Not MoK\Info\KeyboardProfile
          MoK\Info\KeyboardProfile     = #APIEx
        EndIf
        If Not MoK\Info\MouseProfile
          MoK\Info\MouseProfile        = #APIEx
        EndIf
      Case #Profile3
        If OSVersion() >= #PB_OS_Windows_10
          If Not MoK\Info\KeyboardProfile
            MoK\Info\KeyboardProfile   = #API
          EndIf
          If Not MoK\Info\MouseProfile
            MoK\Info\MouseProfile      = #API
          EndIf
        EndIf
        If Not MoK\Info\KeyboardProfile
          MoK\Info\KeyboardProfile     = #APIEx
        EndIf
        If Not MoK\Info\MouseProfile
          MoK\Info\MouseProfile        = #APIEx
        EndIf
     Case #Profile4
        If Not MoK\Info\KeyboardProfile
          MoK\Info\KeyboardProfile     = #API
        EndIf
        If Not MoK\Info\MouseProfile
          MoK\Info\MouseProfile        = #API
        EndIf
    EndSelect
    ProcedureReturn MoK\Info\MouseProfile | MoK\Info\KeyboardProfile
  EndProcedure
  
  Procedure.l Mouse(cKey.l = #Left, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
    If Type.l = #PROFILE : Type.l = MoK\Info\MouseProfile : EndIf
    CallFunctionFast(MouseAdreass(Type.l), cKey, delay, Method)
  EndProcedure
  
  Procedure.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
    If Type.l = #PROFILE : Type.l = MoK\Info\KeyboardProfile : EndIf
    CallFunctionFast(KeyboardAdreass(Type.l), cKey, delay, Method)
  EndProcedure
  
  Procedure.l Device(cDevice.l = #DeviceHID)
    Select cDevice
      Case #DeviceHID
        If _OpenHID() : ProcedureReturn 1 : EndIf
      Case #PS2
        ProcedureReturn _SearchPS2()
    EndSelect
    ProcedureReturn 0
  EndProcedure
  
  Procedure.l DeviceID(mType.l = #DeviceID)
    If Not MoK\Info\OpenHID : ProcedureReturn 0 : EndIf
    SendInputHID(#IDentifier, 0, 0, 0)
    Protected KEY._KEY
    If _ReadHID(@KEY, SizeOf(_KEY))
      Select mType
        Case #DeviceID
          ProcedureReturn KEY\ID
        Case #DeviceKey
          ProcedureReturn KEY\Key
        Case #DeviceType
          ProcedureReturn KEY\Type
      EndSelect
    EndIf
    ProcedureReturn 0
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> DataSection
  ;{----------------------------------------------------------
  
  DataSection
    IO:
    IncludeBinary "Bin\IO.s"
    MouseType:
    Data.l @MouseAPI()
    Data.l @MouseAPIEx()
    Data.l @MousePS2()
    Data.l @MouseHID()
    KeyboardType:
    Data.l @KeyboardAPI()
    Data.l @KeyboardAPIEx()
    Data.l @KeyboardPS2()
    Data.l @KeyboardHID()
  EndDataSection
  
  ;}----------------------------------------------------------
EndModule

; #INDEX# =======================================================================================================================
; Compile .........: Компиляция эмулятора в DLL
; ===============================================================================================================================
CompilerIf #PB_Compiler_DLL And Not #PB_Compiler_Debugger
  
  ProcedureDLL.l Precedency(Precedency.l = MoK::#Profile0)
    ProcedureReturn MoK::Precedency(Type.l)
  EndProcedure
  
  ProcedureDLL.l Device(cDevice.l = MoK::#DeviceHID)
    ProcedureReturn MoK::Device(cDevice.l)
  EndProcedure
  
  ProcedureDLL.l Mouse(cKey.l = MoK::#Left, delay.l = 32, Method.l = MoK::#Click, Type.l = MoK::#PROFILE)
    ProcedureReturn MoK::Mouse(cKey.l, delay.l, Method.l, Type.l)
  EndProcedure
  
  ProcedureDLL.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = MoK::#Click, Type.l = MoK::#PROFILE)
    ProcedureReturn MoK::Keyboard(cKey.l, delay.l, Method.l, Type.l)
  EndProcedure
  
CompilerEndIf

; IDE Options = PureBasic 5.60 (Windows - x86)
; ExecutableFormat = Shared dll
; CursorPosition = 736
; FirstLine = 33
; Folding = QIAAAAoQ+
; EnableAsm
; EnableThread
; EnableXP
; EnableOnError
; Executable = Bin\MoK.dll
; CompileSourceDirectory
; EnablePurifier
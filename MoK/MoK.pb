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
  #MoveX          = 3;
  #MoveY          = 4;
  
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
  
  Structure HID
    lib_hid.l
    lib_setupapi.l
    func_GetHidGuid.l
    func_SetupDiEnumDeviceInterfaces.l
    func_SetupDiEnumDeviceInfo.l
  EndStructure
  
  Structure MoK
    IO.IO
    HID.HID
  EndStructure
 
  
  ;}----------------------------------------------------------
  ;-       MouseKey Global
  ;{----------------------------------------------------------
  
  Global MoK.MoK
  
  ;}----------------------------------------------------------
  ;-       MouseKey Declare
  ;{----------------------------------------------------------
  

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
      MoK\HID\func_GetHidGuid                       = GetFunction(MoK\HID\lib_hid, "HidD_GetHidGuid")
      MoK\HID\func_SetupDiEnumDeviceInterfaces      = GetFunction(MoK\HID\lib_setupapi, "SetupDiEnumDeviceInterfaces")
      MoK\HID\func_SetupDiEnumDeviceInfo            = GetFunction(MoK\HID\lib_setupapi, "SetupDiEnumDeviceInfo")
    Else
      ProcedureReturn 0
    EndIf
    ProcedureReturn 1
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> HID -> Procedure
  ;{----------------------------------------------------------
  
  Procedure.l _SearchPS2()
    If Not _InitHID() : ProcedureReturn 0 : EndIf
    
    Protected HidGuid.Guid, hDevInfo.l, i.l, Result.l, _isKeyBoard.l
    Protected devInfoData.SP_DEVICE_INTERFACE_DATA, DataSize.l
    Protected Dim String.a(100)
    
    devInfoData\cbSize = SizeOf(SP_DEVICE_INTERFACE_DATA)
    
    CallFunctionFast(MoK\HID\func_GetHidGuid, @HidGuid)
    
    hDevInfo = SetupDiGetClassDevs_(@HidGuid,0,0, #DIGCF_PRESENT | #DIGCF_ALLCLASSES)
    
    If hDevInfo = #INVALID_HANDLE_VALUE : ProcedureReturn 0 : EndIf
    For i=0 To 255
      
      Result = CallFunctionFast(MoK\HID\func_SetupDiEnumDeviceInfo, hDevInfo, i, @devInfoData)
      If Result = 0 : Break : EndIf
      SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_DEVICEDESC, 0, @String(0), 100, 0)
      
      
      If FindString(PeekS(@String(0), 100, #PB_Unicode), "PS/2") > 0
        If _isKeyBoard = 0 And FindString(PeekS(@String(0), 100, #PB_Unicode), "клавиатура PS/2") > 0 : _isKeyBoard = 1 : EndIf
        If _isKeyBoard = 0 And FindString(PeekS(@String(0), 100, #PB_Unicode), "PS/2 мышь") > 0 : _isKeyBoard = 1 : EndIf
        PrintN("-----------------")
        PrintN("SPDRP_DEVICEDESC =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_FRIENDLYNAME, 0, @String(0), 100, 0)
        PrintN("SPDRP_FRIENDLYNAME =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_LOCATION_INFORMATION, 0, @String(0), 100, 0)
        PrintN("SPDRP_LOCATION_INFORMATION =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_HARDWAREID, 0, @String(0), 100, 0)
        PrintN("SPDRP_HARDWAREID =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_LOCATION_PATHS, 0, @String(0), 100, 0)
        PrintN("SPDRP_LOCATION_PATHS =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_LOWERFILTERS, 0, @String(0), 100, 0)
        PrintN("SPDRP_LOWERFILTERS =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_MFG, 0, @String(0), 100, 0)
        PrintN("SPDRP_MFG =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_PHYSICAL_DEVICE_OBJECT_NAME, 0, @String(0), 100, 0)
        PrintN("SPDRP_PHYSICAL_DEVICE_OBJECT_NAME =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_SECURITY_SDS, 0, @String(0), 100, 0)
        PrintN("SPDRP_SECURITY_SDS =" + PeekS(@String(0), 100, #PB_Unicode))
        
        SetupDiGetDeviceRegistryProperty_(hDevInfo, @devInfoData, #SPDRP_SERVICE, 0, @String(0), 100, 0)
        PrintN("SPDRP_SERVICE =" + PeekS(@String(0), 100, #PB_Unicode))
      EndIf
    Next
    SetupDiDestroyDeviceInfoList_(hDevInfo)

  EndProcedure
  OpenConsole()
  _SearchPS2()
  Input()
   
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Init
  ;{----------------------------------------------------------
  

  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Mouse
  ;{----------------------------------------------------------
  
  
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Keyboard
  ;{----------------------------------------------------------
  
  
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Is [Function]
  ;{----------------------------------------------------------
  

  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> Declare
  ;{----------------------------------------------------------
  
  
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> DataSection
  ;{----------------------------------------------------------
  
  DataSection
    IO:
    IncludeBinary "Bin\IO.s"
  EndDataSection
  
  ;}----------------------------------------------------------
EndModule



; HID::HID_Init()
; Delay(3000)
; MoK::Mouse(MoK::#Left, 64, MoK::#Click, MoK::#HID)
; Delay(32)
; MoK::Keyboard(#VK_3, 32, MoK::#Click, MoK::#HID)
; Delay(32)
; MoK::Keyboard(#VK_1, 32, MoK::#Click, MoK::#HID)

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 177
; FirstLine = 171
; Folding = ----
; EnableAsm
; EnableThread
; EnableXP
; EnableOnError
; Executable = Bin\MoK.dll.exe
; CompileSourceDirectory
; EnablePurifier
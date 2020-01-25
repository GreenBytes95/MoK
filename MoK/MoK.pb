; #INDEX# =======================================================================================================================
; Title .........: MouseKey
; Version .......: 3.0
; Language ......: Русский
; Description ...: Функции для работы с эмуляцией кнопок мыши и клавиатуры.
; Author ........: GreenBytes ( https://vk.com/greenbytes )
; Dll ...........: win32u.dll, user32.dll, inpout32.dll
; ===============================================================================================================================
XIncludeFile "..\USB\USB.pb"

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
  #DeviceHID      = 3;
  
  #Profile0       = 0;
  #Profile1       = 1;
  #Profile2       = 2;
  #Profile3       = 3;
  
  #Mouse          = 1;
  #Keyboard       = 2;
  
  #HID_KEY        = $FF
  #HID_PID        = $8036;
  #HID_VID        = $2341;
  
  #HID_RX_TX_SIZE = 128 + 2;
  
  #IDentifier     = 240
  
  #DeviceID       = 0
  #DeviceKey      = 1
  #DeviceType     = 2
  
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
  
  Structure MouseGreen
    cNOP.a
    cType.a
    cKey.l
    cMethod.l
    cParam.l
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
    MouseHID.MouseGreen
    *USB.USB::USB
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
  Declare.l Device()
  Declare.l Mouse(cKey.l = #Left, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  Declare.l Keyboard(cKey.l = #VK_SPACE, delay.l = 32, Method.l = #Click, Type.l = #PROFILE)
  
  ;}----------------------------------------------------------
  ;-       MouseKey Init
  ;{----------------------------------------------------------
  
  USB::Init()
  
  ;}----------------------------------------------------------
EndDeclareModule

Module MoK
  ;-----------------------------------------------------------
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
    EndSelect
  EndProcedure
  
  Procedure.l SendInputHID(cType.l, cKey.l, cMethod.l, cParam.l)
    MoK\MouseHID\cType    = cType;
    MoK\MouseHID\cKey     = cKey;
    MoK\MouseHID\cMethod  = cMethod;
    MoK\MouseHID\cParam   = cParam;
    
    ProcedureReturn USB::Run(MoK\USB, $A0, @MoK\MouseHID, SizeOf(MouseGreen))
  EndProcedure
  
  Procedure.l OpenUSB()
    If MoK\USB <> 0
      If USB::GetKey(MoK\USB) = #HID_KEY
        ProcedureReturn 1
      Else
        USB::Close(MoK\USB)
      EndIf
    EndIf
    
    MoK\USB = USB::Device(#HID_KEY, #HID_PID, #HID_VID, USB::#TX, USB::#RX)
    If MoK\USB = 0 : ProcedureReturn 0 : EndIf
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
    If OpenUSB() <> 0
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
      Case #Profile1
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
      Case #Profile2
        MoK\Info\KeyboardProfile   = #API
        MoK\Info\MouseProfile      = #API
      Case #Profile3
        MoK\Info\KeyboardProfile   = #APIEx
        MoK\Info\MouseProfile      = #APIEx
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
  
  Procedure.l Device()
    If OpenUSB() = 1
      Precedency(MoK\Info\Precedency)
      ProcedureReturn 1
    EndIf
    ProcedureReturn 0
  EndProcedure
  
  ;}----------------------------------------------------------
  ;-       MouseKey Module -> DataSection
  ;{----------------------------------------------------------
  
  DataSection
    MouseType:
    Data.l @MouseAPI()
    Data.l @MouseAPIEx()
    Data.l @MouseHID()
    KeyboardType:
    Data.l @KeyboardAPI()
    Data.l @KeyboardAPIEx()
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

; IDE Options = PureBasic 5.50 (Windows - x86)
; ExecutableFormat = Shared dll
; CursorPosition = 99
; Folding = RBAAAw
; EnableAsm
; EnableThread
; EnableXP
; EnableOnError
; Executable = Bin\MoK.dll
; CompileSourceDirectory
; EnablePurifier
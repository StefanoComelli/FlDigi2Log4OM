; *****************
; * FlDigi2Log4OM *
; * v1.0.0        *
; * © IZ3XNJ      *
; *****************

; +------+
; | Main |
; +------+
	#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
	#Warn ; Enable warnings to assist with detecting common errors. To use only in debug
	SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
	#Persistent ; only one copy running allowed

    ; config
	gosub, F2L_Config

	; set up icon
	Menu, Tray, Icon, FlDigi2Log4OM.ico

	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, FlDigi -> Log4OM v1.0.0 %yourCall%
	Sleep, 2000
	SplashTextOff

	; TrayTip
	TrayTip, FlDigi-> Log4OM, FlDigi -> Log4OM © IZ3XNJ, 10, 17

	; setup
	gosub, F2L_Setup

	if !F2L_IsAppRunning(true)
		ExitApp
	else
	{
		; start
		gosub, F2L_setupComm
		
		; events
		OnClipboardChange("F2L_ClipChanged")
		OnExit, F2L_End
		
		; timer
		SetTimer, F2L_CtrlApps, 5000
	}
return

; +-----------+
; | F2L_Setup |
; +-----------+
F2L_Setup:
	; forced windows activation
	#WinActivateForce 
	; the window's title must start with the specified WinTitle to be a match
	SetTitleMatchMode, 1
	; invisible windows are "seen" by the script
	DetectHiddenWindows, On 

	; setup control's name
	lblLog4OM = Log4OM [User Profile:
	lblCommunicator = Log4OM Communicator
	lblFldigi = fldigi ver
	ctrlCall = WindowsForms10.EDIT.app.0.1b0ed41_r12_ad13
	ctrlOutbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad13
	ctrlInbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad13
	ctrlTab = WindowsForms10.SysTabControl32.app.0.1b0ed41_r12_ad12
return

; +------------+
; | F2L_Config |
; +------------+
F2L_Config:
	; read from FlDigi2Log4OM.ini
	; yourCall
	IniRead, yourCall, FlDigi2Log4OM.ini, config, yourCall, NOCALL
return

; +---------------+
; | F2L_setupComm |
; +---------------+
F2L_setupComm:
	; setup Log4oM communicator
	; bring it to front
	WinActivate, %lblCommunicator%

	; click Inbound & outbound buttons
	ControlClick, %ctrlOutbound%, %lblCommunicator%
	ControlClick, %ctrlInbound%, %lblCommunicator%

	; minimize Log4oM communicator
	WinMinimize, %lblCommunicator%
return

; +---------+
; | F2L_End |
; +---------+
F2L_End:
	; delete timer
	SetTimer, F2L_CtrlApps, Delete 
	ExitApp
return

; +--------------+
; | F2L_CtrlApps |
; +--------------+
F2L_CtrlApps:
if !F2L_IsAppRunning(false)
	goto F2L_End
return

; +------------------+
; | F2L_IsAppRunning |
; +------------------+
F2L_IsAppRunning(bMsg)
{
	global
	
	; suspend timer
	SetTimer, F2L_CtrlApps, Off 
	
	; check if needed Apps are running
	
	; check if FlDigi is running
	IfWinNotExist, %lblFldigi%
	{
		if (bMsg)
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, FlDigi not running
		return false
	}
	else
		; check Log4OM running
		IfWinNotExist, Log4OM Communicator
		{
			if (bMsg)
				MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Log4OM not running
			return false
		}	
		
	; restart timer
	SetTimer, F2L_CtrlApps, On 

	return true
}

; +-----------------;
; | F2L_ClipChanged |
; +-----------------;
F2L_ClipChanged(Type) 
{
	global 
	local callsign

	; suspend timer
	SetTimer, F2L_CtrlApps, Off 
	
	; this event raise up when clipoard changes
	;  type = 1  means clipboard contains something that can be expressed as text 
	; (this includes files copied from an Explorer window)
	if Type = 1
	{
		; convert to upper case
		callsign = %clipboard%
		StringUpper, callsign, callsign
		
		; check if the text in clipboard could be a callsign
		if F2L_isCallsign(callsign)
		{			
			; activates the window  and makes it foremost
			WinActivate, %lblLog4OM% 
			
			; read prevoius call
			ControlGetText, prevCall, %ctrlCall%, %lblLog4OM%  
			
			; only if different
			if (prevCall != callsign)
			{	
				; tray
				TrayTip, FlDigi -> Log4OM, %callsign%, 40, 17
				
				; click CLR button to clear previous call
				ControlClick, CLR, %lblLog4OM% 
				
				; copy clipboard to the Callsign field
				ControlSetText, %ctrlCall%, %callsign%, %lblLog4OM%  
			}
			
			; QSO Information tab {F7} -> Push QSO Information Tab
			ControlSend, %ctrlTab%, {F7}, %lblLog4OM%  
		}
	}
	
	; restart timer
	SetTimer, F2L_CtrlApps, On 

	return
}

; +----------------+
; | F2L_isCallsign |
; +----------------+
F2L_isCallsign(call)
{
	global yourCall

	; check if the text in clipboard could be a callsign
	
	; if the clipboard contains tabs or spaces, is not a callsign
	if call contains  %A_Space%, %A_Tab%
		return false
	
	; if it is too long or too short, is not a callsign
	if (StrLen(call) > 13 or StrLen(call) < 3)
		return false
	
	; if it is your call, I doubt you are doing a QSO with yourself
	if (call == yourCall)
		return false
	
	return true
}
; *****************
; * FlDigi2Log4OM *
; * v3.0.0        *
; * © IZ3XNJ      *
; *****************

; +------+
; | Main |
; +------+

	#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
	;#Warn ; Enable warnings to assist with detecting common errors. To use only in debug
	SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
	#Persistent ; only one copy running allowed
	
	version := "3.0.0"
    
	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, FlDigi -> Log4OM`nv%version%
	
	Sleep, 2000
	SplashTextOff

	; setup tray menu
	Gosub, SetupTrayMenu

	; setup
	gosub, F2L_Setup

	; config
	gosub, F2L_Config

	if !F2L_IsAppRunning(true)
		ExitApp
	else
	{
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

return

; +------------+
; | F2L_Config |
; +------------+
F2L_Config:

		; activates the window  and makes it foremost
		WinActivate, %lblLog4OM% 
		
		; click CLR button to clear previous call if necessary
		ControlClick, CLR, %lblLog4OM%		
		
		; send a stringl
		SendInput {Raw}XNJ
		
		; wait a moment
		Sleep 1000
		
		; read same string to detect control id
		clsNNCall := GetLog4OmCtrl("XNJ")
		if (clsNNCall = "")
		{
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, FlDigi -> Log4OM © IZ3XNJ`nErrore clsNNCall
			ExitApp
		}	
		
		; click CLR button to clear string from callsign field
		ControlClick, CLR, %lblLog4OM%		

		; clsNNTab
		clsNNTab := GetLog4OmCtrl("QSO Information (F7)")
		if (clsNNTab = "")
		{
			MsgBox, 16, digiLog4OM © IZ3XNJ, Error in clsNNTab
			ExitApp
		}

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
	; type = 1  means clipboard contains something that can be expressed as text 
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
			ControlGetText, prevCall, %clsNNCall%, %lblLog4OM%  

			; only if different
			if (prevCall != callsign)
			{	
				; tray
				TrayTip, FlDigi -> Log4OM, %callsign%, 40, 17
				
				; click CLR button to clear previous call
				ControlClick, CLR, %lblLog4OM% 
				
				; copy clipboard to the Callsign field
				ControlSetText, %clsNNCall%, %callsign%, %lblLog4OM% 
			}
			
			; QSO Information tab {F7} -> Push QSO Information Tab
			ControlSend, %clsNNTab%, {F7}, %lblLog4OM%  
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

	; check if the text in clipboard could be a callsign
	
	; if the clipboard contains tabs or spaces, is not a callsign
	if call contains  %A_Space%, %A_Tab%
		return false
	
	; if it is too long or too short, is not a callsign
	if (StrLen(call) > 13 or StrLen(call) < 3)
		return false
	
	return true
	
}

; +---------------+
; | GetLog4OmCtrl |
; +---------------+
GetLog4OmCtrl(txtLbl)
{
	
	local hwnd
	local controls 
	local txtRead
	
	hWnd := WinExist(lblLog4OM)

	; retrieve all controls in the main window
	WinGet, controls, ControlListHwnd, Log4OM [User Profile:

	; for each control
	Loop, Parse, controls, `n
	{
		; retrieve text from control
		ControlGetText, txtRead,, ahk_id %A_LoopField%
		if (txtRead = txtLbl)
		{
			ctrlName := Control_GetClassNN(hWnd, A_LoopField) 
			break
		}
	}
	
	return ctrlName
	
}

; +--------------------+
; | Control_GetClassNN |
; +--------------------+
Control_GetClassNN(hWnd, hCtrl) 
{
	
	; SKAN: www.autohotkey.com/forum/viewtopic.php?t=49471
	WinGet, CH, ControlListHwnd, ahk_id %hWnd%
	WinGet, CN, ControlList, ahk_id %hWnd%
	Clipboard := CN
	LF:= "`n",  CH:= LF CH LF, CN:= LF CN LF,  S:= SubStr( CH, 1, InStr( CH, LF hCtrl LF ) )
	StringReplace, S, S,`n,`n, UseErrorLevel
	StringGetPos, P, CN, `n, L%ErrorLevel%

	Return SubStr( CN, P+2, InStr( CN, LF, 0, P+2 ) -P-2 )

}

; +---------------+
; | SetupTrayMenu |
; +---------------+
SetupTrayMenu:

	; TrayTip
	TrayTip, FlDigi-> Log4OM, FlDigi -> Log4OM © IZ3XNJ, 10, 17

	; set tray Icon  & menues
	Menu, Tray, Icon, FlDigi2Log4OM.ico
	menu, Tray, NoStandard
	
	Menu, Tray, Add, About..., about
	Menu, Tray, Add, Exit, F2L_End
	
return

; +-------+
; | about |
; +-------+
about:

	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, digiLog4OM`nv%version% %yourCall% - %mode%
	Sleep, 2000
	SplashTextOff
	
return
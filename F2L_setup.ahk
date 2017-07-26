; *****************
; * F2L_setup     *
; * FlDigi2Log4OM *
; * v2.0.0        *
; * © IZ3XNJ      *
; *****************


; +------+
; | Main |
; +------+
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	#Warn  ; Recommended for catching common errors.
	SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	#SingleInstance, Force
	#Persistent

	; forced windows activation
	#WinActivateForce 
	; the window's title must start with the specified WinTitle to be a match
	SetTitleMatchMode, 1
	; invisible windows are "seen" by the script
	DetectHiddenWindows, On
	
	vVersion := "2.0.0"
	lblLog4OM = Log4OM [User Profile:
	
	; set up icon
	Menu, Tray, Icon, FlDigi2Log4OM.ico

	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, FlDigi -> Log4OM Setup`nv%vVersion%
	Sleep, 2000
	SplashTextOff

	; check Log4OM running
	IfWinNotExist, Log4OM Communicator
	{
		MsgBox, 16, Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nLog4OM not running
		ExitApp
	}	

	InputBox, yourCall , FlDigi -> Log4OM Setup v%vVersion%, Setup FlDigi -> Log4OM © IZ3XNJ`nYour Callsign?
	if (yourCall="")
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nNo Callsign entered
		ExitApp
	}
	
	flgCallsignOk := false
	flgTabOk := false
	
	StringUpper, yourCall, yourCall
	; yourCall
	IniWrite, %yourCall%, FlDigi2Log4OM.ini, config, yourCall
	
	MsgBox, 32, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nWrite your own callsign %yourCall% into Log4OM callsign field`nand then click OK here
	
	hWnd := WinExist(lblLog4OM)

	; retrieve all controls in the main window
	WinGet, controls, ControlListHwnd, Log4OM [User Profile:
	
	; for each control
	Loop, Parse, controls, `n
	{

		; retrieve text from control
		ControlGetText, txtRead,,  ahk_id %A_LoopField%
		
		if (txtRead = yourCall)
		{
			; this is callsign field, as it contains  your call sign
			MsgBox, 64, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nCallsign field OK
			flgCallsignOk := true
			; clsNNCall
			clsNNCall := Control_GetClassNN(hWnd, A_LoopField) 
			IniWrite, %clsNNCall%, FlDigi2Log4OM.ini, config, clsNNCall
		}

		if (txtRead = "QSO Information (F7)")
		{
			; this is Tab 
			MsgBox, 64, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nTab OK
			flgTabOk := true
			; clsNNTab
			clsNNTab := Control_GetClassNN(hWnd, A_LoopField) 
			IniWrite, %clsNNTab%, FlDigi2Log4OM.ini, config, clsNNTab
		}
	}

	if (flgCallsignOk and flgTabOk)
		MsgBox, 64, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nSetup Ok
	else
	{
		if (!flgCallsignOk)
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nSetup Callsign KO

		if (!flgTabOk)
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Setup FlDigi -> Log4OM © IZ3XNJ`nSetup Tab KO
	}

	ExitApp
return

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

; *****************
; * FlDigi2Log4OM *
; * v3.0.0        *
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
	
	#Include Class_SQLiteDB.ahk

	version := "3.0.0"
    
	; config
	Gosub, F2L_Config

	; setup tray menu
	Gosub, SetupTrayMenu

	; show about splash screen
	Gosub, about
	
	; TrayTip
	TrayTip, FlDigi-> Log4OM, FlDigi -> Log4OM © IZ3XNJ, %traySecs%, 17

	; setup
	gosub, F2L_Setup

	if !F2L_IsAppRunning(true)
		ExitApp
	else
	{
		; start
		Gosub, StartDB
		Gosub, F2L_setupComm
		
		if (autoSound = "Y")
			Gosub, SetupAudio
	
		Gosub, StartOmniRig
		
		; events
		OnClipboardChange("F2L_ClipChanged")
		OnExit, F2L_End
		
		; timer
		SetTimer, F2L_CtrlApps, 5000
		
		; read frequency for the first time
		if (autoSound = "Y")
			Gosub, ReadFreq
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
	ctrlOutbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad13
	ctrlInbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad12
return

; +------------+
; | F2L_Config |
; +------------+
F2L_Config:
	; read from FlDigi2Log4OM.ini
	
	; [config]
	
	; yourCall
	IniRead, yourCall, FlDigi2Log4OM.ini, config, yourCall, UNDEF_INI
	if (yourCall = "UNDEF_INI")
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nyourCall
		ExitApp
	}
	
	; clsNNCall
	IniRead, clsNNCall, FlDigi2Log4OM.ini, config, clsNNCall, UNDEF_INI
	if (clsNNCall = "UNDEF_INI")
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nclsNNCall
		ExitApp
	}

	; clsNNTab
	IniRead, clsNNTab, FlDigi2Log4OM.ini, config, clsNNTab, UNDEF_INI
	if (clsNNTab = "UNDEF_INI")
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nclsNNTab
		ExitApp
	}
	
	;traySecs
	IniRead, traySecs, FlDigi2Log4OM.ini, config, traySecs, UNDEF_INI
	if (traySecs = "UNDEF_INI")
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`ntraySecs
		ExitApp
	}
	
	; [sound]
	
	; autoSound
	IniRead, autoSound, FlDigi2Log4OM.ini, sound, autoSound, N

	if (autoSound = "Y")
	{
		; soundCard
		IniRead, soundCard, FlDigi2Log4OM.ini, sound, soundCard, UNDEF_INI
		if (soundCard = "UNDEF_INI")
		{
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nsoundCard
			ExitApp
		}
		
		; volStep
		IniRead, volStep, FlDigi2Log4OM.ini, sound, volStep, UNDEF_INI
		if (volStep = "UNDEF_INI")
		{
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nvolStep
			ExitApp
		}
	
		; autoMax
		IniRead, autoMax, FlDigi2Log4OM.ini, sound, autoMax, N

		; volDisplayTime
		IniRead, volDisplayTime, FlDigi2Log4OM.ini, sound, volDisplayTime, UNDEF_INI
		if (volStep = "UNDEF_INI")
		{
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nvolDisplayTime
			ExitApp
		}

	}

	; [autoSpot]
	
	; autoSpot
	IniRead, autoSpot, FlDigi2Log4OM.ini, spot, autoSpot, N

	if (autoSpot = "Y")
	{
		; sweetSpot
		IniRead, sweetSpot, FlDigi2Log4OM.ini, spot, sweetSpot, UNDEF_INI
		if (sweetSpot = "UNDEF_INI")
		{
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, Error in FlDigi2Log4OM.ini`nsweetSpot
			ExitApp
		}
	}
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
	Gosub, StopOmniRig

	; delete timer
	SetTimer, F2L_CtrlApps, Delete 
	ExitApp
return

; +--------------+
; | F2L_CtrlApps |
; +--------------+
F2L_CtrlApps:
if !F2L_IsAppRunning(false)
	Goto F2L_End
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
	if (Type = 1)
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
				TrayTip, FlDigi -> Log4OM, %callsign%, %traySecs%, 17
				
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

; +------------;
; | SetupAudio |
; +------------;
SetupAudio:
	maxVol := 0
	defVol := 0
	SoundGetWaveVolume, vol_Wave, %soundCard%
	; volume up & down via mouse wheel
	HotKey, WheelUp, volUp       
	HotKey, WheelDown, volDown
	Hotkey, LButton, showVol
return

; +---------+
; | showVol |
; +---------+
showVol:
	; mouse left only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundGetWaveVolume, vol_Wave, %soundCard%
	Gosub, SetSoundInfo
return
; +-------+
; | volUp |
; +-------+
volUp:
	; mouse wheel only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundSetWaveVolume, +%volStep%, %soundCard%
	SoundGetWaveVolume, vol_Wave, %soundCard%
	Gosub, FixVol
	Gosub, SetSoundInfo
return

; +---------+
; | volDown |
; +---------+
volDown:
	; mouse wheel only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundSetWaveVolume, -%volStep%, %soundCard%
	SoundGetWaveVolume, vol_Wave, %soundCard%
	Gosub, FixVol
	Gosub, SetSoundInfo
return

; +----------------------------+
; | OmniRigEngine_ParamsChange |
; +----------------------------+
OmniRigEngine_ParamsChange(RigNumber, Params)
{
	; triggered when radio change via Omnirig
	Gosub, ReadFreq
}

; +----------+
; | ReadFreq |
; +----------+
ReadFreq:
	; read rx frequency
	freq := Rig.GetRxFrequency / 1000
	; if on TX, rx frequency is 0, so read from tx fequency
	if (freq = 0)
			freq := Rig.GetTxFrequency / 1000	
	; which band ?
	nBand := GetBand(freq)

	; is band changed?
	if (nBand <> band)
	{
		band := nBand
		if (autoSound = "Y")
		{
			maxVol := GetMaxVol(band)
			defVol := GetDefVol(band)
			vol_Wave := defVol
			Gosub, FixVol
			Gosub, SetSoundInfo
		}
	}
return

; +--------+
; | FixVol |
; +--------+
FixVol:
	; set audio level to the max allowed per band 
	if (autoMax = "Y" and vol_Wave > maxVol)
	{
		vol_Wave := maxVol
		SoundSetWaveVolume, %vol_Wave%, %soundCard%
	}
return

; +---------+
; | GetBand |
; +---------+
GetBand(vFreq)
{
	; retrieve band by frequency
	global audioData
	
	vBand = NO_HAM
	for index, element in audioData
		if (element.isInBand(vFreq))
		{
			vBand := element.band
			break
		}
	return vBand
}

; +-----------+
; | GetMaxVol |
; +-----------+
GetMaxVol(vBand)
{
	; retrieve default audio level for band
	global audioData
	
	vMaxVol := 0
	for index, element in audioData
		if (element.band = vBand)
		{
			vMaxVol := element.Maxlevel
			break
		}
	return vMaxVol
}

; +-----------+
; | GetDefVol |
; +-----------+
GetDefVol(vBand)
{
	; retrieve default audio level for band
	global audioData
	
	vDefVol := 0
	for index, element in audioData
		if (element.band = vBand)
		{
			vMaxVol := element.defLevel
			break
		}
	return vDefVol
}

; +-------------+
; | StopOmniRig |
; +-------------+
StopOmniRig:
	; stop OmniRig engine
	Rig := ""
	OmniRigEngine := ""
return

; +--------------+
; | StartOmniRig |
; +--------------+
StartOmniRig:
	; start OmniRig engine
	OmniRigEngine := ComObjCreate("OmniRig.OmniRigX") 
	Rig := OmniRigEngine.Rig1
	freq := 0
	band := 0
	
	; goes in PM_DIG_U = 134217728 (&H8000000)
	Rig.Mode := 134217728 
	
	; Connects events to corresponding script functions with the prefix "OmniRigEngine_".
	ComObjConnect(OmniRigEngine, "OmniRigEngine_")
	
	Gosub, ReadFreq	
return

; +--------------+
; | SetSoundInfo |
; +--------------+
SetSoundInfo:
	; display sound infos
	if (autoSound = "Y")
	{
		sFreq := Format("{1:0.2f}",freq)
		SoundGetWaveVolume, vol_Wave, %soundCard%
		sWave := Format("{1:0.0f}", vol_Wave)
		sMaxWave := Format("{1:0.0f}", maxVol)
		Progress, 1:%vol_Wave%, (%sWave%`% - %sMaxWave%`%), %sFreq%,  FlDigi -> Log4OM
		SetTimer, vol_BarOff, %volDisplayTime%
	}
return

; +---------+
; | StartDB |
; +---------+
StartDB:
; open connection to SQLITE db
	global MyDb
	
	MyDB := New SQLiteDB
	DBFileName := A_ScriptDir . "\FlDigi2Log4OM.sqlite"
	If !MyDB.OpenDB(DBFileName) 
	{
		MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, % "StartDB:`t" . MyDB.ErrorMsg . "`nCode:`t" . MyDB.ErrorCode
		ExitApp
	}
	Gosub, readDB
	Gosub, StopDB
return

; +--------+
; | StopDB |
; +--------+
StopDB:
	; close connection to DB
	global MyDb
	MyDB.CloseDB()
return

; +---------+
; | setSpot |
; +---------+
setSpot:
	; set sweet spot frequency
	if (autoSpot="Y")
	{
		InputBox, spotFreq , FlDigi QSY, Frequency
		if (spotFreq > sweetSpot / 1000)
		{
			newFreq := spotFreq * 1000 - sweetSpot		
			Rig.SetSimplexMode(newFreq)
		}
	}
return

; +------------+
; | ChangeFreq |
; +------------+
ChangeFreq(delta)
{
	; shift frequency from actual adding delta
	global Rig
	
	dFreq := Rig.GetRxFrequency + delta
	Rig.SetSimplexMode(dFreq)
}

; +-------+
; | oneUp |
; +-------+
oneUp:
	; change frequency one kHz up
	ChangeFreq(1000)
return

; +---------+
; | oneDown |
; +---------+
oneDown:
	; change frequency one kHz down
	ChangeFreq(-1000)
return

; +---------------+
; | SetupTrayMenu |
; +---------------+
SetupTrayMenu:
	; set tray Icon  & menues
	Menu, Tray, Icon, FlDigi2Log4OM.ico
	menu, Tray, NoStandard
	
	if (autoSpot="Y")
	{
		Menu, Tray, Add, Fldigi QSY, setSpot
		Menu, Tray, Add, <=, oneUp
		Menu, Tray, Add, =>, oneDown
	}
	Menu, Tray, Add, ReRead Ini, ReReadIni
	Menu, Tray, Add, About..., about
	Menu, Tray, Add, Exit, F2L_End
return

; +-------------+
; | MouseIsOver |
; +-------------+
MouseIsOver(WinTitle) 
{
	; detect if winndow is over a specified window
    MouseGetPos,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}

; +--------+
; | readDB |
; +--------+
readDB:
	; read audio per band info from database to memory table
	audioData := Object()
	tSQL = SELECT band, startFreq, endFreq, maxLevel, defLevel FROM tblAudioBand; 

	If (!MyDB.GetTable(tSQL, result))
			MsgBox, 16, FlDigi -> Log4OM © IZ3XNJ, %  "readDB:`t" . MyDB.ErrorMsg . "`nCode:`t" . MyDB.ErrorCode
	
	If (result.HasRows) 
		If (result.Next(tRow) = 1) 
			Loop 
			{
				dBand := new AudioBand()
				dBand.band := tRow[1]
				dBand.startFreq := tRow[2]
				dband.endFreq := tRow[3]
				dBand.maxLevel := tRow[4]
				dBand.defLevel := tRow[4]
				audioData.Insert(dBand)
				tRC := result.Next(tRow)
			} 
			Until (tRC < 1)
return

; +-------+
; | about |
; +-------+
about:
	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, FlDigi -> Log4OM`nv%version% %yourCall%
	Sleep, 2000
	SplashTextOff
return

; +-----------+
; | AudioBand |
; +-----------+
Class AudioBand
{
	; Class used for audio leve per band info
	band := ""
	startFreq := 0
	endFreq := 0
	maxLevel := 0
	defLevel := 0
	
	; +----------+
	; | isInBand |
	; +----------+
	isInBand(freq)
	{
		if (freq >= this.startFreq and freq <= this.endFreq)
			return true
		else
			return false
	}
}

; +------------+
; | vol_BarOff |
; +------------+
vol_BarOff:
	; disale OSD timer
	SetTimer, vol_BarOff, off
	; close OSD
	Progress, 1:Off
return

; +-----------+
; | ReReadIni |
; +-----------+
ReReadIni:
	; splash
	SplashTextOn, 200, 50, FlDigi -> Log4OM © IZ3XNJ, ReReadIni
	Sleep, 1000
	SplashTextOff

	; config
	Gosub, F2L_Config

	; setup tray menu
	Gosub, SetupTrayMenu

	; show about splash screen
	Gosub, about
return
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>

Func ShowSettings()
	If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")
	; Global $stashBrowser, $stashFilePath
	Local $sBrowser
	Local $Settings = GUICreate("Settings",801,726,-1,-1,-1,-1)
	GUICtrlCreateLabel("Boss Coming Key: Ctrl + Enter"&@crlf&"Hit this key combination will immediately close the Stash browser.",100,40,574,127,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	
	GUICtrlCreateLabel("Stash-win.exe location:",100,235,299,37,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$stashPath = GUICtrlCreateInput($stashFilePath,100,286,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	$btnBrowse = GUICtrlCreateButton("Browse",600,280,142,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	GUICtrlCreateGroup("Preferred Browser",100,357,442,286,$BS_CENTER,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$chooseFirefox = GUICtrlCreateRadio("Firefox",169,430,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	$updateFirefox = GUICtrlCreateButton("Update",380,438,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	$chooseChrome = GUICtrlCreateRadio("Chrome",169,492,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	$updateChrome = GUICtrlCreateButton("Update",380,498,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	$chooseEdge = GUICtrlCreateRadio("MS Edge",169,560,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$updateEdge = GUICtrlCreateButton("Update",380,566,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	; Set the radio selection.
	Switch $stashBrowser
		Case "Firefox"
			GUICtrlSetState($chooseFirefox, $GUI_CHECKED)
		Case "Chrome"
			GUICtrlSetState($chooseChrome, $GUI_CHECKED)
		Case "Edge"
			GUICtrlSetState($chooseEdge, $GUI_CHECKED)
	EndSwitch
			
	$btnDone = GUICtrlCreateButton("Done",560,580,173,63,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	GUISetState(@SW_SHOW, $Settings)
	
	While True
		Sleep(10)
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnBrowse
				Local $sFile = FileOpenDialog("Open the Stash-Win.exe:", _ 
					@DocumentsCommonDir, "(Stash-Win.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($stashPath, $sFile)
				EndIf
			Case $btnDone
				Select 
					Case GUICtrlRead($chooseFirefox) = $GUI_CHECKED
						$sBrowser = "Firefox"
					Case GUICtrlRead($chooseChrome) = $GUI_CHECKED
						$sBrowser = "Chrome"
					Case GUICtrlRead($chooseEdge) = $GUI_CHECKED
						$sBrowser = "Edge"
				EndSelect
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath", "REG_SZ", _ 
					GUICtrlRead($stashPath))
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser", "REG_SZ", $sBrowser)
				MsgBox(64,"Setting saved.", _ 
				  "You need to restart the program for the new settings to take effect, though.",0)
				ExitLoop
			Case $updateFirefox
				_WD_DeleteSession($sSession)
				_WD_Shutdown()
				Local $b64 = ( @CPUArch = "X64" )
				Local $bGood = _WD_UPdateDriver ("firefox", Default , $b64, True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Firefox Driver", _ 
					"There is an error getting the driver for Firefox. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else 
					MsgBox(64,"Firefox Updated","Firefox webdriver just updated to the latest version.",0)
				EndIf
				SetupFirefox()
				_WD_Startup()
				$sSession = _WD_CreateSession($sDesiredCapabilities)
			
			Case $updateChrome
				_WD_DeleteSession($sSession)
				_WD_Shutdown()
				Local $bGood = _WD_UPdateDriver ("chrome", Default , Default, True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Firefox Driver", _ 
					"There is an error getting the driver for Firefox. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else
					MsgBox(64,"Chrome Updated","Chrome webdriver just updated to the latest version.",0)
				EndIf
				SetupChrome()
				_WD_Startup()
				$sSession = _WD_CreateSession($sDesiredCapabilities)
			Case $updateEdge
				_WD_DeleteSession($sSession)
				_WD_Shutdown()
				Local $b64 = ( @CPUArch = "X64" )
				Local $bGood = _WD_UPdateDriver ("msedge", Default , $b64 , True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Firefox Driver", _ 
					"There is an error getting the driver for Firefox. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else 
					MsgBox(64,"MS Edge Updated","MS Edge webdriver just updated to the latest version.",0)
				EndIf
				SetupEdge()
				_WD_Startup()
				$sSession = _WD_CreateSession($sDesiredCapabilities)
			
			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	Wend
	GUIDelete($Settings)
EndFunc 
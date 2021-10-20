#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>

Func ShowSettings()
	; Global $stashBrowser, $stashFilePath, $stashURL
	Local $sBrowser
	Local $guiSettings = GUICreate("Settings",801,1042,-1,-1,-1,-1)
	
	GUICtrlCreateLabel("Boss Coming Key: Ctrl + Enter"&@crlf&"Hit this key combination will immediately close the Stash browser.",100,40,574,129,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	
	GUICtrlCreateGroup("Preferred Browser",97,164,442,262,$BS_CENTER,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	GUICtrlCreateLabel("Drivers",407,207,83,24,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	$radioChooseFirefox = GUICtrlCreateRadio("Firefox",166,237,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	$btnUpdateFirefox = GUICtrlCreateButton("Update",387,245,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	$radioChooseChrome = GUICtrlCreateRadio("Chrome",166,299,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$btnUpdateChrome = GUICtrlCreateButton("Update",387,305,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	$radioChooseEdge = GUICtrlCreateRadio("MS Edge",166,367,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$btnUpdateEdge = GUICtrlCreateButton("Update",387,373,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	; Set the radio selection from current settings.
	Switch $stashBrowser
		Case "Firefox"
			GUICtrlSetState($radioChooseFirefox, $GUI_CHECKED)
		Case "Chrome"
			GUICtrlSetState($radioChooseChrome, $GUI_CHECKED)
		Case "Edge"
			GUICtrlSetState($radioChooseEdge, $GUI_CHECKED)
	EndSwitch

	$chkShowStash = GUICtrlCreateCheckbox("Show Stash Console",169,447,258,34,-1,-1)
	If $showStashConsole = 1 Then GUICtrlSetState($chkShowStash, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the stash console when running Stash helper. Can be helpful to trouble-shoot problems.")

	$chkShowWebDriver = GUICtrlCreateCheckbox("Show Web Driver Console",169,488,304,34,-1,-1)
	If $showWDConsole = 1 Then GUICtrlSetState($chkShowWebDriver, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the web driver console when running Stash helper. Can be helpful to trouble-shoot problems.")

	GUICtrlCreateLabel("Stash-win.exe location:",66,539,299,37,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$inputStashWinLocation = GUICtrlCreateInput($stashFilePath,66,590,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	$btnBrowseStash = GUICtrlCreateButton("Browse",566,584,142,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	GUICtrlCreateLabel("Stash URL:",68,634,299,37,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$inputStashURL = GUICtrlCreateInput($stashURL,68,675,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Default is 'http://localhost:9999/'")

	GUICtrlCreateLabel("Alternative player location:",69,753,407,37,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$inputMediaPlayerLocation = GUICtrlCreateInput("",69,804,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Use an alternative media player like VLC, potplayer...etc to player the scene file.")

	$btnBrowsePlayer = GUICtrlCreateButton("Browse",566,798,142,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Browse for the .exe file for the media player.")

		
	$btnDone = GUICtrlCreateButton("Done",566,883,173,63,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	GUISetState(@SW_SHOW, $guiSettings)
	
	While True
		Sleep(10)
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnBrowseStash
				Local $sFile = FileOpenDialog("Open the Stash-Win.exe:", _ 
					@DocumentsCommonDir, "(Stash-Win.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($inputStashWinLocation, $sFile)
				EndIf
			Case $btnBrowsePlayer
				Local $sFile = FileOpenDialog("Open the media player's .exe file:", _ 
					@ProgramFilesDir, "Executable File(*.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($inputMediaPlayerLocation, $sFile)
				EndIf
			Case $btnDone
				Select 
					Case GUICtrlRead($radioChooseFirefox) = $GUI_CHECKED
						$sBrowser = "Firefox"
					Case GUICtrlRead($radioChooseChrome) = $GUI_CHECKED
						$sBrowser = "Chrome"
					Case GUICtrlRead($radioChooseEdge) = $GUI_CHECKED
						$sBrowser = "Edge"
				EndSelect
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath", "REG_SZ", _ 
					GUICtrlRead($inputStashWinLocation))
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser", "REG_SZ", $sBrowser)
				$iShow = (GUICtrlRead($chkShowStash) = $GUI_CHECKED) ? 1 : 0
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowStashConsole", "REG_DWORD", $iShow)
				$iShow = (GUICtrlRead($chkShowWebDriver) = $GUI_CHECKED) ? 1 : 0
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowWDConsole", "REG_DWORD", $iShow)
				$sPlayerLocation = GUICtrlRead($inputMediaPlayerLocation)
				If $sPlayerLocation <> "" Then 
					RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "MediaPlayerLocation", "REG_SZ", $sPlayerLocation)
				EndIf
				$stashURL = GUICtrlRead($inputStashURL)
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL", "REG_SZ", $stashURL)
				
				MsgBox(64,"Setting saved.", _ 
				  "You need to restart the program for the new settings to take effect, though.",0)
				ExitLoop
			Case $btnUpdateFirefox
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
			
			Case $btnUpdateChrome
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
			Case $btnUpdateEdge
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
	GUIDelete($guiSettings)
EndFunc 
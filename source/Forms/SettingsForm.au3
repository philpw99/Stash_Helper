#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>

Func ShowSettings()
	; Global $stashBrowser, $stashFilePath, $stashURL, $sMediaPlayerLocation
	Local $sBrowser, $bRestartRequired = False 
	Local $guiSettings = GUICreate("Settings",800,940,-1,-1,-1,-1)
	GUISetIcon("helper2.ico")
	; Disable the tray clicks
	TraySetClick(0)
	
	GUICtrlCreateLabel("Boss Coming Key: Ctrl + Enter"&@crlf&"Hit this key combination will immediately close the Stash browser.",100,40,566,96,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	
	GUICtrlCreateGroup("Preferred Browser",97,136,444,205,$BS_CENTER,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	GUICtrlCreateLabel("Drivers",407,157,83,24,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	Local $radioChooseFirefox = GUICtrlCreateRadio("Firefox",166,187,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	Local $btnUpdateFirefox = GUICtrlCreateButton("Update",387,195,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when Firefox is not under control any more.")
	
	Local $radioChooseChrome = GUICtrlCreateRadio("Chrome",166,237,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $btnUpdateChrome = GUICtrlCreateButton("Update",387,245,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when Chrome is not under control any more.")
	
	Local $radioChooseEdge = GUICtrlCreateRadio("MS Edge",166,287,147,38,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $btnUpdateEdge = GUICtrlCreateButton("Update",387,293,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when MS Edge is not under control any more.")
	
	GUICtrlCreateLabel("Image Slideshow",407,749,180,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	Local $inputSlideShow = GUICtrlCreateInput(string($iSlideShowSeconds),592,747,60,32,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlCreateLabel("seconds",668,747,83,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	
	; Set the radio selection from current settings.
	Switch $stashBrowser
		Case "Firefox"
			GUICtrlSetState($radioChooseFirefox, $GUI_CHECKED)
		Case "Chrome"
			GUICtrlSetState($radioChooseChrome, $GUI_CHECKED)
		Case "Edge"
			GUICtrlSetState($radioChooseEdge, $GUI_CHECKED)
	EndSwitch

	Local $chkShowStash = GUICtrlCreateCheckbox("Show Stash Console",168,353,258,34,-1,-1)
	If $showStashConsole = 1 Then GUICtrlSetState($chkShowStash, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the stash console when running Stash helper. Can be helpful to trouble-shoot problems.")

	Local $chkShowWebDriver = GUICtrlCreateCheckbox("Show Web Driver Console",168,394,304,34,-1,-1)
	If $showWDConsole = 1 Then GUICtrlSetState($chkShowWebDriver, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the web driver console when running Stash helper. Can be helpful to trouble-shoot problems.")

	GUICtrlCreateLabel("Stash-win.exe location:",66,436,299,37,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Local $inputStashWinLocation = GUICtrlCreateInput($stashFilePath,66,487,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	Local $btnBrowseStash = GUICtrlCreateButton("Browse",566,481,142,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	GUICtrlCreateLabel("Stash URL:",68,531,299,37,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Local $inputStashURL = GUICtrlCreateInput($stashURL,68,572,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Default is 'http://localhost:9999/'")

	GUICtrlCreateLabel("Alternative player location:",68,630,407,37,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Local $inputMediaPlayerLocation = GUICtrlCreateInput($sMediaPlayerLocation,68,681,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Use an alternative media player like VLC, potplayer...etc to player the scene file.")

	Local $btnBrowsePlayer = GUICtrlCreateButton("Browse",566,675,142,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Browse for the .exe file for the media player.")

	GUICtrlCreateLabel("Player Presets:",68,749,162,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	Local $btnPlayerPot = GUICtrlCreateButton("PotPlayer",74,795,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"PotPlayer from potplayer.daum.net")

	Local $btnPlayerVLC = GUICtrlCreateButton("VLC",207,795,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"VLC Media Player by VideoLAN")

	Local $btnPlayerMPC = GUICtrlCreateButton("MPC",340,795,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Media Player Classic from  mpc-hc.org")

	Local $btnPlayerGOM = GUICtrlCreateButton("GOM",74,842,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"GOM Player from player.gomlab.com")

	Local $btnPlayerKodi = GUICtrlCreateButton("Kodi",207,842,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Kodi from XBMC Foundation")

	Local $btnPlayerKMP = GUICtrlCreateButton("KMP",340,842,133,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"K-Multimedia Player from Pandora TV.")

	Local $chk64Bit = GUICtrlCreateCheckbox("64 Bit",288,749,99,38,-1,-1)
	If @OSArch = "X64" Then
		GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE, $GUI_CHECKED))
	Else 
		GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE))
	EndIf

	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $btnDone = GUICtrlCreateButton("Done",541,819,173,63,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	GUISetState(@SW_SHOW, $guiSettings)
	
	
	While True
		Sleep(10)
		; if click on tray icon, activate the current GUI
		Local $nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiSettings)
 		EndSwitch 

 		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnBrowseStash
				Local $sFile = FileOpenDialog("Open the Stash-Win.exe:", _ 
					@DocumentsCommonDir, "(Stash-Win.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($inputStashWinLocation, $sFile)
					$bRestartRequired = True
				EndIf
			Case $btnBrowsePlayer
				Local $sFile = FileOpenDialog("Open the media player's .exe file:", _ 
					$sProgramFilesDir, "Executable File(*.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($inputMediaPlayerLocation, $sFile)
				EndIf
			Case $btnDone
				$sMediaPlayerLocation = GUICtrlRead($inputMediaPlayerLocation)
				If $sMediaPlayerLocation <> "" Then 
					; No checking empty string to enable user to clear this setting.
					If Not FileExists($sMediaPlayerLocation) Then 
						MsgBox(48,"Media Player not exist.","The media player location is not correct.",0)
						ExitLoop 
					EndIf
				EndIf 
				; Either write an empty string, or a valid location.
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "MediaPlayerLocation", "REG_SZ", $sMediaPlayerLocation)
				
				$iSlideShowSeconds = Floor(GUICtrlRead($inputSlideShow))
				If $iSlideShowSeconds > 0 Then 
					RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper","SlideShowSeconds", "REG_DWORD", $iSlideShowSeconds)
				Else
					; Reset to the right value.
					$iSlideShowSeconds = 10
				EndIf
				
				Select 
					Case GUICtrlRead($radioChooseFirefox) = $GUI_CHECKED
						$sBrowser = "Firefox"
					Case GUICtrlRead($radioChooseChrome) = $GUI_CHECKED
						$sBrowser = "Chrome"
					Case GUICtrlRead($radioChooseEdge) = $GUI_CHECKED
						$sBrowser = "Edge"
				EndSelect
				If $sBrowser <> $stashBrowser Then $bRestartRequired = True
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath", "REG_SZ", _ 
					GUICtrlRead($inputStashWinLocation))
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser", "REG_SZ", $sBrowser)
				Local $iShow = (GUICtrlRead($chkShowStash) = $GUI_CHECKED) ? 1 : 0
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowStashConsole", "REG_DWORD", $iShow)
				$iShow = (GUICtrlRead($chkShowWebDriver) = $GUI_CHECKED) ? 1 : 0
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowWDConsole", "REG_DWORD", $iShow)
				
				$stashURL = GUICtrlRead($inputStashURL)
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL", "REG_SZ", $stashURL)
				Local $sMessage =  $bRestartRequired ? "You need to restart the program for the new settings to take effect, though." : "Settings are in effect now."
				MsgBox(64,"Setting saved.", $sMessage,0)
				ExitLoop
			Case $btnUpdateFirefox
				If $stashBrowser = "Firefox" Then 
					_WD_DeleteSession($sSession)
					_WD_Shutdown()
				EndIf 
				Local $b64 = ( @OSArch = "X64" )
				Local $bGood = _WD_UPdateDriver ("firefox", @AppDataDir & "\Webdriver" , $b64, True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Firefox Driver", _ 
					"There is an error getting the driver for Firefox. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else 
					MsgBox(64,"Firefox Updated","Firefox webdriver just updated to the latest version.",0)
				EndIf
				If $stashBrowser = "Firefox" Then 
					SetupFirefox()
					_WD_Startup()
					$sSession = _WD_CreateSession($sDesiredCapabilities)
					OpenURL($stashURL)
				EndIf 
				
			Case $btnUpdateChrome
				If $stashBrowser = "Chrome" Then 
					_WD_DeleteSession($sSession)
					_WD_Shutdown()
				EndIf 
				Local $bGood = _WD_UPdateDriver ("chrome", @AppDataDir & "\Webdriver" , Default, True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Chrome Driver", _ 
					"There is an error getting the driver for Chrome. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else
					MsgBox(64,"Chrome Updated","Chrome webdriver just updated to the latest version.",0)
				EndIf
				If $stashBrowser = "Chrome" Then 
					SetupChrome()
					_WD_Startup()
					$sSession = _WD_CreateSession($sDesiredCapabilities)
					OpenURL($stashURL)
				EndIf 
			Case $btnUpdateEdge
				If $stashBrowser = "Edge" Then 
					_WD_DeleteSession($sSession)
					_WD_Shutdown()
				EndIf 
				Local $b64 = ( @OSArch = "X64" )
				Local $bGood = _WD_UPdateDriver ("msedge", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting ms edge Driver", _ 
					"There is an error getting the driver for MS Edge. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else 
					MsgBox(64,"MS Edge Updated","MS Edge webdriver just updated to the latest version.",0)
				EndIf
				If $stashBrowser = "Edge" Then 
					SetupEdge()
					_WD_Startup()
					$sSession = _WD_CreateSession($sDesiredCapabilities)
					OpenURL($stashURL)
				EndIf 
			Case $btnPlayerPot
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\DAUM\PotPlayer\PotPlayerMini64.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\DAUM\PotPlayer\PotPlayerMini64.exe")
				EndIf 
					
			Case $btnPlayerVLC
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\VideoLAN\VLC\vlc.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\VideoLAN\VLC\vlc.exe")
				EndIf 

			Case $btnPlayerMPC
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\MPC-HC\mplayerc.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\MPC-HC\mplayerc.exe")
				EndIf 
					
			Case $btnPlayerGOM
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\GRETECH\GOMPlayer\GOM.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\GRETECH\GOMPlayer\GOM.exe")
				EndIf 
					
			Case $btnPlayerKodi
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\Kodi\Kodi.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\Kodi\Kodi.exe")
				EndIf 

			Case $btnPlayerKMP
				If GUICtrlRead($chk64Bit) = $GUI_CHECKED Then 
					GUICtrlSetData($inputMediaPlayerLocation, $sProgramFilesDir & "\the kmplayer\kmplayer.exe")
				Else 
					GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\the kmplayer\kmplayer.exe")
				EndIf 

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	Wend
	GUIDelete($guiSettings)
	TraySetClick(9)
EndFunc 
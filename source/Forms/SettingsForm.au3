#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>


Func ChooseBrowser($sBrowser)
	Global $radioChooseFirefox, $radioChooseChrome, $radioChooseEdge
	Switch $sBrowser
		Case "Firefox"
			GUICtrlSetState($radioChooseFirefox, $GUI_CHECKED)
		Case "Chrome"
			GUICtrlSetState($radioChooseChrome, $GUI_CHECKED)
		Case "Edge"
			GUICtrlSetState($radioChooseEdge, $GUI_CHECKED)
	EndSwitch
EndFunc

Func ChooseProfile($sProfile)
	Global $radioChoosePrivate, $radioChooseDefault
	Switch $sProfile
		Case "Private"
			GUICtrlSetState($radioChoosePrivate, $GUI_CHECKED)
		Case "Default"	
			GUICtrlSetState($radioChooseDefault, $GUI_CHECKED)
	EndSwitch
EndFunc 
	
Func ChooseType($sType)
	Global $radioLocal, $radioRemote, $inputStashWinLocation, $btnBrowseStash, $chkShowStash
	Switch $sType
		Case "Local"
			GUICtrlSetState($radioLocal, $GUI_CHECKED)
			GUICtrlSetState($inputStashWinLocation, $GUI_ENABLE)
			GUICtrlSetState($btnBrowseStash, $GUI_ENABLE)
			GUICtrlSetState($chkShowStash, $GUI_ENABLE)
		Case "Remote"
			GUICtrlSetState($radioRemote, $GUI_CHECKED)
			GUICtrlSetState($inputStashWinLocation, $GUI_DISABLE)
			GUICtrlSetState($btnBrowseStash, $GUI_DISABLE)
			GUICtrlSetState($chkShowStash, $GUI_DISABLE)
	EndSwitch
EndFunc

Func ShowSettings()

	Global $stashBrowser, $stashFilePath, $stashURL, $sMediaPlayerLocation, $stashBrowserProfile
	Local $sBrowser, $sProfile, $bRestartRequired = False, $sBrowserLocation = "unchanged"
	Local $guiSettings = GUICreate("Settings",770,984,-1,-1,-1,-1)
	GUISetIcon("helper2.ico")
	; Disable the tray clicks
	TraySetClick(0)

	; Stash type choosing radios
	GUICtrlCreateGroup("Stash Type",33,23,277,90,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	Global $radioLocal = GUICtrlCreateRadio("Local",51,68,85,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Stash will run by launching stash-win.exe locally.")
	Global $radioRemote = GUICtrlCreateRadio("Remote",181,68,116,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Stash will run in a remote computer. Stash help will access it by using Stash URL.")

	GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
	
	Global $chkShowStash = GUICtrlCreateCheckbox("Show Stash Console",354,13,258,34,-1,-1)
	If $showStashConsole = 1 Then GUICtrlSetState($chkShowStash, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the stash console when running Stash helper. Can be helpful to trouble-shoot problems.")

	Local $chkShowWebDriver = GUICtrlCreateCheckbox("Show Web Driver Console",354,54,304,34,-1,-1)
	If $showWDConsole = 1 Then GUICtrlSetState($chkShowWebDriver, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show the web driver console when running Stash helper. Can be helpful to trouble-shoot problems.")

	Local $chkShowDebugConsole = GUICtrlCreateCheckbox("Show Stash Helper Console",353,94,304,34,-1,-1)
	If $showDebugConsole = 1 Then GUICtrlSetState($chkShowDebugConsole, $GUI_CHECKED)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Show Stash Helper's debug console when running Stash helper. Can be helpful to trouble-shoot problems.")

	; Group for choosing browser
	GUICtrlCreateGroup("Preferred Browser",31,133,417,273,$BS_CENTER,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	; Choose browser radios and update buttons
	Global  $radioChooseFirefox = GUICtrlCreateRadio("Firefox",84,180,147,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	Local $btnUpdateFirefox = GUICtrlCreateButton("Update",280,185,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when Firefox is not under control any more.")
	
	Global $radioChooseChrome = GUICtrlCreateRadio("Chrome",84,220,147,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local  $btnUpdateChrome = GUICtrlCreateButton("Update",280,225,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when Chrome is not under control any more.")
	
	Global $radioChooseEdge = GUICtrlCreateRadio("MS Edge",84,260,147,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $btnUpdateEdge = GUICtrlCreateButton("Update",280,265,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when MS Edge is not under control any more.")

	Global $radioChooseOpera = GUICtrlCreateRadio("Opera",84,300,147,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $btnUpdateOpera = GUICtrlCreateButton("Update",280,305,112,32,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Update this web driver only when Opera is not under control any more.")

	
	; Button to specify browser exe location.
	$btnExeLocation = GUICtrlCreateButton("Browser EXE Location ...",84,350,308,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	If $gsBrowserLocation <> "" Then 
		GUICtrlSetTip(-1,"Currently location: " & $gsBrowserLocation & @CRLF & "Leave it empty to use default location.")
	Else
		GUICtrlSetTip(-1,"Currently location: empty" & @CRLF & "Leave it empty to use default location.")
	EndIf
	
	; Profile choosing radios
	GUICtrlCreateGroup("Browser Profile",477,137,256,172,$BS_CENTER,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	Global $radioChoosePrivate = GUICtrlCreateRadio("Private Profile",504,194,174,20,-1,-1)
	GUICtrlSetTip(-1,"Stash will run in the browser with a private profile. Your browser's history will be safe.")
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	Global $radioChooseDefault = GUICtrlCreateRadio("Default Profile",504,252,184,20,-1,-1)
	GUICtrlSetTip(-1,"Stash will run in the browser's default user profile. Your bookmarks and add-ons will be available.")
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group Browser Profile
	
	; Option to remember last URL
	$chkSaveLastURL = GUICtrlCreateCheckbox("Remember Last Visit",477,326,249,48,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Remember the last page you visit when closing the Stash Helper. SH will open that page again when it run next time.")
	If $giSaveLastURL = 1 Then 
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf
	
	; Set fragment to studio code for JAV
	$btnJAVStudioCode = GUICtrlCreateButton("JAV Studio Code",477,394,245,41,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Set the fragment matching for JAV studios.")

	GUICtrlCreateLabel("Stash-win.exe location:",34,431,299,33,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Global $inputStashWinLocation = GUICtrlCreateInput($stashFilePath,34,472,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	
	global $btnBrowseStash = GUICtrlCreateButton("Browse",533,472,142,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	GUICtrlCreateLabel("Stash URL:",36,526,299,33,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Local $inputStashURL = GUICtrlCreateInput($stashURL,36,557,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Default is 'http://localhost:9999/'")
	
	; Group Media player
	GUICtrlCreateGroup("Media Player",20,610,714,225,$BS_CENTER,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")


	GUICtrlCreateLabel("Player location:",38,641,173,35,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	Local $inputMediaPlayerLocation = GUICtrlCreateInput($sMediaPlayerLocation,38,676,473,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Use an alternative media player like VLC, potplayer...etc to player the scene file.")

	Local $btnBrowsePlayer = GUICtrlCreateButton("Browse",532,676,142,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Browse for the .exe file for the media player.")

	GUICtrlCreateLabel("Player Presets:",53,743,162,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	Local $chk64Bit = GUICtrlCreateCheckbox("64 Bit",255,734,99,38,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	If @OSArch = "X64" Then
		GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE, $GUI_CHECKED))
	Else 
		GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE))
	EndIf

	; Image show seconds.
	GUICtrlCreateLabel("Image Slideshow",374,734,180,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetTip(-1,"When send a images list to the media player, how many seconds between each picture? Some players will ignore this." )
	Local $inputSlideShow = GUICtrlCreateInput(string($iSlideShowSeconds),559,732,60,32,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetTip(-1,"In the m3u for images sent to the media player, how many seconds delay between each picture?" )
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlCreateLabel("seconds",635,732,83,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	Local $btnPlayerPot = GUICtrlCreateButton("PotPlayer",41,780,119,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"PotPlayer from potplayer.daum.net")

	Local $btnPlayerVLC = GUICtrlCreateButton("VLC",164,780,119,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"VLC Media Player by VideoLAN")

	Local $btnPlayerMPC = GUICtrlCreateButton("MPC",287,780,119,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Media Player Classic from  mpc-hc.org")

	Local $btnPlayerGOM = GUICtrlCreateButton("GOM",411,780,119,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"GOM Player from player.gomlab.com")

	Local $btnPlayerDeo = GUICtrlCreateButton("DeoVR",530,780,119,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"DeoVR the easy and free VR video player. Default SteamVR location.")

	; Mouse button group
	GUICtrlCreateGroup("Mini Menu Shortcut",20,840,417,121,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"The combo to show the mini-menu in the browser.")
	Local $radioMouseMiddle = GUICtrlCreateRadio("Ctrl + Mouse Middle Button",53,886,329,20,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	Local $radioMouseRight = GUICtrlCreateRadio("Ctrl + Mouse Right Button",53,918,329,33,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	If $giMouseButtonRight = 1 Then 
		GUICtrlSetState( $radioMouseRight, $GUI_CHECKED )
	Else 
		GUICtrlSetState( $radioMouseMiddle, $GUI_CHECKED )
	EndIf
	
	Local $btnDone = GUICtrlCreateButton("Done",546,850,173,63,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	; Set the radio selection from current settings.
	ChooseBrowser($stashBrowser)
	If $stashBrowserProfile = "" Then $stashBrowserProfile = "Private"
	ChooseProfile($stashBrowserProfile)
	If $stashType = "" Then $stashType = "Local"
	ChooseType($stashType)
	
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
				
			Case $radioLocal
				ChooseType("Local")
			Case $radioRemote
				ChooseType("Remote")
				
			Case $radioChooseFirefox, $radioChooseChrome, $radioChooseEdge
				$sBrowserLocation = ""	; Reset it to default location.
				GUICtrlSetTip($btnExeLocation,"Currently location: empty" & @CRLF & "Leave it empty to use default location.")
				
			Case $btnDone
				
				; Set the mouse button setting
				If GUICtrlRead( $radioMouseRight) = $GUI_CHECKED Then
					$giMouseButtonRight =  1
				Else
					$giMouseButtonRight =  0
				EndIf 
				RegWrite($gsRegBase,"MouseButtonRight", "REG_DWORD", $giMouseButtonRight)
				
				; Media player setting
				$sMediaPlayerLocation = GUICtrlRead($inputMediaPlayerLocation)
				If $sMediaPlayerLocation <> "" Then 
					; No checking empty string to enable user to clear this setting.
					If Not FileExists($sMediaPlayerLocation) Then 
						MsgBox(48,"Media Player not exist.","The media player location is not correct.",0)
						ExitLoop 
					EndIf
				EndIf 
				; Either write an empty string, or a valid location.
				RegWrite($gsRegBase, "MediaPlayerLocation", "REG_SZ", $sMediaPlayerLocation)
				
				$iSlideShowSeconds = Floor(GUICtrlRead($inputSlideShow))
				If $iSlideShowSeconds > 0 Then 
					RegWrite($gsRegBase,"SlideShowSeconds", "REG_DWORD", $iSlideShowSeconds)
				Else
					; Reset to the right value.
					$iSlideShowSeconds = 10
				EndIf
				
				; Set the browser choice
				Select 
					Case GUICtrlRead($radioChooseFirefox) = $GUI_CHECKED
						$sBrowser = "Firefox"
					Case GUICtrlRead($radioChooseChrome) = $GUI_CHECKED
						$sBrowser = "Chrome"
					Case GUICtrlRead($radioChooseEdge) = $GUI_CHECKED
						$sBrowser = "Edge"
					Case GUICtrlRead($radioChooseOpera) = $GUI_CHECKED
						$sBrowser = "Opera"
				EndSelect
				RegWrite($gsRegBase, "Browser", "REG_SZ", $sBrowser)
				If $sBrowser <> $stashBrowser Then $bRestartRequired = True
				
				; Set the profile choice
				Select 
					Case GUICtrlRead($radioChoosePrivate) = $GUI_CHECKED
						$sProfile = "Private"
					Case GUICtrlRead($radioChooseDefault) = $GUI_CHECKED
						$sProfile = "Default"
				EndSelect
				RegWrite($gsRegBase, "BrowserProfile", "REG_SZ", $sProfile)
				If $sProfile <> $stashBrowserProfile Then $bRestartRequired = True
				
				; Set the Save Last URL
				$giSaveLastURL = GUICtrlRead( $chkSaveLastURL) =  $GUI_CHECKED ? 1 : 0
				RegWrite($gsRegBase, "SaveLastURL", "REG_DWORD", $giSaveLastURL)
				
				; Set the stash type choice
				Select 
					Case GUICtrlRead($radioLocal) = $GUI_CHECKED
						$sType = "Local"
					Case GUICtrlRead($radioRemote) = $GUI_CHECKED
						$sType = "Remote"
				EndSelect
				RegWrite($gsRegBase, "StashType", "REG_SZ", $sType)
				if $stashType <> $sType Then $bRestartRequired = True 

				; Save other settings.
				RegWrite($gsRegBase, "StashFilePath", "REG_SZ", _ 
					GUICtrlRead($inputStashWinLocation))
				Local $iShow = (GUICtrlRead($chkShowStash) = $GUI_CHECKED) ? 1 : 0
				RegWrite($gsRegBase, "ShowStashConsole", "REG_DWORD", $iShow)
				if $iShow <> $showStashConsole Then $bRestartRequired = True
				$iShow = (GUICtrlRead($chkShowWebDriver) = $GUI_CHECKED) ? 1 : 0
				RegWrite($gsRegBase, "ShowWDConsole", "REG_DWORD", $iShow)
				If $iShow <> $showWDConsole Then $bRestartRequired = True
				$iShow = (GUICtrlRead($chkShowDebugConsole) = $GUI_CHECKED) ? 1 : 0
				RegWrite($gsRegBase, "ShowDebugConsole", "REG_DWORD", $iShow)
				if $iShow <> $showDebugConsole Then $bRestartRequired = True
				
				$stashURL = GUICtrlRead($inputStashURL)
				RegWrite($gsRegBase, "StashURL", "REG_SZ", $stashURL)
			
				
				; Default browser location
				If $sBrowserLocation <> "unchanged" Then 
					$gsBrowserLocation = $sBrowserLocation
					RegWrite($gsRegBase, "BrowserLocation", "REG_SZ", $gsBrowserLocation )
					$bRestartRequired = True 
				EndIf
				
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

			Case $btnUpdateOpera
				If $stashBrowser = "Opera" Then 
					_WD_DeleteSession($sSession)
					_WD_Shutdown()
				EndIf 
				Local $b64 = ( @OSArch = "X64" )
				Local $bGood = _WD_UPdateDriver ("opera", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
				If Not $bGood Then 
					MsgBox(48,"Error Getting Opera Driver", _ 
					"There is an error getting the driver for Opera. Maybe your Internet is down?" _ 
						& @CRLF & "The program will try to get the driver again next time you launch it.",0)
				Else 
					MsgBox(64,"Opera Driver Updated","Opera webdriver just updated to the latest version.",0)
				EndIf
				If $stashBrowser = "Opera" Then 
					SetupOpera()
					_WD_Startup()
					$sSession = _WD_CreateSession($sDesiredCapabilities)
					OpenURL($stashURL)
				EndIf 
			
			Case $btnExeLocation
				
				Local $sExePath = FileOpenDialog( "Choose the Browser Exe file", @ProgramFilesDir & "\", "Exe Files (*.exe)", $FD_FILEMUSTEXIST )
				If @error Then 
					$sBrowserLocation = ""
					MsgBox( $MB_SYSTEMMODAL, "Cancelled", "Now the Exe location is empty.")
					GUICtrlSetTip($btnExeLocation, "Currently location: empty" & @CRLF & "Leave it empty to use default location.")
				Else
					$sBrowserLocation = $sExePath
					GUICtrlSetTip($btnExeLocation, "Currently location: " & $sBrowserLocation & @CRLF & "Leave it empty to use default location.")
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
					
			Case $btnPlayerDeo
				; For SteamVR
				GUICtrlSetData($inputMediaPlayerLocation, @ProgramFilesDir & "\Steam\steamapps\common\DeoVR Video Player\DeoVR.exe")

			Case $btnJAVStudioCode
				; Manually set fragment to Studio code for JAV handling.
				JavStudios()

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	Wend
	GUIDelete($guiSettings)
	TraySetClick(9)
EndFunc 
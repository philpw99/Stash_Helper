#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=C:\Users\Philip\Documents\GitHub\Stash_Helper\source\Stash_Helper.a3x
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;*****************************************
;Stash_Helper.au3 by Philip Wang
;Created with ISN AutoIt Studio v. 1.14
;*****************************************
#include <FileConstants.au3>
#include <TrayConstants.au3>
; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <GuiTab.au3>
#include <GuiListBox.au3>
#include <EditConstants.au3>
#include "webdriver\wd_core.au3"	; Includes json.au3 and winhttp.au3
#include "webdriver\wd_helper.au3"
#include "webdriver\wd_capabilities.au3"
#include <Array.au3>
#include <Inet.au3>
#Include <GDIPlus.au3>
#include <MsgBoxConstants.au3>
#include <Misc.au3>

; opt("MustDeclareVars", 1)

#include <WinAPIGdi.au3>

#Region Globals
Global Const $currentVersion = "v2.5.4"
Global Const $gsRegBase = "HKEY_CURRENT_USER\Software\Stash_Helper"
Global Const $gsWebDriverPath = @AppDataDir & "\WebDriver"

Global $iStashPID = 0, $iConsolePID = 0

; The scale of the screen. This needs to be called before the "SetProcessDPIAware"
Global $gdScale = _WinAPI_EnumDisplaySettings('', $ENUM_CURRENT_SETTINGS)[0] / @DesktopWidth

#include "DTC.au3"
#include "URL_Json_Encode.au3"
#include "TrayMenuEx.au3"
#include "SimpleMsgBox.au3"
; For middle mouse button menu

#include "Forms\MetroPopUpMenu.au3"

If AlreadyRunning() Then
	MsgBox(48,"Stash Helper is still running.","Stash Helper is still running. Maybe it had an error and froze. " & @CRLF _
		& "You can use the 'task manager' to close it." & @CRLF _
		& "I don't recommend running two Stash Helper at the same time.",0)
	Exit
EndIf


; If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")

DllCall("User32.dll","bool","SetProcessDPIAware")

Global $sAboutText = "Stash helper " & $currentVersion & ", written by Philip Wang." _
				& @CRLF & "Hopefully this little program will make you navigate the powerful Stash App more easily." _
				& @CRLF & "Kudos to the great Stash App team ! kermieisinthehouse, WithoutPants, bnkai ... and all other great contributors working for this huge project." _
				& @CRLF & "Kudos also go to Christian Faderl's ISN AutoIt Studio! It's such a powerful AutoIt IDE, which making this program much easier to write." _
				& @CRLF & "Also thanks to InstallForge.net for providing me such an easy-to-build installer!" _
				& @CRLF & "Special thanks to BViking78 for the numerous pieces of advice," _
				& @CRLF & "and thank you gamerjax for your play list suggestions!" _
				& @CRLF & "Wraithstalker90, you made my program more solid, thank you !" _
				& @CRLF & "Also thank you EoinBurke93 for your play current tab suggestions!" _
				& @CRLF & "githubxnoob, thank you for suggesting the ApiKey fix!" _
				& @CRLF & "and PalmerRobbie, who consistantly wanted it to work!"

; This already declared in Custom.au3
Global Enum $ITEM_HANDLE, $ITEM_TITLE, $ITEM_LINK
Global Const $iMaxSubItems = 20
Global $iMediaPlayerPID = 0

; For Play list
Global Enum $LIST_TITLE, $LIST_DURATION, $LIST_FILE
Global $aPlayList[0][3]

TraySetIcon("helper2.ico")


Opt("TrayAutoPause", 0)  ; No pause in tray
; Opt("TrayOnEventMode", 1) ; Enable tray on event mode. NO,NO, DON'T DO IT!

; Remove the trailing (x86) for 64bit windows
Global $sProgramFilesDir = ( @OSArch = "X64" ) ? StringReplace(@ProgramFilesDir, " (x86)", "", 1, 2) : @ProgramFilesDir

; Either "Local" or "Remote"
Global $stashType = RegRead($gsRegBase, "StashType")
Global $stashURL = RegRead($gsRegBase, "StashURL")

#include <Forms\InitialSettingsForm.au3>

If $stashURL = "" Or $stashType = "" Then
	; First time run this program. Need to set the settings.
	InitialSettingsForm()
EndIf

; Now crack the StashURL for host and port.

Global $aStashURL =  _WinHttpCrackUrl($stashURL)
;                  |$array[0] - scheme name
;                  |$array[1] - internet protocol scheme
;                  |$array[2] - host name
;                  |$array[3] - port number
;                  |$array[4] - user name
;                  |$array[5] - password
;                  |$array[6] - URL path  Note: relative path. Default is "/"
;                  |$array[7] - extra information

If @error Then
	RegWrite($gsRegBase, "StashURL", "REG_SZ", "")
	MsgExit("Error in StashURL: " & $stashURL & @CRLF & "Resetting it.")
EndIf

; Have to decleare the following, otherwise the setting form will fail.
Global $stashFilePath = RegRead($gsRegBase, "StashFilePath")
Global $stashPath = stringleft($stashFilePath, StringInStr($stashFilePath, "\", 2, -1))
; Show the local stash console or not
Global $showStashConsole = RegRead($gsRegBase, "ShowStashConsole")
If @error Then $showStashConsole = 0
; For v0.11 and above. Disable the browser from autostart
Global $gsNoBrowser = ""

; For remembering last URL in stash. Default is enable.
Global $giSaveLastURL = RegRead($gsRegBase, "SaveLastURL")
If @error Then $giSaveLastURL = 1
Global $gsLastURL = RegRead($gsRegBase, "LastURL")
if @error Or $giSaveLastURL = 0 Or StringLower(StringLeft($gsLastURL,4)) <> "http" Then
	$gsLastURL = $stashURL
EndIf

If $stashType = "Local" Then
	; Now determine where to get the settings: working directory or %userprofile%\.stash
	Global $gsFileConfig = $stashPath & "config.yml"
	If Not FileExists($gsFileConfig) Then
		$stashPath = @UserProfileDir & "\.stash\"
		$gsFileConfig = $stashPath & "config.yml"
		If not FileExists($gsFileConfig) Then
			MsgBox(0, "No Config file", "There is no config.yml in either current working directory or .stash directory yet." & @CRLF _
				& "Please finish setup and generate a config.yml file then run the Stash Helper again.")
		EndIf
	EndIf

	If FileExists($gsFileConfig) Then
		Global $gsConfigContent = FileRead($gsFileConfig)
		; If exist this setting, then it's v0.11 and above
		If StringInStr($gsConfigContent, "nobrowser:", 2) <> 0 Then
			$gsNoBrowser = " --nobrowser"
		EndIf
	EndIf
EndIf

; Get the browser type and profile type
Global $stashBrowser = RegRead($gsRegBase, "Browser")
If $stashBrowser =  "" Then
	InitialSettingsForm()
	ExitScript()
EndIf

Global $stashBrowserProfile = RegRead($gsRegBase, "BrowserProfile")
If $stashBrowserProfile = "" Then $stashBrowserProfile = "Private"

; show the webdriver console or not
Global $showWDConsole = RegRead($gsRegBase, "ShowWDConsole")
if @error Then $showWDConsole = 0

Global $showDebugConsole =  RegRead($gsRegBase, "ShowDebugConsole")
If @error Then $showDebugConsole = 0

Global $sDesiredCapabilities, $sSession
Global $stashVersion
Global $sMediaPlayerLocation = RegRead($gsRegBase, "MediaPlayerLocation")

Global $iSlideShowSeconds = RegRead($gsRegBase, "SlideShowSeconds")
if @error Then
	$iSlideShowSeconds = 10
	RegWrite($gsRegBase, "SlideShowSeconds", "REG_DWORD", 10)
EndIf

; Specify browser exe location.
Global $gsBrowserLocation = RegRead($gsRegBase, "BrowserLocation")
If @error Then $gsBrowserLocation = ""

Local $sIconPath = @ScriptDir & "\images\icons\"
Local $hIcons[21]	; 20 (0-19) bmps  for the tray menus
For $i = 0 to 20
	$hIcons[$i] = _LoadImage($sIconPath & $i & ".bmp", $IMAGE_BITMAP)
Next

; For SceneToGroupForm.
Global $mInfo = ObjCreate("Scripting.Dictionary")
If @error Then MsgExit("Error Creating global $minfo object.")

; Set Mini Menu shortcut combo
; If $giMouseButtonRight = 1, use mouse right button instead of middle button.
Global $giMouseButtonRight = RegRead($gsRegBase, "MouseButtonRight")
If @error Then
	; Default to be enabled.
	RegWrite( $gsRegBase, "MouseButtonRight", "REG_DWORD", 0)
	$giMouseButtonRight =  0
EndIf

; Is the Stash-Win.exe was launched from Stash_helper?
Global $gbRunStashFromHelper = False
#EndRegion Globals

#Region Load Forms
; All forms.
#include <Forms\SettingsForm.au3>
#include <Forms\CustomizeForm.au3>
#include <Forms\ScrapersForm.au3>
#include <Forms\SceneToGroupForm.au3>
#include <Forms\CopySceneInfo.au3>
#include <Forms\ManagePlayListForm.au3>
#include <Forms\MergePerformers.au3>
#include <Forms\JavStudios.au3>
GetJAVStudioData()

; Seems special scraper is no longer needed when visible CDP works much better.

; Now this is running in the tray
; First run the Stash-Win program $sStashPath
#EndRegion

#Region Launching Stash-Win.exe if necessary.
If $stashURL = "" Then
	If $stashType = "Remote" Then
		; Shouldn't be in this situation. Reset.
		MsgBox(0, "Error in settings", "Invalid Stash URL, have to reset the settings. Restart and set it again.")
		RegWrite($gsRegBase, "StashURL", "REG_SZ", "http://localhost:9999")
		RegWrite($gsRegBase, "StashType", "REG_SZ", "Local")
		Exit
	EndIf
	; Never have $stashURL before. Run it for the first time.
	$stashURL = "http://localhost:9999/"
	RegWrite($gsRegBase, "StashURL", "REG_SZ", $stashURL)
	RegWrite($gsRegBase, "StashType", "REG_SZ", "Local")
	$iStashPID = ProcessExists("stash-win.exe")
	If $iStashPID <> 0 Then ProcessClose($iStashPID) ; Just in case.
	; Run it for the first time.
	$iStashPID = Run($stashFilePath & $gsNoBrowser, $stashPath, @SW_HIDE)
Else
	; StashURL already saved. Launch it only when it's local.
	If $stashType = "Local" Then
		; Use previous $aStashURL
		If UBound($aStashURL) = 0 Then
			$aStashURL = _WinHttpCrackUrl($stashURL)
			If @error Then
				RegWrite($gsRegBase, "StashURL", "REG_SZ", "")
				MsgExit( "Error parsing StashURL:" & $stashURL & @CRLF & "Resetting it again.")
			EndIf
		EndIf

		Local $sHost = $aStashURL[2], $sPort = $aStashURL[3]
		If $sHost = "localhost" or $sHost = "127.0.0.1" Then
			; All below is just to get the right PID for stash, in case two stashes are running at the same time.
			$iStashPID = ProcessExists("stash-win.exe")
			If $iStashPID = 0 Then
				; Not running. Launch it.
				If $showStashConsole Then
					Run(@ComSpec & ' /C ' & $stashFilePath & $gsNoBrowser, $stashPath, @SW_SHOW )
					$iStashPID = ProcessWait( "stash-win.exe", 5 )
					$gbRunStashFromHelper = True
					c( "console pid:" & $iStashPID )
				Else
					$iStashPID = Run($stashFilePath & $gsNoBrowser, $stashPath, @SW_HIDE)
					$gbRunStashFromHelper = True
				EndIf
			Else
				; Already running. Get the PID which is listening to that port
				Local $iPid = Run(@ComSpec & ' /C netstat -ano|find "0.0.0.0:' & $sPort & '"',"",@SW_HIDE, $STDOUT_CHILD )
				ProcessWaitClose($iPid)
				Local $sReadOut = StdoutRead($iPid)
				; Get the PID
				$aStr = StringRegExp($sReadOut, "LISTENING\s+(\d+)", $STR_REGEXPARRAYMATCH)
				If @error Then
					; bad or no match
					$iStashPID = 0
				Else
					; Good match
					$iStashPID = Int( $aStr[0] )
				EndIf
			EndIf
		Else
			$iStashPID = 0 ; No closing in the end.
		EndIf
	EndIf
EndIf
#EndRegion

#Region TCP Connect test
; Too bad that using TCPConncet doesn't work any more. So have to skip the check.

; Test the StashURL with TCPConnect for 10 seconds.
;~ TCPStartup()
;~ ; Get IP for host
;~ opt("TCPTimeout",  2000 )
;~ $sIP = _IsIP( $aStashURL[2] ) ? $aStashURL[2] : TCPNameToIP( $aStashURL[2] )
;~ c( "stash IP:" & $sIP & " Port:" & $aStashURL[3] )
;~ Local $Timer = TimerInit(), $iSocket, $bTcpConnect = False
;~ While TimerDiff($Timer) < 10000
;~ 	$iSocket = TCPConnect( $sIP, $aStashURL[3])
;~ 	If @error Then
;~ 		c( "Error in TCPConnect:" & @error )
;~ 		Sleep( 1000 )
;~ 		; Try again
;~ 	Else
;~ 		TCPCloseSocket( $iSocket )
;~ 		$bTcpConnect = True
;~ 	EndIf
;~ Wend
;~ TCPShutdown()

;~ If Not $bTcpConnect Then
;~ 	$reply = MsgBox(20,"Stash is Not Running","Something is wrong with Stash. It appears to be not running." _
;~ 		 & @CRLF & "Here is the URL:" & @CRLF & $stashURL _
;~ 		 & @CRLF & "Do you want to set the Stash URL yourself?",0)
;~ 	switch $reply
;~ 		case 6 ;YES
;~ 			$stashURL = InputBox("Stash URL Manual input", "Please type the stash URL below", $stashURL)
;~ 			If Not @error Then
;~ 				RegWrite($gsRegBase, "StashURL", "REG_SZ", $stashURL)
;~ 				MsgBox(0, "Setting written", "Setting is saved. You need to restart Stash Helper.")
;~ 			EndIf
;~ 			ExitScript()
;~ 		case 7 ;NO
;~ 			; Just continue and try.
;~ 	endswitch
;~ Else
;~ 	c( "tcp connect:" &  $bTcpConnect )
;~ 	c( "Done Tcp listening at " & TimerDiff($Timer) & "ms" )
;~ EndIf
#EndRegion


#include "URLtoQuery.au3"
#include "CurrentImagesViewer.au3"
#include "AutoHandleJAV.au3"

#Region Initialize tray menus
Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected.
; Now create the top level tray menu items.

TrayCreateItem("Stash Helper " & $currentVersion ) ; 0
TrayCreateItem("")
								; 1
Local $iTrayIconCount = 2
Global $trayMenuScenes = TrayCreateMenu("Scenes")		; 2
_TrayMenuAddImage($hIcons[0], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuImages = TrayCreateMenu("Images")		; 3
_TrayMenuAddImage($hIcons[1], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuGroups = TrayCreateMenu("Groups")		; 4
_TrayMenuAddImage($hIcons[2], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuMarkers = TrayCreateMenu("Markers")		; 5
_TrayMenuAddImage($hIcons[3], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuGalleries = TrayCreateMenu("Galleries")	; 6
_TrayMenuAddImage($hIcons[4], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuPeformers = TrayCreateMenu("Performers"); 7
_TrayMenuAddImage($hIcons[5], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuStudios = TrayCreateMenu("Studios")		; 8
_TrayMenuAddImage($hIcons[6], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuTags = TrayCreateMenu("Tags")			; 9
_TrayMenuAddImage($hIcons[7], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuBookmark = TrayCreateItem("Bookmark    Ctrl-Alt-B") ; 10
_TrayMenuAddImage($hIcons[17], $iTrayIconCount)

$iTrayIconCount += 1
TrayCreateItem("")										; 11

$iTrayIconCount += 1
Global $trayPlayTab = TrayCreateItem("Play Current Scene/Group...   MidMouseButton or Alt-P") ;12
; GUICtrlSetTip(-1, "Play the current scene with external media player specified in the settings.")
_TrayMenuAddImage($hIcons[12], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayScrapers = TrayCreateItem("Scrapers Manager"); 13
; GUICtrlSetTip(-1,"Install or remove website scrapers used by Stash.")
_TrayMenuAddImage($hIcons[8], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayScan = TrayCreateItem("Scan New Files") 	; 14
_TrayMenuAddImage($hIcons[14], $iTrayIconCount)
; GUICtrlSetTip(-1,"Let Stash scans for any new files added to your locations.")

$iTrayIconCount += 1
Global $trayGroup2Scene = TrayCreateItem("Create group from scene...") ; 15
_TrayMenuAddImage($hIcons[15], $iTrayIconCount)
; GUICtrlSetTip(-1,"Create a group from current scene.")

$iTrayIconCount += 1
Global $trayMergePerformers = TrayCreateItem("Merge 2 Performers")		; 16
_TrayMenuAddImage($hIcons[5], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayOpenFolder =  TrayCreateItem("Open Media Folder   Ctrl-Alt-O") ; 17
_TrayMenuAddImage($hIcons[18], $iTrayIconCount)

$iTrayIconCount += 1
Global $trayMenuCSS = TrayCreateMenu("CSS Magic") ; 18
_TrayMenuAddImage($hIcons[19], $iTrayIconCount)

Global $aCSSItems[0][4]
; Enums for the array row.
Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE, $CSS_HANDLE


$iTrayIconCount += 1
Global $trayMenuPlayList = TrayCreateMenu("Play List")		; 19
_TrayMenuAddImage($hIcons[16], 18)
Global $trayAddItemToList = TrayCreateItem("Add Scene/Group/Image/Gallery to Play List        Ctrl-Alt-A", $trayMenuPlayList)
Global $trayManageList =	TrayCreateItem("Manage Current Play List                     Ctrl-Alt-M", $trayMenuPlayList)
Global $trayListPlay = 		TrayCreateItem("Send the Current Play List to Media Player   Ctrl-Alt-P", $trayMenuPlayList)
Global $trayClearList = 	TrayCreateItem("Clear the Play List                          Ctrl-Alt-C", $trayMenuPlayList)

$iTrayIconCount += 1
TrayCreateItem("")										; 20

$iTrayIconCount += 1
Global $traySettings = TrayCreateItem("Settings")		; 21
_TrayMenuAddImage($hIcons[9], 20)

$iTrayIconCount += 1
Global $trayAbout = TrayCreateItem("About")				; 22
_TrayMenuAddImage($hIcons[10], 21)

$iTrayIconCount += 1
Global $trayExit = TrayCreateItem("Exit")				; 23
_TrayMenuAddImage($hIcons[11], 22)

; Sub menu items for tools

; No need for those icons any more
_IconDestroy($hIcons)

; Now sub menu items. 0 is the handle, 1 is title, 2 is the link
Global $traySceneLinks[$iMaxSubItems][3]
Global $trayImageLinks[$iMaxSubItems][3]
Global $trayGroupLinks[$iMaxSubItems][3]
Global $trayMarkerLinks[$iMaxSubItems][3]
Global $trayGalleryLinks[$iMaxSubItems][3]
Global $trayPerformerLinks[$iMaxSubItems][3]
Global $trayStudioLinks[$iMaxSubItems][3]
Global $trayTagLinks[$iMaxSubItems][3]

Global $customScenes, $customImages, $customGroups, $customMarkers, $customGalleries
Global $customPerformers, $customStudios, $customTags

#EndRegion

#Region Launch Debug console
Global $pidDebugConsole
If $showDebugConsole Then
	$pidDebugConsole = Run( Q(@ScriptDir & "\AutoIt3.exe") & " " & Q(@ScriptDir & "\Console.a3x") , @ScriptDir, @SW_SHOW, $STDIN_CHILD)
EndIf

#EndRegion Launch Debug console

#Region Webdriver Start
; Now get WebDriver Ready

; Hide the console, OR NOT
If Not $showWDConsole Then
	$_WD_DEBUG = $_WD_DEBUG_None
EndIf
; For debug purpose
; $_WD_DEBUG = $_WD_DEBUG_Full
StartBrowser()

; Slow down a bit here, or the web driver is not ready.
Sleep(500)

Global $iConsolePID = _WD_Startup()
If @error <> $_WD_ERROR_Success Then
	$WDErrChoice = MsgBox(275,"Browser Control Error!","The Web Driver has error in startup, which means it cannot control the browser." & @CRLF _
		& "Do you want to update the web driver for $stashBrowser ?" & @CRLF _
		& "If you choose Yes, it will do the force update." & @CRLF _
		& "If you choose No, it will reset the browser settings, so you can choose another browser next time." & @CRLF _
		& "If you choose cancel, it will continue and try to create a web session anyway.",0)
	switch $WDErrChoice
		case 6 ;YES
			_WD_Shutdown()
			; Not fit, need to update the driver and try it once again.
			Local $b64 = ( @CPUArch = "X64" )
			Switch $stashBrowser
				Case "Firefox"
					$bGood = _WD_UPdateDriver ("firefox", @AppDataDir & "\Webdriver" , $b64, True) ; Force update
				Case "Chrome"
					$bGood = _WD_UPdateDriver ("chrome", @AppDataDir & "\Webdriver" , Default , True) ; Force update
				Case "Edge"
					$bGood = _WD_UPdateDriver ("msedge", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
				Case "Opera"
					$bGood = _WD_UPdateDriver ("opera", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
			EndSwitch
			$iConsolePID = _WD_Startup()
			if @error <> $_WD_ERROR_Success Then
				BrowserError($_WD_HTTPRESULT, @ScriptLineNumber, "Too bad the web driver still cannot start.")
			EndIf
		case 7 ;NO
			; Set the browser setting to empty so it will run the init dialog next time.
			RegWrite($gsRegBase, "Browser", "REG_SZ", "")
			ExitScript()
		case 2 ;CANCEL
	endswitch

EndIf

; $sDesiredCapabilities =  StringReplace( $sDesiredCapabilities, "\/", "/" )
c("Cap:" & $sDesiredCapabilities)

$sSession = _WD_CreateSession($sDesiredCapabilities)
If @error <> $_WD_ERROR_Success Then
	; c("last http result:" & $_WD_HTTPRESULT)
	If $_WD_HTTPRESULT >= 500 Then
		$WDErrChoice = MsgBox(275,"Session Creation Error!","The Web Driver has error in creating a web session." & @CRLF _
			& "Details: " & @CRLF & GetLastHttpMessage() & @CRLF & @CRLF _
			& "Do you want to update the web driver for $stashBrowser ?" & @CRLF _
			& "If you choose Yes, it will do the force update." & @CRLF _
			& "If you choose No, it will reset the browser settings, so you can choose another browser next time." & @CRLF _
			& "If you choose cancel, it will continue and try to run it anyway.",0)
		switch $WDErrChoice
			case 6 ;YES
				_WD_Shutdown()
				; Not fit, need to update the driver and try it once again.
				Local $b64 = ( @CPUArch = "X64" )
				Switch $stashBrowser
					Case "Firefox"
						$bGood = _WD_UPdateDriver ("firefox", @AppDataDir & "\Webdriver" , $b64, True) ; Force update
					Case "Chrome"
						$bGood = _WD_UPdateDriver ("chrome", @AppDataDir & "\Webdriver" , Default , True) ; Force update
					Case "Edge"
						$bGood = _WD_UPdateDriver ("msedge", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
					Case "Opera"
						$bGood = _WD_UPdateDriver ("opera", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
				EndSwitch
				$iConsolePID = _WD_Startup()
				if @error <> $_WD_ERROR_Success Then
					BrowserError($_WD_HTTPRESULT, @ScriptLineNumber, "Too bad the web driver still cannot start." & @CRLF _
						 & "Detals:" & @CRLF _
						 & GetLastHttpMessage() )
				EndIf
			case 7 ;NO
				; Set the browser setting to empty so it will run the init dialog next time.
				RegWrite($gsRegBase, "Browser", "REG_SZ", "")
				ExitScript()
			case 2 ;CANCEL
		endswitch

		StartBrowser()
		If @error <> $_WD_ERROR_Success Then BrowserError($_WD_HTTPRESULT, @ScriptLineNumber, "After cap error, still cannot set up the browser.")

		_WD_Startup()
		If @error <> $_WD_ERROR_Success Then BrowserError($_WD_HTTPRESULT, @ScriptLineNumber, "After cap error, still cannot start up web driver.")

		$sSession = _WD_CreateSession($sDesiredCapabilities)
		If @error <> $_WD_ERROR_Success Then BrowserError($_WD_HTTPRESULT, @ScriptLineNumber, "Too bad it still doesn't work.")

	ElseIf $_WD_HTTPRESULT >= 400 Then
		BrowserError( $_WD_HTTPRESULT,  @ScriptLineNumber, "Web client error.")	; Show error and exit
	Else
		; Other errors:
		BrowserError( $_WD_HTTPRESULT, @ScriptLineNumber, "Other error. Please use task manager to make sure all browser processes are closed." )	; Show other error and exit.
	EndIf
EndIf

c("Session ID:" & $sSession )
; ExitScript()

Global $gsBrowserHandle = _WD_Window($sSession, "window")
; c( "Browser Handle:" & $gsBrowserHandle )

#EndRegion

#Region Tray Menu Handling

; Create all the bookmark sub menu for scenes, groups, studio...etc
CreateSubMenu()

TraySetState($TRAY_ICONSTATE_SHOW)
; Launch the web page with last remember URL.
; If not remember the URL, $gsLastURL is $stashURL anyway.
; Now browser will open last url for the first run.
; c( "Last Url:" & $gsLastURL )
if $gsLastURL = "" Then
	OpenURL($stashURL)
Else
	OpenURL($gsLastURL)
EndIf

; Find out if this site is password protected and set ApiKey accordingly
Global $gbUserPass = False, $gsApiKey = ""
If IsLoginScreen() Then
	$gbUserPass = True
	TraySetClick(0)		; Disable tray menu
	While True
		Sleep(1000)
		If Not IsLoginScreen() Then ExitLoop
	Wend
	SetApiKey()
	TraySetClick(9)		; Enable tray menu
EndIf

CheckStashVersion()
If $stashVersion <> "" Then
	TrayTip("Stash is Active", $stashVersion, 5, $TIP_ICONASTERISK+$TIP_NOSOUND  )
EndIf

; Create the css menu with a function. It can only becalled after ApiKey is checked.
CreateCSSMenu()

; Ctrl+Alt+A to add scene/group to the playlist.
HotKeySet("^!a", "AddItemToList")
; Ctrl+Alt+C to clear the playlist.
HotKeySet("^!c", "ClearPlayList")
; Ctrl+Alt+M to manage the playlist.
HotKeySet("^!m", "ManagePlayList")
; Ctrl+Alt+P to play the playlist.
HotKeySet("^!p", "SendPlayerList")
; Ctrl+Alt+B to bookmark the current browser tab.
HotKeySet("^!b", "BookmarkCurrentTab")
HotKeySet("^!o", "OpenMediaFolder")
; Alt+P to play the media in the current tab.
HotKeySet("!p", "PlayCurrentTab")

; Looping to get message
While True
	Local $nMsg = TrayGetMsg()
	Switch $nMsg
		Case 0
			; Nothing should be here, but Case 0 here is very necessary.
		Case $trayAbout
			MsgBox(64, "Stash Helper " & $currentVersion, $sAboutText, 20)
		Case $trayExit
			ExitScript()
		Case $traySettings
			ShowSettings()
		Case $trayScrapers
			ScrapersManager()
 		Case $customScenes
			CustomList("Scenes", $traySceneLinks)
		Case $customImages
			CustomList("Images", $trayImageLinks)
		Case $customGroups
			CustomList("Groups", $trayGroupLinks)
		Case $customMarkers
			CustomList("Markers", $trayMarkerLinks)
		Case $customGalleries
			CustomList("Galleries", $trayGalleryLinks)
		Case $customPerformers
			CustomList("Performers", $trayPerformerLinks)
		Case $customStudios
			CustomList("Studios", $trayStudioLinks)
		Case $customTags
			CustomList("Tags", $trayTagLinks)
 		Case $trayPlayTab
 			PlayCurrentTab()
		Case $trayScan
			ScanFiles()
		Case $trayGroup2Scene
			Scene2Group()
		Case $trayMergePerformers
			MergePerformers()
		Case $trayAddItemToList
			AddItemToList()
		Case $trayClearList
			ClearPlayList()
		Case $trayManageList
			ManagePlayList()
		Case $trayListPlay
			SendPlayerList()
		Case $trayMenuBookmark
			BookmarkCurrentTab()
		Case $trayOpenFolder
			OpenMediaFolder()
;		Special scraper is no longer used.
; 		Case $traySpecialScraper
; 			ScrapeSpecial()
		Case Else
			; Auto match the sub menu items.
			For $i = 0 to UBound($traySceneLinks)-1
				If $traySceneLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($traySceneLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayImageLinks)-1
				If $trayImageLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayImageLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayGroupLinks)-1
				If $trayGroupLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayGroupLinks[$i][$ITEM_LINK])
					; Continue 2nd level of loops
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayMarkerLinks)-1
				If $trayMarkerLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayMarkerLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayGalleryLinks)-1
				If $trayGalleryLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayGalleryLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayPerformerLinks)-1
				If $trayPerformerLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayPerformerLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayStudioLinks)-1
				If $trayStudioLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayStudioLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			For $i = 0 to UBound($trayTagLinks)-1
				If $trayTagLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayTagLinks[$i][$ITEM_LINK])
					ContinueLoop 2
				EndIf
			Next
			; Now handle the CSS Magic sub menu items
			For $i = 0 To UBound($aCSSItems) -1
				If $aCSSItems[$i][$CSS_HANDLE] = $nMsg Then
					Local $sQuery = "{configuration{interface{cssEnabled}}}"
					$sResult = Query2($sQuery)
					If @error Then ContinueLoop
					If StringInStr($sResult, "true", 2) = 0 Then
						; the result is false
						MsgBox(0, "Need to enable custom css feature.", 'You need to enable custom css in "Settings->Interface->Custom CSS" first.' )
						ContinueLoop
					EndIf

					Local $sCSS =  GetCSSstring()
					If @error Then $sCSS = ""

					If $aCSSItems[$i][$CSS_ENABLE] = 1 Then
						; Already Enabled. Disable it by removing.
						Local $sSearchStart = "/* Start:" & $aCSSItems[$i][$CSS_TITLE] & " */"
						Local $sSearchEnd = "/* End:" & $aCSSItems[$i][$CSS_TITLE] & " */"
						Local $iPos1 = StringInStr($sCSS, $sSearchStart, 2)
						Local $iPos2 = StringInStr($sCSS, $sSearchEnd, 2)
						If $iPos2 > $iPos1 and $iPos1 <> 0 Then
							; Only do it when the numbers are valid
							$iPos2 += StringLen($sSearchEnd)
							$sCSS = StringLeft($sCSS, $iPos1-1) & StringMid($sCSS, $iPos2)
						EndIf
						ApplyCSS($sCSS)
						$aCSSItems[$i][$CSS_ENABLE] = 0
						TrayItemSetState($aCSSItems[$i][$CSS_HANDLE], $TRAY_UNCHECKED)
					Else
						; Not enable yet. Add it to the end
						Local $sStart = "/* Start:" & $aCSSItems[$i][$CSS_TITLE] & " */"
						Local $sEnd = "/* End:" & $aCSSItems[$i][$CSS_TITLE] & " */"
						; Add the crlf to the end if not there yet.
						If StringRight($sCSS, 1) <> @LF Then $sCSS &= @LF
						$sCSS &= $sStart & @LF & $aCSSItems[$i][$CSS_CONTENT] & @LF & $sEnd
						ApplyCSS($sCSS)
						$aCSSItems[$i][$CSS_ENABLE] = 1
						TrayItemSetState($aCSSItems[$i][$CSS_HANDLE], $TRAY_CHECKED)
					EndIf
					; Now refresh the browser
					_WD_Action($sSession, "refresh")
				EndIf
			Next

	EndSwitch

	; Check for mini menu combo
	If $giMouseButtonRight = 1 Then
		; Check mouse right button
		If _IsPressed("02") And _IsPressed("11") Then MouseWheelClick()
	Else
		; Check mouse middle button
		if _IsPressed("04") And _IsPressed("11") Then MouseWheelClick()
	EndIf

Wend

; Not supposed to end here.
Exit

#EndRegion Tray menu

#Region Functions Region

Func GetLastHttpMessage()
	; Get the last messsage from WebDriver about the last HTTP Response
	Local $oJSON = Json_Decode($_WD_HTTPRESPONSE)
	Return Json_Get($oJSON, $_WD_JSON_Message)
EndFunc

Func MouseWheelClick($bReset = False)
	; Add current tab to the play list.
	Static $hBrowser = 0	; Just need to get the win handle once.
	Static $hTimer = 0 ; Prevent clicking too many times


	If $hTimer = 0 Then
		$hTimer = TimerInit()	; First time, just start timer. No judgement.
	Else
		If TimerDiff($hTimer) < 2000 Then Return ; Too fast. Each click should be 2 seconds apart.
		$hTimer = TimerInit()	; Accepted. Timer reset.
	EndIf

	If $bReset Then			; If browser was closed and relaunched.
		$hBrowser = 0
		Return
	EndIf

	If $hBrowser = 0 Then
		$hBrowser = CurrentBrowserWinHandle()
	EndIf

	; Get winhandle under the mouse
	; https://www.autoitscript.com/forum/topic/122147-window-handletitle-under-mouse-pointer/?do=findComment&comment=848114
	Local $stPoint=DllStructCreate($tagPOINT), $aPos, $hControl, $hWin
	Local $aPos=MouseGetPos()
	DllStructSetData($stPoint,1,$aPos[0])
	DllStructSetData($stPoint,2,$aPos[1])
	$hControl=_WinAPI_WindowFromPoint($stPoint)
	$hWin=_WinAPI_GetAncestor($hControl,2)
	If $hWin = $hBrowser Then
		; Metro style buttons
		MetroPopUpMenu()
	EndIf
EndFunc


Func CheckStashVersion()
	; It will set the global $stashVersion variable
	; Will prompt if there is a new version available.
	If $gbUserPass And $gsApiKey = "" Then
		; no api key, no access to any query
		Return SetError(1)
	EndIf

	Local $sResult = Query('{"query":"{version{version,hash}}"}')
	If @error Then
		MsgBox(0, "Error getting current version", "Error getting data for current verion.")
		Return SetError(1)
	EndIf

	; Query and Get current version.
	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error getting current version", "Error decoding data for current verion.")
		Return SetError(2)
	EndIf

	Local $oVersion = Json_ObjGet($oResult, "data.version")
	$stashVersion = $oVersion.Item("version")
	Local $stashVersionHash = $oVersion.Item("hash")

	; Now get the latest version. Only above 0.11
	$sResult = Query('{"query":"{latestversion{shorthash,url}}"}')
	If @error Then
		MsgBox(0, "Error getting latest version", "Error getting data for the latest version.")
		Return SetError(3)
	EndIf
	; Successfully get the info about latest version.
	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error getting latest version", "Error decoding data for the latest version.")
		Return SetError(4)
	EndIf

	Local $oLatestVersion = Json_ObjGet($oResult, "data.latestversion")
	Local $sLatestVersionHash = $oLatestVersion.Item("shorthash")
	Local $sLatestVersionURL = $oLatestVersion.Item("url")
	Local $sIgnoreHash = RegRead($gsRegBase, "IgnoreHash")

	; c( "Latest Version Hash:" & $sLatestVersionHash & " VersionHash:" & $stashVersionHash & " latestVersionURL:" & $sLatestVersionURL)
	If $sLatestVersionHash <> $stashVersionHash And $sLatestVersionHash <> $sIgnoreHash And $stashType = "Local" Then
		; A new version is waiting.
		Local $aMatchStr = StringRegExp($sLatestVersionURL, '\/download\/(.+)\/stash-win.exe', $STR_REGEXPARRAYMATCH)
		; c ("Latest Version:" & $sLatestVersionURL)
		If UBound($aMatchStr) = 1 Then
			Local $sNewVersion = $aMatchStr[0]
			Local $hAskUpgrade = MsgBox(266787,"A new stash version:" & $sNewVersion & " is available.","There is a new version of Stash: " & $sNewVersion _
				& " Do you want to update the current stash to the new one?" & @CRLF _
				& "If you hit 'Yes', the new version will automatically replace the old one." & @CRLF _
				& "If you hit 'No', this new version will be ignored." & @CRLF _
				& "If you hit 'Cancel', Stash_Helper will ask you again next time.",0)
			switch $hAskUpgrade
				case 6 ;YES, update.
					If $stashType = "Remote" Then
						MsgBox(0, "Not local Stash", "The stash is not running locally. Cannot update it.")
					Elseif $stashType = "Local" Then
						ProcessClose($iStashPID)
						InetGet($sLatestVersionURL, @TempDir & "\stash-win.exe" )
						If Not @error Then
							$stashVersion = ""
							; Download successful.
							FileDelete($stashFilePath)
							FileMove(@TempDir & "\stash-win.exe", $stashFilePath, $FC_OVERWRITE)
							; Run it now.
							If $showStashConsole Then
								Run(@ComSpec &  ' /C ' & $stashFilePath & $gsNoBrowser, $stashPath, @SW_SHOW)
								$iStashPID = ProcessWait( "stash-win.exe", 5 )
							Else
								$iStashPID = Run($stashFilePath & $gsNoBrowser, $stashPath, @SW_HIDE)
							EndIf
						EndIf
					EndIf
				case 7 ;NO, ignore.
					RegWrite($gsRegBase, "IgnoreHash", "REG_SZ", $sLatestVersionHash)
				case 2 ;CANCEL
			endswitch
		EndIf
	EndIf
EndFunc

Func SetApiKey()
	; Get the Api key from $gsConfigContent

	If $gbUserPass Then
		If $stashType = "Local" Then
			Local $iPos1 = StringInStr($gsConfigContent, "api_key: ")
			If $iPos1 <> 0 Then
				$iPos1 += 9
				Local $iPos2 = StringInStr($gsConfigContent, @LF, 1, 1, $iPos1)
				If $iPos2 = 0 Then $iPos2 = StringLen($gsConfigContent) + 1
				$gsApiKey = StringMid($gsConfigContent, $iPos1, $iPos2-$iPos1)
				c("ApiKey:|" & $gsApiKey & "|")
			Else
				$gsApiKey = ""
			EndIf
			If $gsApiKey = "" Or $gsApiKey = '""' Then
				MsgBox(266288,"Need to create ApiKey","Your stash has username/password, but do not have apikey yet." _
					& @CRLF & "You need to generate an apikey in order for most features to work properly." ,0)

				OpenURL($stashURL & "settings?tab=security" )
				$gsApiKey = ""
			EndIf

		ElseIf $stashType = "Remote" Then
			; Open the security tab to get the api key
			OpenURL($stashURL & "settings?tab=security" )
			_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='value text-break']", 0, 10000 )
			Local $sKey
			Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='value text-break']" )
			If $sElement <> "" Then
				$gsApiKey = _WD_ElementAction( $sSession, $sElement, "Text")
			EndIf
			If $gsApiKey = "" Then
				MsgBox(266288,"Need to create ApiKey","Your stash has username/password, but do not have apikey yet." _
					& @CRLF & "You need to generate an apikey in order for most features to work properly." ,0)
			Else
				c("ApiKey:|" & $gsApiKey & "|")
				OpenURL($stashURL)
			EndIf
		EndIf

	EndIf
EndFunc

Func IsLoginScreen()
	; return true if current screen is login screen
	Local $sActualURL = GetURL()
	If @error Then Return SetError(1,  0,  False )	; no browser opened.

	Local $aURL = _WinHttpCrackUrl($sActualURL)
	If @error or Not IsArray($aURL) Then Return SetError(2,  0,  False )

	; c( "IsLoginScreen? $aURL[6]:" & $aURL[6] )
	If $aURL[6] = "/login" Then Return True
	Return False
EndFunc

Func SetHandleToActiveTab()
	; Set the browser handle to the active tab
	Local $sCurrentTitle = CurrentBrowserTitle()  ; Long name with extra
	If $sCurrentTitle = "" Then Return SetError(1)

	Local $sTitle = _WD_Action( $sSession, "title")
	c( "title:" & $sTitle)
	c( "Current Title" & $sCurrentTitle)

	Local $bFound = False
	if $sTitle <> stringleft( $sCurrentTitle, StringLen($sTitle) ) Then
		Local $aHandles = _WD_Window($sSession, 'handles')
		If @error = $_WD_ERROR_Success Then
			Local $sCurrentTab = _WD_Window($sSession, 'window')
			For $sHandle In $aHandles
				_WD_Window($sSession, 'Switch', '{"handle":"' & $sHandle & '"}')
				$sTitle = _WD_Action($sSession, "title")

				If $sTitle = stringleft( $sCurrentTitle, StringLen($sTitle) ) Then
					$bFound = True
					$gsBrowserHandle = $sHandle
					ExitLoop
				EndIf
			Next
		EndIf
	Else
		$bFound = True
	EndIf

	If Not $bFound Then
		; MsgBox(0, "Error", "Error switching to active tab. Line:" & @ScriptLineNumber)
		c( "error switching to active tab.")
		Return SetError(2)
	EndIf

EndFunc

Func CurrentBrowserWinHandle()
	; Return the browser's win handle
	Opt( "WinTitleMatchMode", 2 )
	Local $hWnd
	If $gsBrowserLocation = "" Then
		; Regular situation.
		Switch $stashBrowser
			Case "Firefox"
				$hWnd = WinGetHandle( " — Mozilla Firefox" )
			Case "Chrome"
				$hWnd = WinGetHandle( " - Google Chrome" )
			Case "Edge"
				$hWnd = WinGetHandle( " - Microsoft​ Edge" )
			Case "Opera"
				$hWnd = WinGetHandle( "Opera" )
		EndSwitch
		if @error Then $hWnd = 0
	Else
		; If the browser is a special one, use the exe file name
		Local $sExe = StringMid( $gsBrowserLocation, StringInStr($gsBrowserLocation, "\", 0, -1) + 1 )
		$sExe = StringLeft( $sExe, StringInStr( $sExe, ".") -1 )  ; Remove the ".exe"
		$hWnd = WinGetHandle( " - " & $sExe )
		if @error Then $hWnd = 0
	EndIf
	Opt( "WinTitleMatchMode", 1 )	; Restore to default
	Return $hWnd
EndFunc

Func CurrentBrowserTitle()
	; Return the browser's active tab's title
	Opt( "WinTitleMatchMode", 2 )
	Local $sTitle
	If $gsBrowserLocation = "" Then
		; Regular situation.
		Switch $stashBrowser
			Case "Firefox"
				$sTitle = WinGetTitle( " — Mozilla Firefox" )
			Case "Chrome"
				$sTitle = WinGetTitle( " - Google Chrome" )
			Case "Edge"
				$sTitle = WinGetTitle( " - Microsoft​ Edge" )
			Case "Opera"
				$sTitle = WinGetTitle( "Opera" )
		EndSwitch
	Else
		; If the browser is a special one, use the exe file name
		Local $sExe = StringMid( $gsBrowserLocation, StringInStr($gsBrowserLocation, "\", 0, -1) + 1 )
		$sExe = StringLeft( $sExe, StringInStr( $sExe, ".") -1 )  ; Remove the ".exe"
		$sTitle = WinGetTitle( " - " & $sExe )
	EndIf
	Opt( "WinTitleMatchMode", 1 )	; Restore to default
	Return $sTitle
EndFunc

Func IsEmpty( $item )
	Switch VarGetType($item)
		Case "String"
			if $item = "" or $item = Null  Then Return True
		Case "Array"
			if UBound($item) = 0 Then Return True
		Case "Binary"
			If $item = Null Or StringLen( $item) = 0 Then Return True
		Case "Object"
			If UBound($item.Items) = 0 Then Return True
		Case Else
			If $item = Null Then return true
	EndSwitch
	Return False
EndFunc


Func AddToList($sList, $sItem, $sep = "|" )
	; Add items to a list separated by "|" for listview or listbox
	Return $sList = "" ? $sItem : $sList & $sep & $sItem
EndFunc

Func StartBrowser()
	If Not FileExists($gsWebDriverPath) Then
		DirCreate($gsWebDriverPath)
	EndIf
	Switch StringLower($stashBrowser)
		Case "firefox"
			SetupFirefox()
		Case "chrome"
			SetupChrome()
		Case "edge"
			SetupEdge()
		Case "opera"
			SetupOpera()
		Case Else
			$stashBrowser = "Edge"
			SetupEdge()  ; Edge is more universally available.
	EndSwitch
EndFunc

Func ApplyCSS($str)
	$str = StringReplace($str, @CRLF, "\\n", 0, 2)
	$str = StringReplace($str, @LF, "\\n", 0, 2)
	If StringLeft($str, 3) = "\\n" Then
		$str = StringMid($str, 4)
	EndIf
	$sQuery = '{configureInterface(input:{css:\"' & $str & '\" cssEnabled: true }){css}}'
	QueryMutation($sQuery)
	if @error then return SetError(1)
	RefreshAllTabs()
EndFunc

Func CreateCSSMenu()
	; Create the sub items for CSS Magic menu
	; Global $trayMenuCSS
	; Global $aCSSItems[0][4]
	; Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE, $CSS_HANDLE

	; It will have problems when a user/pass is set
	If $gbUserPass And $gsApiKey = "" Then
		Return SetError(1)
	EndIf

	If UBound($aCSSItems) = 0 Then InitCSSArray($aCSSItems)

	For $i = 0 To UBound($aCSSItems) -1
		; Create the item for the CSS item
		$aCSSItems[$i][$CSS_HANDLE] = TrayCreateItem($aCSSItems[$i][$CSS_TITLE], $trayMenuCSS)
		; Set the check state if the CSS is already enabled.
		If $aCSSItems[$i][$CSS_ENABLE] = 1 Then
			TrayItemSetState($aCSSItems[$i][$CSS_HANDLE], $TRAY_CHECKED)
		EndIf
	Next

EndFunc

Func InitCSSArray(ByRef $a)
	; Global $trayCSSItems[0][4]
	; Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE

	AddCSStoArray($a, "Scene - Hide Scene Specs from Scene Cards", ".scene-specs-overlay{display: none;}" )

	AddCSStoArray($a, "Scene - Hide Studio from Scene Cards", ".scene-studio-overlay{display: none;}" )

	AddCSStoArray($a, "Scene - Tags use less width", ".bs-popover-bottom{max-width: 500px}" )

	AddCSStoArray($a, "Scene - Swap Studio and Specs in Scene Cards", _
		".studio-overlay{bottom: 1rem; right: 0.7rem; height: inherit; top: inherit;}" & @LF _
		& ".scene-specs-overlay { right: 0.7rem; top: 0.7rem; bottom: inherit;}" )

	AddCSStoArray($a, "Scene - Disable Zoom on Hover in Wall Mode", _
		".wall-item:hover .wall-item-container {transform: none;} " & @LF _
		& ".wall-item:before { opacity: 0 !important;}" )

	AddCSStoArray($a, "Performer - Show Larger Performer's Image", "#performer-page .detail-header-image img { max-width: 30rem;}" )

	AddCSStoArray($a, "Images - Disable Lightbox Animation", ".Lightbox-carousel { transition: none;}" )

	AddCSStoArray($a, "Groups - Better Layout for Desktops 1 - Regular Posters", _
		"#group-page .detail-header-image { max-width: 80%;}" & @LF _
		& "#group-page .detail-header-image .group-images img {max-width:50rem;}" )

	AddCSStoArray($a, "Groups - Better Layout for Desktops 2 - Larger Posters", _
		"#group-page .detail-header-image { max-width: 80%;}" & @LF _
		& "#group-page .detail-header-image .group-images img {max-width:100rem;}" )

	AddCSStoArray($a, "Global - Hide the Donation Button", ".btn-primary.btn.donate.minimal { display: none;}" )

	AddCSStoArray($a, "Global - Blur NSFW Images", _
		".scene-card-preview-video, .scene-card-preview-image, .image-card-preview-image, .image-thumbnail, .gallery-card-image," & @LF _
		& ".performer-card-image, img.performer, .group-card-image, .gallery .flexbin img, .wall-item-media, .scene-studio-overlay .image-thumbnail," & @LF _
		& ".image-card-preview-image, #scene-details-container .text-input, #scene-details-container .scene-header, #scene-details-container .react-select__single-value," & @LF _
		& ".scene-details .pre, #scene-tabs-tabpane-scene-file-info-panel span.col-8.text-truncate > a, .gallery .flexbin img, .group-details .logo " & @LF _
		& "{filter: blur(8px);}" & @LF _
		& ".scene-card-video {filter: blur(13px);}" & @LF _
		& ".jw-video, .jw-preview, .jw-flag-floating, .image-container, .studio-logo, .scene-cover { filter: blur(20px);}" & @LF _
		& ".group-card .text-truncate, .scene-card .card-section { filter: blur(4px); }" )

	$sCSS = GetCSSstring()
	If @error Then Return SetError(2)

	; Use /* Start:$a[xx][0] */ as the starting point
	; /* End:$a[xx][0] */ as the ending point
	For $i = 0 To UBound($a) -1
		Local $sSearch = "/* Start:" & $a[$i][0] & " */"
		$a[$i][$CSS_ENABLE] = (StringInStr($sCSS, $sSearch, 2) <> 0) ? 1 : 0
	Next

EndFunc

Func GetCSSstring()
	; It will read the custom.css from graphql

	Local $sQuery = '{configuration{interface{css}}}'
	local $sResult = Query2($sQuery, True )  ; Surpress error messages.
	If @error Then Return SetError(1)

	Local $oCSS = Json_Decode($sResult)
	If Not IsObj($oCSS) Then
		; MsgBox(0, "Error in CSS", "Error getting CSS string from settings.")
		Return SetError(1)
	EndIf

	Local $sCSS =  Json_ObjGet($oCSS, "data.configuration.interface.css")
	If Not IsString($sCSS) Then
		$sCSS = ""
	Else
		$sCSS = StringReplace($sCSS, "\n", @CRLF)
	EndIf
	Return $sCSS
EndFunc

Func AddCSStoArray(ByRef $a, $title, $content )
	Local $i = UBound($a)
	ReDim $a[$i+1][4]
	$a[$i][$CSS_TITLE] = $title
	$a[$i][$CSS_CONTENT] = $content
EndFunc

Func AlreadyRunning()
	Local $aPID = ProcessList("AutoIt3.exe")
	If @error or $aPID[0][0] = 0 then Return False
	For $i = 1 to $aPID[0][0]
		; Skip this one.
		If $aPID[$i][1] = @AutoItPID Then ContinueLoop
		; Get full path by pid
		Local $sPath = _WinAPI_GetProcessFileName($aPID[$i][1])
		If StringInStr($sPath, "Stash Helper") <> 0 Then Return True
	Next
	Return False
EndFunc

Func OpenMediaFolder()
	If $stashType = "Remote" Then
		Return MsgBox(0, "Not supported", "Since this is a remote stash, this function is not supported.")
	EndIf
	$sResult = GetCurrentTabCategoryAndNumber()
	If @error Then Return SetError(1)
	; Return string is like "scenes-11" or "scenes"
	If StringInStr($sResult, "-") = 0 Then
		; in main category or collection
		MsgBox(0, "Need specific item", "The current browser is showing a collection, need to show specific scene/group/image/gallery." )
		Return
	EndIf

	Local $aStr = StringSplit($sResult, "-")
	Switch $aStr[1]
		Case "performers"
			MsgBox(0, "Cannot be a performer", "No folder location for performers.")
			Return
		Case "studios"
			MsgBox(0, "Cannot be a studio", "No folder location for studios.")
			Return
		Case "markers"
			MsgBox(0, "Cannot be markers", "Sorry, no support for markers.")
			Return
		Case "groups"
			; Now get the group info
			$sQuery = '{ "query": "{findGroup(id: ' & $aStr[2] & '){name,scene_count,scenes{id}}}" }'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)

			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			Local $oGroupData = Json_ObjGet($oResult, "data.findGroup")
			; name, scene_count, scenes->id
			Local $iCount = Int( $oGroupData.Item("scene_count") )  ; better to convert it.
			If $iCount = 0 Then
				MsgBox(0, "No scene", "There is no scene in this group.")
				Return SetError(1)
			EndIf
			; Just need the first scene location
			Local $nSceneID = $oGroupData.Item("scenes")[0].Item("id")
			$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){files{path}}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			Local $oSceneData = Json_ObjGet($oResult, "data.findScene")

		Case "scenes"
			; $sQuery = '{"query":"{findScene(id:' & $aStr[2] & '){path}}"}'		; v16
			$sQuery = '{"query":"{findScene(id:' & $aStr[2] & '){files{path}}}"}'	; v17
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findScene")

		Case "images"
			; $sQuery = '{"query":"{findImage(id:' & $aStr[2] & '){path}}"}'		; For v16
			$sQuery = '{"query":"{findImage(id:' & $aStr[2] & '){files{path}}}"}'	; For v17
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findImage")

		Case "galleries"
			; $sQuery = '{"query":"{findGallery(id:' & $aStr[2] & '){path}}"}'		; For v16
			$sQuery = '{"query":"{findGallery(id:' & $aStr[2] & '){files{path}}}"}'	; For v17
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findGallery")
		Case Else
			Return
	EndSwitch

	If IsObj($oSceneData) Then
		; $sFilePath = $oSceneData.Item("path")					; For v16
		$sFilePath = $oSceneData.Item("files")[0].Item("path")	; For v17
		$sFilePath = FixPath($sFilePath)		; v17 need fixing

		; Geth the path only
		$iPos =  StringInStr($sFilePath, "\", 2, -1)
		$sPath = StringLeft($sFilePath, $iPos)
		ShellExecute($sPath)
	EndIf
EndFunc

Func ReloadScrapers()
	; Get the current handle.
	$sResult = QueryMutation('{reloadScrapers}')
	If @error Then Return SetError(1)
	RefreshAllTabs()
	; This message should be sent by the func caller.
	; MsgBox(0, "Scraper Reloaded.", "Successfully reloaded the scrapers.", 10)
EndFunc

Func GetCategory($sURL)
	Local $sStr = StringMid($sURL, StringLen($stashURL) +1 )
	If $sStr = "" Then
		MsgBox(0, "This is home page", "The current browser is showing the home page of stash.")
		Return SetError(1)
	EndIf
	If StringLeft($sStr, 1) = "/" Then
		; remove the leading / , just in case
		$sStr = StringTrimLeft($sStr, 1)
	EndIf
	; split either by
	$aStr = StringSplit($sStr, "/?=" )
	If $aStr[0] = 0 Then
		MsgBox(0, "Error processing page", "The current browser is unknown.")
		Return SetError(1)
	EndIf

	Return $aStr[1]
EndFunc

Func GetCurrentTabCategoryAndNumber()
	Local $sURL = GetURL()
	If @error then Return SetError(1)
	; Get the text after http://localhost:9999/
	Local $sStr = StringMid($sURL, StringLen($stashURL) +1 )
	If $sStr = "" Then
		MsgBox(0, "This is home page", "The current browser is showing the home page of stash.")
		Return SetError(1)
	EndIf
	If StringLeft($sStr, 1) = "/" Then
		; remove the leading / , just in case
		$sStr = StringTrimLeft($sStr, 1)
	EndIf
	; split either by
	$aStr = StringSplit($sStr, "/?=" )
	If $aStr[0] = 0 Then
		MsgBox(0, "Error processing page", "The current browser is unknown.")
		Return SetError(1)
	EndIf

	If $aStr[0] >= 2 and StringIsDigit($aStr[2]) Then
		Return $aStr[1] & "-" & $aStr[2]
	Else
		Return $aStr[1]
	EndIf

EndFunc

Func GetURL()
	; Probably it's close or no windows at all.
	c("Getting current URL")
	Local $sResult
	Local $aHandles =  _WD_Window($sSession, 'Handles')
	Switch  UBound($aHandles)
		case 0
			; No wd windows opened.
			MsgBox(0, "No Stash browser", "Currently no Stash browser is opened. Please open one by using the bookmarks.")
			Return SetError(1)
		case Else
			If Not BrowserTabIsFront() Then
				; Set the current handle to the front tab of the browser
				SetHandleToActiveTab()
			EndIf
			$sResult = _WD_Action($sSession, "url")
;~ 			If @error <> $_WD_ERROR_Success Then
;~ 				; Set the last tab as the current browser tab
;~ 				Local $sHandle =  $aHandles[UBound($aHandles)-1]
;~ 				_WD_Window($sSession, "Switch", '{"handle":"'& $sHandle & '"}')
;~ 				$sResult = _WD_Action($sSession, "url")
;~ 				c ( "1 tab:" & $sResult )
;~ 			EndIf
	EndSwitch

	Return _URLDecode($sResult)
EndFunc

Func BrowserTabIsFront()
	; Check to see if the current browser tab is in the front
	Local $sScript = "return document.visibilityState;"
	Local $sResult = _WD_ExecuteScript( $sSession, $sScript, Default , Default )
	; c( "error :" & @error & " result :" & $sResult)
	If @error = $_WD_ERROR_Success Then
		if $sResult = '{"value":"visible"}' Then Return True
	EndIf
	Return False
EndFunc

Func GetTitle()
	Local $aHandles =  _WD_Window($sSession, 'Handles')
	Switch  UBound($aHandles)
		case 0
			; No wd windows opened.
			MsgBox(0, "No Stash browser", "Currently no Stash browser is opened. Please open one by using the bookmarks.")
			Return SetError(1)
		case 1
			Local $sResult = _WD_Action($sSession, "title")
			If @error <> $_WD_ERROR_Success Then
				; Set the last tab as the current browser tab
				Local $sHandle =  $aHandles[UBound($aHandles)-1]
				_WD_Window($sSession, "Switch", '{"handle":"'& $sHandle & '"}')
				$sResult = _WD_Action($sSession, "title")
			EndIf
		case Else
			; Multi-tab situation. No good solution here.
			Local $sHandle =  $aHandles[0]
			_WD_Window($sSession, "Switch", '{"handle":"'& $sHandle & '"}')
			$sResult = _WD_Action($sSession, "title")
	EndSwitch
	Return $sResult
EndFunc

Func BookmarkCurrentTab()
	Local $sResult = GetCurrentTabCategoryAndNumber()
	If @error Then Return SetError(1)
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	local $sThing = "thing"
	$aStr = StringSplit($sResult, "-")
	Local $sCategory = $aStr[1]

	If $aStr[0] = 2 Then
		If StringIsDigit($aStr[2]) Then
			; Single scene/group
			$sThing = StringTrimRight($sCategory, 1)
		ElseIf $aStr[2] = "c" Then
			$sThing = StringTrimRight($sCategory, 1) & " collection"
		EndIf
	EndIf
	; c("aStr[0]:" & $aStr[0] & " aStr[1]:" & $aStr[1])
	; Now we have the thing.
	Local $sDescription = InputBox("Title required", "Please enter a brief description/title for this " & $sThing & ".")
	If $sDescription = "" Then Return
	$sDescription = StringLeft($sDescription, 50)

	; For bookmarks, the URL need to be encoded.
	$sURL = _URLEncode($sURL, 2)

	Switch $sCategory
		Case "scenes"
			Local $iRow = AddBookmarkToArray($sDescription, $sURL, $traySceneLinks )
			TrayItemDelete($customScenes)
			$traySceneLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuScenes )
			$customScenes = TrayCreateItem("Customize...", $trayMenuScenes)
			SaveMenuItems($sCategory, $traySceneLinks)

		Case "images"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayImageLinks )
			TrayItemDelete($customImages)
			$trayImageLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuImages )
			$customImages = TrayCreateItem("Customize...", $trayMenuImages)
			SaveMenuItems($sCategory, $trayImageLinks)

		Case "groups"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayGroupLinks )
			TrayItemDelete($customGroups)
			$trayGroupLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuGroups )
			$customGroups = TrayCreateItem("Customize...", $trayMenuGroups)
			SaveMenuItems($sCategory, $trayGroupLinks)

		Case "markers"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayMarkerLinks )
			TrayItemDelete($customMarkers)
			$trayMarkerLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuMarkers )
			$customMarkers = TrayCreateItem("Customize...", $trayMenuMarkers)
			SaveMenuItems($sCategory, $trayMarkerLinks)

		Case "galleries"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayGalleryLinks )
			TrayItemDelete($customGalleries)
			$trayGalleryLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuGalleries )
			$customGalleries = TrayCreateItem("Customize...", $trayMenuGalleries)
			SaveMenuItems($sCategory, $trayGalleryLinks)

		Case "performers"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayPerformerLinks )
			TrayItemDelete($customPerformers)
			$trayPerformerLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuPeformers )
			$customPerformers = TrayCreateItem("Customize...", $trayMenuPeformers)
			SaveMenuItems($sCategory, $trayPerformerLinks)

		Case "Studios"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayStudioLinks )
			TrayItemDelete($customStudios)
			$trayStudioLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuStudios )
			$customStudios = TrayCreateItem("Customize...", $trayMenuStudios)
			SaveMenuItems($sCategory, $trayStudioLinks)

		Case "tags"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayTagLinks )
			TrayItemDelete($customTags)
			$trayTagLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuTags )
			$customTags = TrayCreateItem("Customize...", $trayMenuTags)
			SaveMenuItems($sCategory, $trayTagLinks)

	EndSwitch
	MsgBox(0, "Bookmark added.", "Successfully added '" & $sDescription & "' to the " & $sCategory & " category.")
EndFunc

Func SaveMenuItems($sCategory, ByRef $aArray)
	; Save the menu items to the registry
	; First letter should be capital.
	Local $sCat = StringUpper(stringleft($sCategory, 1)) & stringmid($sCategory, 2)
	; First item
	Local $str = "1|" & $aArray[0][$ITEM_TITLE] & "|" & $aArray[0][$ITEM_LINK]
	; the rest
	For $i = 1 to $iMaxSubItems-1
		$str &= "@@@" & String($i+1) & "|" & $aArray[$i][$ITEM_TITLE] & "|" & $aArray[$i][$ITEM_LINK]
	Next
	RegWrite($gsRegBase, $sCat & "List", "REG_SZ", $str)
EndFunc

Func AddBookmarkToArray($sTitle, $sLink, ByRef $aArray )
	For $i = 0 to $iMaxSubItems -1
		If $aArray[$i][$ITEM_TITLE] = "" Then ExitLoop
	Next
	; if all 20 is used, then $i will be the last one
	If $i = 19 Then
	; Special handling of the 20th
		If $aArray[19][$ITEM_HANDLE] <> Null Then
			TrayItemDelete($aArray[19][$ITEM_HANDLE])
		EndIf
	EndIf

	$aArray[$i][$ITEM_TITLE] = $sTitle
	$aArray[$i][$ITEM_LINK] = $sLink
	Return $i
	; return the $row that's added.
EndFunc

Func ClearPlayList()
	ReDim $aPlayList[0][3]
	MsgBox(0, "Playlist cleared", "OK, now the play list is empty.", 10)
EndFunc

Func AddItemToList()
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	c("Add current URL:" & $sURL)

	Local $sCategory = GetCategory($sURL)
	if @error Then Return SetError(2)

	Local $sQueryCount = URLtoQuery($sURL, "count")
	c("sQueryCount: " & $sQueryCount)

	Local $iItemCount
	Switch $sQueryCount
		Case "not support"
			MsgBox(0, "Not support", "Sorry but this kind of collection is not supported yet.")
			Return
		Case  "home"
			MsgBox(0, "Stash HOme Page", "This is Stash's home page. Nothing to add to the play list.")
			Return
		Case "1"
			$iItemCount = 1
		Case Else
			$sResult = Query2($sQueryCount)
			If @error Then Return SetError(1)
			c("result:" & $sResult)
			Local $aStr = StringRegExp($sResult, '"count":\s*(\d+)', $STR_REGEXPARRAYMATCH )
			$iItemCount = Int($aStr[0])
	EndSwitch

	If $iItemCount <> 1 Then
		Local $hConfirm = MsgBox(65,"Confirm","Totally " & $iItemCount & " " & $sCategory & " to add to the play list." & @CRLF & "Some of them might contain multiple items." & @CRLF & "Are you sure to add them to the play list?",0)
		if $hConfirm = 2 then Return ; Cancelled.
	EndIf

	; Get the full list of ids.
	$sQuery = URLtoQuery($sURL, "id")
	if @error then Return SetError(3)

	; If return just a single id.
	If StringLeft($sQuery, 3) = "id=" Then
		; No need to get query. Has one single id.
		Local $sID = PairValue($sQuery), $iNo
		Switch $sCategory
			Case "scenes"
				AddSceneToList($sID)
				If @error then Return
				MsgBox(262208, "Done", "One scene was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList), 10)
			Case "images"
				AddImageToList($sID)
				If @error then Return
				MsgBox(262208, "Done", "One image was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList), 10)
			Case "groups"
				$iNo = AddGroupToList($sID)
				If @error then Return
				MsgBox(262208, "Done", "One group with " & $iNo & " scenes was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList), 10)
			Case "galleries"
				$iNo = AddGalleryToList($sID)
				If @error then Return
				MsgBox(262208, "Done", "One gallery with " & $iNo & " images was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList), 10)
		EndSwitch
		Return
	ElseIf $sQuery = "not support" Then
		MsgBox(262192, "Not support", "Too bad, this kind of query is not support.")
		Return
	EndIf

	; Batch processing
	$sResult = Query2($sQuery)
	if @error Then Return SetError(1)
	Local $oData = Json_Decode($sResult)
	If Not IsObj($oData) Then
		MsgBox(262192, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(4)
	EndIf

	; Start to add scenes, groups... to the play list.
	Switch $sCategory
		Case "scenes"
			Local $aScenes = Json_ObjGet($oData, "data.findScenes.scenes")
			If UBound($aScenes) = 0 Then
				MsgBox(262192, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(5)
			EndIf
			Local $i = 0
			For $oScene in $aScenes
				$i += AddSceneToList($oScene.item("id"))
			Next

			MsgBox(262208, "Done", "Totally "& $i & " scenes were added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList), 10)
		Case "images"
			Local $aImages = Json_ObjGet($oData, "data.findImages.images")
			If UBound($aImages) = 0 Then
				MsgBox(262192, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(6)
			EndIf
			Local $i = 0
			For $oImage in $aImages
				$i += AddImageToList($oImage.item("id"))
			Next
			MsgBox(262208, "Done", "Totally "& $i & " images was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList) & @CRLF _
				& "Beware: Most media players do not support playing images stored in .zip files.", 10 )
		Case "groups"
			Local $aGroups = Json_ObjGet($oData, "data.findGroups.groups")
			If UBound($aGroups) = 0 Then
				MsgBox(262192, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(7)
			EndIf
			Local $i = 0
			For $oGroup in $aGroups
				$i += AddGroupToList($oGroup.item("id"))
			Next
			MsgBox(262208, "Done", "Totally "& UBound($aGroups) & " groups with "& $i & " scenes was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList), 10)
		Case "galleries"
			Local $aGalleries = Json_ObjGet($oData, "data.findGalleries.galleries")
			If UBound($aGalleries) = 0 Then
				MsgBox(0, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(8)
			EndIf
			Local $i = 0
			For $oGallery in $aGalleries
				$i += AddGalleryToList($oGallery.item("id"))
			Next
			MsgBox(262208, "Done", "Totally "& UBound($aGalleries) & " galleries with "& $i & " images were added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList) & @CRLF _
				& "Beware: Most media players do not support playing images stored in .zip files.", 10 )
		Case Else
			MsgBox(262192, "Not supported", "Sorry, only scene/image/group/gallery are supported.", 20)
	EndSwitch

EndFunc

Func AddImageToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	; $sQuery = '{"query":"{findImage(id:' & $sID & '){title,path,paths{image} }}"}' 		; For v16
	$sQuery = '{"query":"{findImage(id:' & $sID & '){title,files{path},paths{image} }}"}' 	; For v17
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oData = Json_ObjGet($oResult, "data.findImage")
	If Not IsObj($oData) Then Return 0
	; $oData.Item("title") $oData.Item("path")
	$i = UBound($aPlayList)
	ReDim $aPlayList[$i+1][3]
	$aPlayList[$i][$LIST_TITLE] = "Image: " & $oData.Item("title")
	$aPlayList[$i][$LIST_DURATION] = $iSlideShowSeconds
	If $stashType = "Local" Then
		; $aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("path"))						; for v16
		$aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("files")[0].Item("path") )	; For v17
	ElseIf $stashType = "Remote" Then
		$aPlayList[$i][$LIST_FILE] = $oData.Item("paths").Item("image")
	EndIf
	Return 1  ; Once scene added to the list
EndFunc

Func AddGalleryToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	; $sQuery = '{"query":"{findGallery(id:' & $sID & '){title,image_count,path,images{path, paths{image} }}}"}'  		; for v16
	$sQuery = '{"query":"{findGallery(id:' & $sID & '){title,image_count,path,images{files{path}, paths{image} }}}"}'	; for v17
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oData = Json_ObjGet($oResult, "data.findGallery")
	If Not IsObj($oData) Then Return 0
	; Check gallery's path.
	Local $sPath = $oData.item("path")
	if stringlower(StringRight($sPath, 4)) = ".zip" Then
		Local $iReply = MsgBox(52,"Not Supported","This gallery is a zip file which contains images." & @CRLF _
		& "Showing images in .zip files is not supported by most media players." & @CRLF _
		& "So do you still want to add this gallery: " & $oData.Item("title")& "?",0)
		if $iReply = 7 Then return 0
	EndIf
	Local $aImages = $oData.Item("images")
	If UBound($aImages) = 0 Then Return 0
	; Treat a gallery like a group, just add all images to the list
	Local $iCount = 0
	For $oImage In $aImages
		$iCount += 1
		$i = UBound($aPlayList)
		ReDim $aPlayList[$i+1][3]
		$aPlayList[$i][$LIST_TITLE] = "Gallery: " & $oData.Item("title") & " Image: " & $iCount
		$aPlayList[$i][$LIST_DURATION] = $iSlideShowSeconds
		If $stashType = "Local" Then
			; $aPlayList[$i][$LIST_FILE] = FixPath($oImage.Item("path"))				; for v16
			$aPlayList[$i][$LIST_FILE] = FixPath($oImage.Item("files")[0].Item("path"))	; for v17
		ElseIf $stashType = "Remote" Then
			$aPlayList[$i][$LIST_FILE] = $oImage.Item("paths").Item("image")
		EndIf
	Next
	Return $iCount  ; Total image count.
EndFunc


Func SendPlayerList()
	; Send the media player a temporary list and let it play.
	CheckMediaPlayer()
	If @error Then Return SetError(1)
	If UBound($aPlayList, $UBOUND_ROWS ) = 0 Then
		MsgBox(48,"Play list is empty","There is nothing in the play list. Cannot play it.",10)
		Return SetError(1)
	EndIf
	Local $sFileName = @TempDir & "\StashPlayList.m3u"

	Local $hFile = FileOpen($sFileName, $FO_OVERWRITE)
	If $hFile = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when creating the file.", 10)
		Return SetError(1)
	EndIf

	; Write the required first line.
	FileWriteLine($hFile, "#EXTM3U")
	; Now write the file/path list
	Local $iCount = UBound($aPlayList)
	Local $sTitle, $sFile, $iDuration, $line
	For $i = 0 to $iCount-1
		$sTitle = $aPlayList[$i][$LIST_TITLE]
		$iDuration = $aPlayList[$i][$LIST_DURATION]
		$sFile = $aPlayList[$i][$LIST_FILE]
		$line = "#EXTINF:" & $iDuration & "," & $sTitle
		FileWriteLine($hFile, $line ) ; $aData[2] is the name of the file.
		; Write the real file/path on second line.
		FileWriteLine($hFile, $sFile)
	Next
	FileClose($hFile)
	; Now play it.
	Play(@TempDir & "\StashPlayList.m3u")
EndFunc

Func AddGroupToList($sID)
	If $sID = "" Then Return 0 ; Just in case.
	; Now get the group info
	$sQuery = '{ "query": "{findGroup(id: ' & $sID & '){name,scene_count,scenes{id}}}" }'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oGroupData = Json_ObjGet($oResult, "data.findGroup")
	If $oGroupData = "" Then Return 0
	; name, scene_count, scenes->id
	Local $iCount = Int( $oGroupData.Item("scene_count") )  ; better to convert it.
	If $iCount = 0 Then
		Return 0
	EndIf
	For $i = 0 to $iCount-1
		Local $nSceneID = $oGroupData.Item("scenes")[$i].Item("id")
		; Now add this scene to the  play list
		$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){files{path,duration},paths{stream}}}"}'
		$sResult = Query($sQuery)
		If @error Then Return SetError(1)

		$oResult = Json_Decode($sResult)
		If Not IsObj($oResult) Then
			MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
			Return SetError(1)
		EndIf
		Local $oSceneData = Json_ObjGet($oResult, "data.findScene")
		; path
		Local $j = UBound($aPlayList)
		ReDim $aPlayList[$j+1][3]
		$aPlayList[$j][$LIST_TITLE] = "Group: " & $oGroupData.Item("name") & " - Scene " & ($i+1)
		$aPlayList[$j][$LIST_DURATION] = Floor( $oSceneData.Item("files")[0].Item("duration") )
		If $stashType = "Local" Then
			$aPlayList[$j][$LIST_FILE] = FixPath($oSceneData.Item("files")[0].Item("path"))
		ElseIf $stashType = "Remote" Then
			$aPlayList[$j][$LIST_FILE] = $oSceneData.Item("paths").Item("stream")
 		EndIf
	Next
	Return $iCount
EndFunc


Func AddSceneToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	; $sQuery = '{"query":"{findScene(id:' & $sID & '){title,path,file{duration},paths{stream}}}"}'		; for v16
	$sQuery = '{"query":"{findScene(id:' & $sID & '){title,files{path,basename,duration},paths{stream}}}"}'		; for v17
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oData = Json_ObjGet($oResult, "data.findScene")
	If $oData = "" Then Return 0
	; $oData.Item("title") $oData.Item("path")
	$i = UBound($aPlayList)
	ReDim $aPlayList[$i+1][3]
	If $oData.Item("title") = "" Then
		; No title yet
		$aPlayList[$i][$LIST_TITLE] = "Scene: " & $oData.Item("files")[0].Item("basename")
	Else
		; Has a title.
		$aPlayList[$i][$LIST_TITLE] = "Scene: " & $oData.Item("title")
	EndIf
	; c( "oData.title=" &  $oData.Item("title") )
	; $aPlayList[$i][$LIST_DURATION] = Floor( $oData.Item("file").Item("duration") )			; for v16
	$aPlayList[$i][$LIST_DURATION] = Floor( $oData.Item("files")[0].Item("duration") )			; for v17
	If $stashType = "Local" Then
		; $aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("path"))					; for v16
		$aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("files")[0].Item("path"))	; for v17
	ElseIf $stashType = "Remote" Then
;~ 		$sPath = $oData.Item("path")
;~ 		$sExt = StringMid( $sPath, StringInStr($sPath, ".", 1, -1) )
;~ 		$aPlayList[$i][$LIST_FILE] = $oData.Item("paths").Item("stream") & $sExt
		$aPlayList[$i][$LIST_FILE] = $oData.Item("paths").Item("stream")
	EndIf
	Return 1  ; Once scene added to the list
EndFunc

Func FixPath($sPath)
	; Fix the path returned from Stash
	; g:\myvideo\folder instead of g:myvideo\\folder
	If stringmid($sPath, 2, 1) = ":" AND stringmid($sPath, 2, 2) <> ":\" Then
		$sPath = StringLeft($sPath, 1) & ":\" & StringMid($sPath, 3)
	EndIf
	Return StringReplace($sPath, "\\", "\")
EndFunc

; Converts seconds to HH:MM:SS
Func TimeConvert($i)
	Local $iHour =  Floor($i / 3600)
	Local $iMin = Floor( ($i - 3600 * $iHour) / 60)
	Local $iSec = Mod($i, 60)
	Return StringFormat('%01d:%02d:%02d', $iHour, $iMin, $iSec)
EndFunc

; Convert the HH:MM:SS back to seconds
Func TimeConvertBack($str)
	If StringInStr($str, ":", 2) = 0 Then Return 0
	Local $aTime = StringSplit($str, ":")
	Return Int($aTime[1]) * 3600 + Int($aTime[2]) * 60 + Int($aTime[3])
EndFunc

Func GetNumber($sURL, $sCategory)
	Local $iPos1 = StringInStr($sURL, "/" & $sCategory & "/", 2)
	If $iPos1 = 0 Then Return SetError(1)
	Local $str =  StringMid($sURL, $iPos1 + StringLen($sCategory) + 2 ) ; rest of the url after /
	Local $aMatch = StringRegExp( $str, "^\d+", $STR_REGEXPARRAYMATCH )
	if @error Then Return SetError(2)

	Return $aMatch[0]
	; like "589" in string mode.
EndFunc

Func ScanFiles()
	; Scan new files in Stash
	QueryMutation('{metadataScan(input:{ useFileMetadata:true})}')
	If @error Then
		MsgBox(0, "Error", "Error sending the scan command.")
		Return SetError(1)
	EndIf

	OpenURL( $stashURL & "settings?tab=tasks" )
	MsgBox(0, "Command sent", "The scan command is sent. You can check the progress in Settings->Tasks.", 10)
EndFunc

Func PlayGroup()
	; Play the current group with external media player
	CheckMediaPlayer()
	If @error Then Return SetError(1)

	SwitchToTab("groups")
	If @error then return SetError(1)

	; Group tab found and set current
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $nGroup = GetNumber($sURL, "groups")
	PlayGroupInCurrentTab($nGroup)
EndFunc

Func CheckMediaPlayer()
	If $sMediaPlayerLocation = "" Then
		MsgBox(48,"Media player missing.","You need to set the external media player in the 'Settings' first.",0)
		Return SetError(1)
	ElseIf Not FileExists($sMediaPlayerLocation) Then
		MsgBox(48,"Media player missing.","The external media player in the 'Settings' is not valid.",0)
		Return SetError(1)
	EndIf
EndFunc

Func RefreshAllTabs()
	; This will refresh all tabs. Useful after mutations.
	Local $sCurrentTab = _WD_Window($sSession, "Window")	; Current Tab handle
	If @error <> $_WD_ERROR_Success Then $sCurrentTab = ""

	Local $aHandles = _WD_WINDOW($sSession, "Handles")
	If @error <> $_WD_ERROR_Success Or Not IsArray($aHandles) Then
		; MsgBox(48,"Error in browser.","Error retrieving browser handles.",0)
		Return SetError(1)
	EndIf

	Local $iTabCount = UBound($aHandles)
	For $i = 0 To $iTabCount-1
		; Switch to this tab
		_WD_Window($sSession, "Switch", '{"handle":"' & $aHandles[$i] & '"}' )
		_WD_Action($sSession, "refresh")
	Next
	; Switch back to the current tab
	If $sCurrentTab <> "" Then
		_WD_Window($sSession, "Switch", '{"handle":"' & $sCurrentTab & '"}' )
	EndIf
EndFunc

Func SwitchToTab($sCategory)
	; It will switch to the tab that contains the category, then return the no.
	; First check if the currrent tab is the right one
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $sSearchRegEx = "\/" & $sCategory & "\/\d+"
	If StringRegExp($sURL, $sSearchRegEx) Then
		; Current tab matches. It's a scene or group.
		Return
	EndIf
	; Not the current tab, get the scenes list
	Local $aHandles = _WD_WINDOW($sSession, "Handles")
	If @error <> $_WD_ERROR_Success Or Not IsArray($aHandles) Then
		MsgBox(48,"Error in browser.","Error retrieving browser handles.",0)
		Return SetError(1)
	EndIf
	Local $iTabCount = UBound($aHandles)
	Local $bFound = False, $i, $sURL ; With $i we can get the handle.
	For $i = 0 To $iTabCount-1
		; Switch to this tab
		_WD_Window($sSession, "Switch", '{"handle":"' & $aHandles[$i] & '"}' )
		$sURL = _WD_Action($sSession, "url")
		If StringRegExp($sURL, $sSearchRegEx) Then
			; Match. This is a scene
			$bFound = True
			ExitLoop
		EndIf
	Next
	If Not $bFound Then
		Local $sItem = StringLeft($sCategory, stringlen($sCategory)-1)
		MsgBox(48,"Cannot find the " & $sItem,"Sorry, but I cannot find the browser tab with the " & $sItem & " you want.",0)
		Return SetError(1)
	EndIf
EndFunc

Func PlayGroupInCurrentTab($nGroup)
	; Use graphql to get the scenes in groups
	$sResult = Query( '{"query": "{findGroup(id:' & $nGroup & '){scenes{files{path},paths{stream}}}}"}' )
	If @error Then Return
	Local $oData = Json_Decode($sResult)
	If Not IsObj($oData) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	; Get the scenes array
	Local $aScenes = Json_ObjGet($oData, "data.findGroup.scenes")
	c("aScenes:" & UBound($aScenes))
	Switch UBound($aScenes)
		Case 0
			; Do nothing.
		Case 1
			; Just play it.
			If $stashType = "Local" Then
				; Play the local file
				Play( $aScenes[0].Item("files")[0].Item("path") )
			ElseIf $stashType = "Remote" Then
				; Add the stream its extension
				Play( $aScenes[0].Item("paths").Item("stream") )
			EndIf
		Case Else
			; write a temp m3u file
			Local $hFile = FileOpen(@TempDir & "\StashGroup.m3u", $FO_OVERWRITE )
			If $hFile = -1 Then
				MsgBox(0, "m3u create error", "failed to create a m3u file for this group.")
				Return
			EndIf
			; First line
			FileWriteLine($hFile, "#EXTM3U")

			For $i = 0 to UBound($aScenes) - 1
				FileWriteLine($hFile, "#EXTINF:-1,")
				If $stashType = "Local" Then
					FileWriteLine($hFile, FixPath( $aScenes[$i].Item("files")[0].Item("path") )	)
				Elseif $stashType ="Remote" Then
					FileWriteLine($hFile, $aScenes[$i].Item("paths").Item("stream") )
				EndIf
			Next
			FileClose($hFile)

			; Now play the m3u file
			Play(@TempDir & "\StashGroup.m3u")
	EndSwitch
EndFunc

Func Play($sFile)
	; Use external player to play the file
	If $stashType = "Local" or stringright($sFile, 4) = ".m3u" or StringMid($sFile,2,1) == ":" Then
		$sFile = FixPath($sFile)			; Fix it if the format is slightly wrong.
		Local $sPath = StringLeft($sFile, StringInStr($sFile, "\", -1) )
		$iMediaPlayerPID = ShellExecute($sMediaPlayerLocation, Q($sFile), Q($sPath), $SHEX_OPEN)
	ElseIf $stashType = "Remote" Then
		$iMediaPlayerPID = ShellExecute($sMediaPlayerLocation, Q($sFile), "", $SHEX_OPEN)
	EndIf
	If $iMediaPlayerPID = -1 Then $iMediaPlayerPID = 0  ; error getting pid
EndFunc

Func QueryResultError($sResult)
	; the result itself says errors.
	Return StringLeft($sResult,10) = '{"errors":'
EndFunc

Func Query2($sQuery, $bIgnoreError = False )
	; This one will wrap the {"query":" "} around $sQuery. Easier to program.
 	c("QueryString:" & '{"query":"'& $sQuery& '"}')
 	$sResult = Query('{"query":"'& $sQuery& '"}', $bIgnoreError)
	If @error Then Return SetError(@error, 0, $sResult)
	Return $sResult
EndFunc

Func QueryMutation($sQuery, $bIgnoreError = False )
	; This one will wrap the {"mutation":" "} around $sQuery. Easier to program.
	if StringLower( StringLeft($sQuery, 8)) = "mutation" Then
		; Remove the "mutation" from left.
		$sQuery = StringTrimLeft($sQuery, 8)
	EndIf

	c("QueryString:" & '{"query": "mutation' & $sQuery & '"}'  )
	$sResult = Query('{"query": "mutation' & $sQuery & '"}' , $bIgnoreError)
	If @error Then Return SetError(1, 0, $sResult)
	Return $sResult
EndFunc


Func Query($sQuery, $bIgnoreError = False )
	; Use Stash's graphql to get results or do something
	If $gbUserPass And $gsApiKey = "" Then
		; It won't work. Need to set ApiKey
		c("Query without ApiKey, won't work")
		Return SetError(1)
	EndIf

	Local $hOpen = _WinHttpOpen()
	Local $hConnect = _WinHttpConnect($hOpen, $aStashURL[2], $aStashURL[3])
	If $hConnect = 0 Then
		c("error connecting to stash server.")
		; Close handles
		_WinHttpCloseHandle($hOpen)
		Return SetError(2)
	EndIf
	Local $sPath = $aStashURL[6]	; Get the start relative path
	If StringRight($sPath,1) = "/" Then $sPath = StringTrimRight($sPath,1)	; Remove the right slash

	$sPath &= "/graphql"

	; Use full http Request for query
	$hRequest = _WinHttpOpenRequest($hConnect, "POST", $sPath)
	If @error Then
		MsgBox(0, "Error opening request", "Error in opening a request to server.")
		Return SetError(3)
	EndIf

 	; Add headers
	If $gsApiKey <> "" Then
		_WinHttpAddRequestHeaders($hRequest, "ApiKey: " & $gsApiKey)
		If @error Then
			MsgBox(0, "error in request", "Error in adding apikey header to server.")
			Return SetError(4)
		EndIf
	EndIf


	_WinHttpAddRequestHeaders($hRequest, "Content-Type: application/json")
	If @error Then
		MsgBox(0, "error in request", "Error in adding content type header to server.")
		Return SetError(5)
	EndIf

	; Have to use binary way to communicate, otherwise Japanese and Chinese words will have errors!
	Local $BinQuery = StringToBinary($sQuery, $SB_UTF8)

	_WinHttpSendRequest($hRequest, Default, $BinQuery )
	If @error Then
		MsgBox(0, "error in request", "Error in sending request to server.")
		Return SetError(6)
	EndIf


	; wait for receiving response, maximum 10 seconds.
	_WinHttpReceiveResponse($hRequest)
	Local $hTimer = TimerInit()
	While _WinHttpQueryDataAvailable($hRequest) = 0
		Sleep(1)
		If TimerDiff($hTimer) > 10000 Then ExitLoop		; Wait max 10 seconds for response.
	Wend

	; Get return header
	Local $iReturnCode = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE)
	c("return header:" & $iReturnCode)
	; Get return data

	Local $binData = _WinHttpSimpleReadData($hRequest, 2)	; Read data in binary mode.


;~  	Local $sHeader = 'Content-Type: application/json'
;~  	If $gsApiKey <> "" Then $sHeader &= @CRLF & 'ApiKey: ' & $gsApiKey & @CRLF

;~  	Local $BinResult = _WinHttpSimpleRequest($hConnect, "POST", $sPath, Default, _
;~  		$BinQuery, $sHeader, Default, 2 )  ; Last one is iMode: Reading UTF-8 Text


 	Local $result = BinaryToString( $binData, $SB_UTF8)
 	c("returned result:" & $result)

 	; Close handles
	_WinHttpCloseHandle($hRequest)
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
	If $iReturnCode >= 400 Then
		c( "Error getting data from the stash server. Returned code:" & $iReturnCode)
		Return SetError(7)
	ElseIf QueryResultError($result) Then
		c("Error in the query result:" & $result)
		Return SetError(8)
	EndIf
	Return $result
EndFunc


Func PlayScene()
	; Play the current scene with external media player
	CheckMediaPlayer()
	If @error Then Return SetError(1)

;~ 	SwitchToTab("scenes")
;~ 	If @error Then Return SetError(1)

	PlayCurrentScene()
EndFunc

Func PlayCurrentTab()
	; Play the current tab's media. Can be scene/group/galery
	Local $sURL = GetURL()
	If @error Then  Return SetError(1)
	c( "Current Tab URL: " & $sURL)
	Select
		Case StringInStr($sURL, "/scenes/")
			PlayCurrentScene()
		Case StringInStr($sURL, "/groups/")
			Local $nGroup = GetNumber($sURL, "groups")
			PlayGroupInCurrentTab($nGroup)
		Case StringInStr($sURL, "/images") Or StringInStr($sURL, "/galleries/")
			CurrentImagesViewer()
		Case Else
			; The current tab is not
			MsgBox(0, "Not support", "Sorry, this operation only supports current scene/group/images/gallery.")
	EndSelect
EndFunc


Func PlayCurrentScene()
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	c( "Play current scene, URL:" & $sURL )

	Local $aMatch = StringRegExp($sURL, "\/scenes\/(\d+)\?", $STR_REGEXPARRAYMATCH )
	If @error Then Return SetError(@error)

	c("scene id:" & $aMatch[0])

	If $stashType = "Local" Then
		; $sQuery = "{findScene(id:' & $aMatch[0] & '){path}}" 			; for v16
		$sQuery = "{findScene(id:" & $aMatch[0] & "){files{path}}}"						; for v17
		c("scene query:" & $sQuery)

		; This will query the graphql and get the path info
		$sResult = Query2( $sQuery )
		If @error  Then Return SetError(1)

		Local $oData = Json_Decode($sResult)
		If @error Or Not Json_IsObject($oData) Then
			MsgBox(0, "Data error.", "The data return from stash has errors. Error:" & @error & @CRLF & "Result:" & $sResult)
			Return
		EndIf
		; Get the scenes file path and play
		; $sFile = Json_ObjGet($oData, "data.findScene.path")				; For v16
		Local $aFiles = Json_ObjGet($oData, "data.findScene.files")			; for v17
		if UBound($aFiles) =  0 Then
			MsgBox(0, "Error in files array", "Find scene returns empty file array")
			Return SetError(1)
		EndIf
		Local $sFile = $aFiles[0].Item("path")								; for v17
		If Not IsString($sFile) Then
			MsgBox(0, "Data error.", "Error getting the scene file/path.")
			Return SetError(1)
		EndIf
	ElseIf $stashType = "Remote" Then
		; Get the scene's stream as the "file"
		$sQuery = '{"query": "{findScene(id:' & $aMatch[0] & '){paths{stream}}}"}'
		c("scene query:" & $sQuery)

		; This will query the graphql and get the path info
		$sResult = Query( $sQuery )
		If @error  Then Return SetError(1)

		Local $oData = Json_Decode($sResult)
		If Not Json_IsObject($oData) Then
			MsgBox(0, "Data error.", "The data return from stash has errors.")
			Return
		EndIf
		; Get the scenes file path and play
		$sFile = Json_ObjGet($oData, "data.findScene.paths.stream")
		If Not IsString($sFile) or $sFile = "" Then
			MsgBox(0, "Data error.", "Error getting the scene stream.")
			Return SetError(1)
		EndIf
		; Get the full file name
;~ 		$sPath =  Json_ObjGet($oData, "data.findScene.path")
;~ 		If Not IsString($sPath) Then
;~ 			MsgBox(0, "Data error.", "Error getting the scene path.")
;~ 			Return SetError(1)
;~ 		EndIf
;~ 		; Get the ".mp4" or ".mkv", disable for huge performance impact on stash
;~ 		$sExt = StringMid( $sPath, StringInStr($sPath, ".", 1, -1) )
;~ 		$sFile &= $sExt
	EndIf
	Play( $sFile )

EndFunc

Func CloseSession()
	; Immediately close the web browser
	_WD_DeleteSession($sSession)
	; Close the player too if available
	If $iMediaPlayerPID <> 0 Then
		ProcessClose($iMediaPlayerPID)
	EndIf
EndFunc

Func SetupFirefox()
	If Not FileExists(@AppDataDir & "\Webdriver\" & "geckodriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("firefox", @AppDataDir & "\Webdriver" , $b64, True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'geckodriver.exe')
	Local $iPort = 4444
	_WD_Option('DriverClose', True)
	_WD_Option('Port', $iPort )
	_WD_Option('DriverParams', '--port=' &  $iPort & ' --log trace')

	; Use new UDF for capabilities
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd("firstMatch", "firefox")
	_WD_CapabilitiesAdd("browserName", "firefox")
	_WD_CapabilitiesAdd("acceptInsecureCerts", True)
	; _WD_CapabilitiesAdd("w3c", True)		; Not working any more
	; _WD_CapabilitiesAdd("excludeSwitches", "enable-automation")	; not working

	If $gsBrowserLocation <> "" Then
		_WD_CapabilitiesAdd("binary", $gsBrowserLocation )
	EndIf

	If $stashBrowserProfile = "Default" Then
		_WD_Option('DriverParams', '--marionette-port 2828')
		_WD_CapabilitiesAdd( "args", "-profile", GetDefaultFFProfile() )
	Else
		; Private profile. Do nothing for now.
	EndIf

	; _WD_CapabilitiesAdd( "args", $gsLastURL)	; Launch the last remembered URL or just stash.
	$sDesiredCapabilities = _WD_CapabilitiesGet()

	; The old way
;~ 	Switch $stashBrowserProfile
;~ 		Case "Private"
;~ 			if $gsBrowserLocation <> "" Then
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true,' _
;~ 					& '"moz:firefoxOptions":{"binary":"' & StringReplace($gsBrowserLocation, "\", "\\") & '"}' _
;~ 					& '}}}'
;~ 			Else
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
;~ 			EndIf
;~
;~ 		Case "Default"
;~ 			_WD_Option('DriverParams', '--marionette-port 2828')
;~
;~ 			If $gsBrowserLocation <> "" Then
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": { "browserName": "firefox", "acceptInsecureCerts":true, "moz:firefoxOptions": {' _
;~ 				& '"binary":"' & StringReplace($gsBrowserLocation, "\", "\\") & '",' _
;~ 				& '"args": ["-profile", "' & GetDefaultFFProfile() & '"]}}}}'
;~ 			Else
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true, "moz:firefoxOptions": {"args": ["-profile", "' & GetDefaultFFProfile() & '"]}}}}'
;~ 			EndIf
;~
;~ 	EndSwitch

EndFunc   ;==>SetupFirefox

Func GetDefaultFFProfile()
	Local $sDefault, $sProfilePath = ''

	Local $sProfilesPath = StringReplace(@AppDataDir, '\', '/') & "/Mozilla/Firefox/"
	Local $sFilename = $sProfilesPath & "profiles.ini"
	Local $aSections = IniReadSectionNames ($sFilename)

	If Not @error Then
		For $i = 1 To $aSections[0]
			$sDefault = IniRead($sFilename, $aSections[$i], 'Default', '0')
			If $sDefault = '1' Then
				$sProfilePath = $sProfilesPath & IniRead($sFilename, $aSections[$i], "Path", "")
				ExitLoop
			EndIf
		Next
	EndIf

	Return $sProfilePath
EndFunc

Func SetupChrome()
	If Not FileExists( $gsWebDriverPath & "\chromedriver.exe" ) Then
		Local $bGood = _WD_UPdateDriver ("chrome",  $gsWebDriverPath , Default, True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Chrome Driver", _
			"There is an error getting the driver for Chrome. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	If ProcessExists( "chrome.exe") Then
		$iReply = MsgBox(52,"Other Chrome Browser Is Running","This program need other Chrome browsers to close to run properly." _
					& @CRLF & "Do you want to close them now?" _
					& @CRLF & "Click Yes to force close them all. Click No to exit this program.",0)
		switch $iReply
			case 6 ;YES
				Local $iPid = ProcessExists("chrome.exe"), $iTimer = TimerInit()
				While $iPID <> 0 And TimerDiff( $iTimer ) < 20000	; give it 20 seconds.
					ProcessClose( $iPid)
					Sleep(500)
				Wend
			case 7 ;NO
				ExitScript()
		endswitch
	EndIf

	_WD_Option('Driver', $gsWebDriverPath & '\chromedriver.exe')
	_WD_Option('DriverClose', True)
	Local $iPort =  5555
	_WD_Option('Port', $iPort)
	_WD_Option('DriverParams', '--port=' & $iPort & ' --verbose --log-path="' & $gsWebDriverPath & '\chrome.log"')

	; Use new UDF for capabilities
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd("alwaysMatch", "chrome")
	_WD_CapabilitiesAdd("browserName", "chrome")
	_WD_CapabilitiesAdd("w3c", True)
	_WD_CapabilitiesAdd("excludeSwitches", "enable-automation")

	If $gsBrowserLocation <> "" Then
		_WD_CapabilitiesAdd("binary", $gsBrowserLocation )
	EndIf

	If $stashBrowserProfile = "Default" Then
		_WD_CapabilitiesAdd( "args", "--no-sandbox")
		; _WD_CapabilitiesAdd( "args", "--disable-dev-shm-usage")
		_WD_CapabilitiesAdd( "args", "--user-data-dir", GetDefaultChromeProfile() )
		_WD_CapabilitiesAdd( "args", "--profile-directory", "Default" )
	Else
		; Private profile. Do nothing for now.
	EndIf

	; _WD_CapabilitiesAdd( "args", "--app=" & $gsLastURL)	; Launch the last remembered URL or just stash.

	$sDesiredCapabilities = _WD_CapabilitiesGet()

	; The old way
;~ 	Switch $stashBrowserProfile
;~ 		Case "Private"
;~ 			If $gsBrowserLocation <> "" Then
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": {"w3c": true, ' _
;~ 					& '"binary":"' & StringReplace($gsBrowserLocation, "\", "\\") & '", ' _
;~ 					& '"excludeSwitches": [ "enable-automation"]}}}}'
;~ 			Else
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
;~ 			EndIf
;~
;~ 		Case "Default"
;~ 			If $gsBrowserLocation <> "" Then
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, ' _
;~ 					& '"binary":"' & StringReplace($gsBrowserLocation, "\", "\\") & '", ' _
;~ 					& '"excludeSwitches": [ "enable-automation"], "args":["--user-data-dir=' & GetDefaultChromeProfile() & '", "--profile-directory=Default"]}}}}'
;~ 			Else
;~ 				$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"], "args":["--user-data-dir=' & GetDefaultChromeProfile() & '", "--profile-directory=Default"]}}}}'
;~ 			EndIf
;~ 	EndSwitch
EndFunc   ;==>SetupChrome

Func GetDefaultChromeProfile()
	; return like "C:\\Users\\user\\AppData\\Local\\Google\\Chrome\\User Data\\"
	; For new UDF wd_capabilities.au3, it's not necessary. just "c:\users\user..."
	return StringReplace( @AppDataDir, "\Roaming", "\Local", 1 ) & "\Google\Chrome\User Data"
EndFunc

Func SetupEdge()
	If Not FileExists($gsWebDriverPath & "\msedgedriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("msedge", $gsWebDriverPath , $b64 , True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting MS Edge Driver", _
			"There is an error getting the driver for MS Edge. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	If ProcessExists( "msedge.exe") Then
		$iReply = MsgBox(52,"Other Edge Browser Is Running","This program need other Edge browsers to close to run properly." _
						& @CRLF & "Do you want to close them now?" _
						& @CRLF & "Click Yes to force close them all. Click No to exit this program.",0)
		switch $iReply
			case 6 ;YES
				Local $iPid = ProcessExists("msedge.exe"), $iTimer = TimerInit()
				While $iPID <> 0 And TimerDiff( $iTimer ) < 20000	; give it 20 seconds.
					ProcessClose( $iPid)
					Sleep(500)
				Wend
			case 7 ;NO
				ExitScript()
		endswitch

	EndIf

	_WD_Option('Driver', $gsWebDriverPath & "\msedgedriver.exe")
	Local $iPort = 9515
	_WD_Option('DriverClose', True)
	_WD_Option('Port', $iPort)
	_WD_Option('DriverParams', '--port=' & $iPort & ' --verbose --log-path="' & $gsWebDriverPath & '\msedge.log"')

	; Use new UDF for capabilities
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd("alwaysMatch", "msedge")
	_WD_CapabilitiesAdd("browserName", "msedge")
	_WD_CapabilitiesAdd("w3c", True)
	_WD_CapabilitiesAdd("excludeSwitches", "enable-automation")

	If $gsBrowserLocation <> "" Then
		_WD_CapabilitiesAdd("binary", $gsBrowserLocation )
	EndIf

	If $stashBrowserProfile = "Default" Then
		_WD_CapabilitiesAdd("binary", "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" )
		_WD_CapabilitiesAdd( "args", "--no-sandbox")
		_WD_CapabilitiesAdd( "args", "--user-data-dir", GetDefaultEdgeProfile() )
		_WD_CapabilitiesAdd( "args", "--profile-directory", "Default" )
	Else
		; Private profile. Do nothing for now.
	EndIf

	; _WD_CapabilitiesAdd( "args", $gsLastURL)	; Launch the last remembered URL or just stash.

	$sDesiredCapabilities = _WD_CapabilitiesGet()

	; c( "Browser Path:" & _WD_GetBrowserPath('msedge') )
	; The old way
;~ 	Switch $stashBrowserProfile
;~ 		Case "Private"
;~ 			$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "MicrosoftEdge", "ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
;~ 		Case "Default"
;~ 			$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "MicrosoftEdge", "ms:edgeOptions": {"excludeSwitches": [ "enable-automation"], "args": ["user-data-dir='& GetDefaultEdgeProfile() & '", "profile-directory=Default"]}}}}'
;~ 	EndSwitch

EndFunc   ;==>SetupEdge

Func GetDefaultEdgeProfile()
	; C:\\Users\\user\\AppData\\Local\\Microsoft\\Edge\\User Data\\
	; Local $sPath = StringReplace( @AppDataDir, "\Roaming", "\Local", 1) & "\Microsoft\Edge\User Data\"
	; Return $sPath
	Return StringReplace( @AppDataDir, "\Roaming", "\Local", 1) & "\Microsoft\Edge\User Data"
EndFunc

Func SetupOpera()
	If Not FileExists( $gsWebDriverPath & "\operadriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("opera", $gsWebDriverPath , $b64 , True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Opera Driver", _
			"There is an error getting the driver for Opera browser. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf


	_WD_Option('Driver', $gsWebDriverPath & '\operadriver.exe')
	_WD_Option('DriverClose', True)
	Local $iPort = _WD_GetFreePort( 9515, 9600 )
	_WD_Option('Port', $iPort)
	_WD_Option('DriverParams', '--port=' & $iPort & ' --verbose --log-path="' & $gsWebDriverPath & '\opera.log"')

	; Use new UDF for capabilities
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd("firstMatch", "opera")
	_WD_CapabilitiesAdd("browserName", "opera")
	_WD_CapabilitiesAdd("w3c", True)
	_WD_CapabilitiesAdd("excludeSwitches", "enable-automation")

	If $gsBrowserLocation <> "" Then
		_WD_CapabilitiesAdd("binary", $gsBrowserLocation )
	EndIf

	If $stashBrowserProfile = "Default" Then
		_WD_CapabilitiesAdd( "args", "--no-sandbox" )
		_WD_CapabilitiesAdd( "args", "--user-data-dir", GetDefaultOperaProfile() )
		_WD_CapabilitiesAdd( "args", "--profile-directory", "Default" )
	Else
		; Private profile. Do nothing for now.
	EndIf

	; _WD_CapabilitiesAdd( "args", $gsLastURL)	; Launch the last remembered URL or just stash.

	$sDesiredCapabilities = _WD_CapabilitiesGet()

EndFunc   ;==>SetupOpera

Func GetDefaultOperaProfile()
	Return @AppDataDir & '\Opera software\Opera Stable'
EndFunc


Func BrowserError($code, $sLine, $sDetails = "")
	MsgBox(48,"Oops !","Something wrong with the browser's driver. Cannot continue." _
		 & @CRLF & "WinHTTP status code:" & $code & @CRLF & "Script Line:" & $sLine & @CRLF & $sDetails & @CRLF _
		 & "Last Message From WebDrive:" &  @CRLF _
		 & GetLastHttpMessage() )
	ExitScript()
EndFunc

Func OpenURL($url)
	; Probably it's close or no windows at all.
	Local $sCurrentHandle = _WD_Window($sSession, 'Window')
	c( "current handle:" & $sCurrentHandle)
	If @error <> $_WD_ERROR_Success Then
		$sCurrentHandle = ""
	EndIf

	Local $aHandles =  _WD_Window($sSession, 'Handles')
	Local $iCount = UBound($aHandles)
	If $iCount = 0 Then
			; No browser at all, open a new window.
			$sResult = _WD_Window($sSession, "new", '{"type":"window"}' )
			c( "use new window.")
			MouseWheelClick(True)	; reset the mouse click
	Else
			; Some browser tab is still alive.
			c(" use existing window.")
			If $sCurrentHandle = "" Then
				; Handle is lost, switch to the tab in the front
				SetHandleToActiveTab()
			Else
				; if active handle is not the one in the front, switch to the front tab.
				If Not BrowserTabIsFront() Then SetHandleToActiveTab()
			EndIf
	EndIf
	_WD_Navigate($sSession, $url)
	$gsBrowserHandle = _WD_Window($sSession, "Window")
EndFunc

Func Alert($sMessage)
	; No quotes in the message.
	$sMessage = StringReplace($sMessage, "'", "`")
	$sMessage = StringReplace($sMessage, '"', "`")

	_WD_ExecuteScript($sSession, "prompt('" & $sMessage& "')", Default , True )
EndFunc

Func CreateSubMenu()
	Local $i
	; Load the data from Registry

	; Scene data
	Local $sData = RegRead($gsRegBase, "ScenesList")
	If @error Then
		; Empty. All Scenes only.
		SetMenuItem($traySceneLinks,0, 0, "All Scenes", $stashURL & "scenes")
	Else
		; Setting all the data
		; Data is like "0|All Groups|http://localhost...@crlf 1|Second Item|http:..."
		DataToArray($sData, $traySceneLinks)
	EndIf

	; Image data

	Local $sData = RegRead($gsRegBase, "ImagesList")
	If @error Then
		SetMenuItem($trayImageLinks,0, 0, "All Images", $stashURL & "images")
	Else
		DataToArray($sData, $trayImageLinks)
	EndIf

	; Group data

	Local $sData = RegRead($gsRegBase, "GroupsList")
	If @error Then
		SetMenuItem($trayGroupLinks,0 , 0, "All Groups", $stashURL & "groups")
	Else
		DataToArray($sData, $trayGroupLinks)
	EndIf

	; Marker data
	Local $sData = RegRead($gsRegBase, "MarkersList")
	If @error Then
		SetMenuItem($trayMarkerLinks,0, 0, "All Markers", $stashURL & "markers")
	Else
		DataToArray($sData, $trayMarkerLinks)
	EndIf

	; Gallery data
	Local $sData = RegRead($gsRegBase, "GalleriesList")
	If @error Then
		SetMenuItem($trayGalleryLinks,0, 0, "All Galleries", $stashURL & "galleries")
	Else
		DataToArray($sData, $trayGalleryLinks)
	EndIf

	; Performer data
	Local $sData = RegRead($gsRegBase, "PerformersList")
	If @error Then
		SetMenuItem($trayPerformerLinks,0, 0, "All Performers", $stashURL & "performers")
	Else
		DataToArray($sData, $trayPerformerLinks)
	EndIf

	; Studio data
	Local $sData = RegRead($gsRegBase, "StudiosList")
	If @error Then
		SetMenuItem($trayStudioLinks,0, 0, "All Studios", $stashURL & "studios")
	Else
		DataToArray($sData, $trayStudioLinks)
	EndIf

	; Tag data
	Local $sData = RegRead($gsRegBase, "TagsList")
	If Not @error Then
		SetMenuItem($trayTagLinks,0, 0, "All Tags", $stashURL & "tags")
	Else
		DataToArray($sData, $trayTagLinks)
	EndIf


	; Populate the scenes sub menu
	For $i = 0 To UBound($traySceneLinks) -1
		If $traySceneLinks[$i][$ITEM_TITLE] <> "" Then
			$traySceneLinks[$i][$ITEM_HANDLE] = TrayCreateItem($traySceneLinks[$i][$ITEM_TITLE], $trayMenuScenes)
		EndIf
	Next
	; Populate the images sub menu
	For $i = 0 To UBound($trayImageLinks) -1
		If $trayImageLinks[$i][$ITEM_TITLE] <> "" Then
			$trayImageLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayImageLinks[$i][$ITEM_TITLE], $trayMenuImages)
		EndIf
	Next
	; Populate the groups sub menu
	For $i = 0 To UBound($trayGroupLinks) -1
		If $trayGroupLinks[$i][$ITEM_TITLE] <> "" Then
			$trayGroupLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayGroupLinks[$i][$ITEM_TITLE], $trayMenuGroups)
		EndIf
	Next
	; Populate the markers sub menu
	For $i = 0 To UBound($trayMarkerLinks) -1
		If $trayMarkerLinks[$i][$ITEM_TITLE] <> "" Then
			$trayMarkerLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayMarkerLinks[$i][$ITEM_TITLE], $trayMenuMarkers)
		EndIf
	Next
	; Populate the galleries sub menu
	For $i = 0 To UBound($trayGalleryLinks) -1
		If $trayGalleryLinks[$i][$ITEM_TITLE] <> "" Then
			$trayGalleryLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayGalleryLinks[$i][$ITEM_TITLE], $trayMenuGalleries)
		EndIf
	Next
	; Populate the Performer sub menu
	For $i = 0 To UBound($trayPerformerLinks) -1
		If $trayPerformerLinks[$i][$ITEM_TITLE] <> "" Then
			$trayPerformerLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayPerformerLinks[$i][$ITEM_TITLE], $trayMenuPeformers)
		EndIf
	Next
	; Populate the Studio sub menu
	For $i = 0 To UBound($trayStudioLinks) -1
		If $trayStudioLinks[$i][$ITEM_TITLE] <> "" Then
			$trayStudioLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayStudioLinks[$i][$ITEM_TITLE], $trayMenuStudios)
		EndIf
	Next
	; Populate the Tag sub menu
	For $i = 0 To UBound($trayTagLinks) -1
		If $trayTagLinks[$i][$ITEM_TITLE] <> "" Then
			$trayTagLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayTagLinks[$i][$ITEM_TITLE], $trayMenuTags)
		EndIf
	Next

	; Add Custom... to the last
	$customScenes = TrayCreateItem("Customize...", $trayMenuScenes)
	$customImages = TrayCreateItem("Customize...", $trayMenuImages)
	$customGroups = TrayCreateItem("Customize...", $trayMenuGroups)
	$customMarkers = TrayCreateItem("Customize...", $trayMenuMarkers)
	$customGalleries = TrayCreateItem("Customize...", $trayMenuGalleries)
	$customPerformers = TrayCreateItem("Customize...", $trayMenuPeformers)
	$customStudios = TrayCreateItem("Customize...", $trayMenuStudios)
	$customTags = TrayCreateItem("Customize...", $trayMenuTags)

EndFunc

Func ReloadMenu($sCategory)
	; Delete all sub-menu items
	; DeleteAllSubMenu()
	; Recreate all sub-menu items
	; CreateSubMenu()
	$sCategory = StringLower($sCategory)
	Switch $sCategory
		Case "scenes"
			TrayItemDelete($customScenes)
			ReloadSubMenu($sCategory, $traySceneLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuScenes)

		Case "images"
			TrayItemDelete($customImages)
			ReloadSubMenu($sCategory, $trayImageLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuImages)

		Case "groups"
			TrayItemDelete($customGroups)
			ReloadSubMenu($sCategory, $trayGroupLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuGroups)

		Case "markers"
			TrayItemDelete($customMarkers)
			ReloadSubMenu($sCategory, $trayMarkerLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuMarkers)

		Case "galleries"
			TrayItemDelete($customGalleries)
			ReloadSubMenu($sCategory, $trayGalleryLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuGalleries)

		Case "performers"
			TrayItemDelete($customPerformers)
			ReloadSubMenu($sCategory, $trayPerformerLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuPeformers)

		Case "Studios"
			TrayItemDelete($customStudios)
			ReloadSubMenu($sCategory, $trayStudioLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuStudios)

		Case "tags"
			TrayItemDelete($customTags)
			ReloadSubMenu($sCategory, $trayTagLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuTags)

	EndSwitch

EndFunc

Func ReloadSubMenu($sCategory, ByRef $aArray)
	; $sCategory is like "groups","scenes"...
	; Make the first one capital letter.
	Local $sCat = StringUpper(stringleft($sCategory, 1)) & StringMid($sCategory, 2)
	; Delete all the submenu items
	For $i = 0 To UBound($aArray) -1
		If $aArray[$i][$ITEM_HANDLE] <> Null Then
			TrayItemDelete($aArray[$i][$ITEM_HANDLE])
		EndIf
		$aArray[$i][$ITEM_TITLE] = ""
	Next

	; Load data from registry.
	Local $sData = RegRead($gsRegBase, $sCat & "List")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($aArray,0, 0, "All " & $sCat, $stashURL & $sCategory)
	Else
		; Setting all the data after "All Groups/Scenes..."
		; Data is like "0|All Groups|http://localhost...@@@1|Second Item|http:..."
		DataToArray($sData, $aArray)
	EndIf
	; Now $aArray is like [1][null][Title1][Link1],[2][null][title2][link2]...
		; Populate the scenes sub menu

	For $i = 0 To UBound($aArray) -1
		If $aArray[$i][$ITEM_TITLE] <> "" Then
			$aArray[$i][$ITEM_HANDLE] = TrayCreateItem($aArray[$i][$ITEM_TITLE], GetMenuHandle($sCategory) )
		EndIf
	Next

EndFunc

Func GetMenuHandle($sCategory)
	Switch StringLower( $sCategory)
		Case "scenes"
			Return $trayMenuScenes
		Case "images"
			Return  $trayMenuImages
		Case "groups"
			Return  $trayMenuGroups
		Case "markers"
			Return $trayMenuMarkers
		Case "galleries"
			Return  $trayMenuGalleries
		Case "performers"
			Return  $trayMenuPeformers
		Case "studios"
			Return  $trayMenuStudios
		Case "tags"
			Return  $trayMenuTags
		Case Else
			Return SetError(1)
	EndSwitch

EndFunc

Func DeleteAllSubMenu()
	; Delete Scenes submenu
	For $i = 0 to UBound($traySceneLinks)-1
		If $traySceneLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($traySceneLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customScenes)

	; Delete images submenu
	For $i = 0 to UBound($trayImageLinks)-1
		If $trayImageLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayImageLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customImages)

	; Delete Groups submenu
	For $i = 0 to UBound($trayGroupLinks)-1
		If $trayGroupLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayGroupLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customGroups)

	; Delete Markers submenu
	For $i = 0 to UBound($trayMarkerLinks)-1
		If $trayMarkerLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayMarkerLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customMarkers)

	; Delete Galleries submenu
	For $i = 0 to UBound($trayGalleryLinks)-1
		If $trayGalleryLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayGalleryLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customGalleries)

	; Delete performers submenu
	For $i = 0 to UBound($trayPerformerLinks)-1
		If $trayPerformerLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayPerformerLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customPerformers)

	; Delete studios submenu
	For $i = 0 to UBound($trayStudioLinks)-1
		If $trayStudioLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayStudioLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customStudios)

	; Delete tags submenu
	For $i = 0 to UBound($trayTagLinks)-1
		If $trayTagLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayTagLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customTags)

EndFunc

Func DataToArray($sData, ByRef $aLink)
	; Data is like "1|All Groups|http://localhost...@@@2|Second Item|http:..."
	; Data in $aLink will be changed.
	Local $aLines = StringSplit($sData, "@@@", $STR_ENTIRESPLIT + $STR_NOCOUNT)
	If @error Then Return SetError(1)

	For $i = 0 To $iMaxSubItems-1
		If $i < UBound($aLines) Then
			; c("Line:" & $aLines[$i])
			Local $aItem = StringSplit($aLines[$i], "|", $STR_NOCOUNT)
			If UBound($aItem) = 3 Then
				$aLink[$i][$ITEM_TITLE] = $aItem[$ITEM_TITLE]
				$aLink[$i][$ITEM_LINK] = $aItem[$ITEM_LINK]
			Else
				$aLink[$i][$ITEM_TITLE] = ""
				$aLink[$i][$ITEM_LINK] = ""
			EndIf
		Else
			; Clean up the data no longer used
			$aLink[$i][$ITEM_HANDLE] = Null
			$aLink[$i][$ITEM_TITLE] = ""
			$aLink[$i][$ITEM_LINK] = ""
		EndIf
	Next
EndFunc

Func SetMenuItem(ByRef $aItem, $index, $handle, $Title, $Link)
	$aItem[$index][$ITEM_HANDLE] = $handle
	$aItem[$index][$ITEM_TITLE] = $Title
	$aItem[$index][$ITEM_LINK] = $Link
EndFunc

Func Q($str)
	; Double quote the $str
	Return '"' & $str & '"'
EndFunc

Func Q2($str)
	; Double slash quote the str
	Return '\"' & $str & '\"'
EndFunc

Func ExitScript()
	If $giSaveLastURL and $sSession Then
		If CurrentBrowserWinHandle() <> 0 Then
			; The browser is still running.
			$sURL = GetURL()
			If @error Then
				RegWrite($gsRegBase, "LastURL", "REG_SZ", $stashURL )
			Else
				RegWrite($gsRegBase, "LastURL", "REG_SZ", $sURL )
			EndIf
		EndIf
	EndIf

	if $sSession Then
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf

	If $iStashPID <> 0 And $gbRunStashFromHelper Then
		If ProcessExists($iStashPID) Then ProcessClose($iStashPID)
	EndIf

	If $iConsolePID <> 0 And $gbRunStashFromHelper Then
		ProcessClose($iConsolePID)
	EndIf

	If $pidDebugConsole And ProcessExists($pidDebugConsole) Then ProcessClose($pidDebugConsole)

	Exit
EndFunc   ;==>ExitScript

Func c($str, $script=@ScriptName, $iLine = @ScriptLineNumber)
	$sLine = StringTrimRight($script,4) & " #" & $iline & " " & StringLeft($str,300) & @CRLF
	ConsoleWrite($sLine)
	if $pidDebugConsole Then
		StdinWrite( $pidDebugConsole, $sLine)
		If @error Then
			ConsoleWrite( "Error in writing to debug console")
			$pidDebugConsole = ""
		EndIf
	EndIf
EndFunc

Func _IsIP($ip)
	; Return true if $ip is like 1.2.3.4
    Return StringRegExp ($ip, "^(?:(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(?1)$")
EndFunc
Func MsgExit($str)
	; For serious problems that has to exit.
	MsgBox(16,"Error !",$str,0)
	ExitScript()
EndFunc
#EndRegion Functions
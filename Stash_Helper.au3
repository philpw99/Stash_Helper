;*****************************************
;Stash_Helper.au3 by Philip Wang
;Created with ISN AutoIt Studio v. 1.13
;*****************************************
#include <FileConstants.au3>
#include <TrayConstants.au3>
; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <GuiTab.au3>
#include <EditConstants.au3>
#include <wd_core.au3>
#include <wd_helper.au3>
#include <Forms\InitialSettingsForm.au3>
#include "TrayMenuEx.au3"

; If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")

DllCall("User32.dll","bool","SetProcessDPIAware")

Global Const $currentVersion = "v1.3"

; This already declared in Custom.au3
Global Enum $ITEM_HANDLE, $ITEM_TITLE, $ITEM_LINK
Global Const $iMaxSubItems = 11

TraySetIcon("helper2.ico")

#Region Globals Initialization
Opt("TrayAutoPause", 0)  ; No pause in tray
; Opt("TrayOnEventMode", 1) ; Enable tray on event mode. NO,NO, DON'T DO IT!

; Remove the trailing (x86) for 64bit windows
Global $sProgramFilesDir = ( @OSArch = "X64" ) ? StringReplace(@ProgramFilesDir, " (x86)", "", 1, 2) : @ProgramFilesDir

Global $stashFilePath = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath")
If @error Or Not FileExists($stashFilePath) Then
	; First time run this program. Need to set the settings.
	InitialSettingsForm()
EndIf

Global $stashBrowser = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser")

Global $showStashConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowStashConsole")
If @error Then $showStashConsole = 0
Global $showWDConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowWDConsole")
if @error Then $showWDConsole = 0

Global $sDesiredCapabilities, $sSession
Global $stashVersion, $stashURL
Global $sMediaPlayerLocation = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "MediaPlayerLocation")

Local $sIconPath = @ScriptDir & "\images\icons\"
Local $hIcons[13]	; 13 (0-12) bmps  for the tray menus
For $i = 0 to 12
	$hIcons[$i] = _LoadImage($sIconPath & $i & ".bmp", $IMAGE_BITMAP)
Next

#include <Forms\SettingsForm.au3>
#include <Forms\CustomForm.au3>
#include <Forms\ScrapersForm.au3>

; Now this is running in the tray
; First run the Stash-Win program $sStashPath

; Attach to an existing stash-win first.
Global $iStashPID = WinGetProcess("stash-win.exe")
If $iStashPID = -1 Then
	; Stash not running.
	Local $sPath = StringLeft($stashFilePath, StringInStr($stashFilePath, "\", 2, -1) )
	If $showStashConsole Then
		; Show the stash console.
		$iStashPID = Run($stashFilePath, $sPath, @SW_SHOW)
		$stashURL = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL")
		If @error Then $stashURL = "http://localhost:9999/"  ; Last resort
	Else
		; Hide the stash console. First time run, it will always hide it so we can read the stash url.
		$iStashPID = Run($stashFilePath, $sPath, @SW_HIDE, $STDERR_MERGED)

		$hTimer = TimerInit()
		While True
			Local $sLine = StdoutRead($iStashPID)
			If @error Then
				; Stash App is closed.
				Exit
			EndIf
			If $sLine <> "" Then
				c("*" & $sLine)
			EndIf
			Select
				Case StringInStr($sLine, "stash version:", 2)
					$stashVersion = StringMid($sLine, StringInStr($sLine, "stash version:", 2))
					$stashVersion = StringStripWS($stashVersion, $STR_STRIPTRAILING)
				Case StringInStr($sLine, "stash is running at ")
					$iPos1 = StringInStr($sLine, "http", 2)
					$iPos2 = StringInStr($sLine, " ", 2, 1, $iPos1 + 7)  ; Use space as the end.
					$stashURL = StringMid($sLine, $iPos1, $iPos2 -$iPos1)
					$stashURL = StringStripWS($stashURL, $STR_STRIPTRAILING)
					; Now time to jump to the next phrase.
					$sURL = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL")
					If $sURL <> $stashURL Then
						RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL", "REG_SZ", $stashURL)
					EndIf
					ExitLoop
			EndSelect
			; 10 seconds max for this loop
			If TimerDiff($hTimer)> 10000 Then
				; Something is wrong.
				MsgBox(48,"Error launching StashApp", _
					"It takes too long to get StashApp ready. Something is wrong. Exiting.",20)
				Exit
			EndIf
			Sleep(100)
		Wend
	EndIf
Else
	; Stash already running.
	$stashURL = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL")
	If @error Then $stashURL = "http://localhost:9999/"  ; Last resort
EndIf

Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected.
; Now create the top level tray menu items.
If $stashVersion <> "" Then
	TrayTip("Stash is Active", $stashVersion, 5, $TIP_ICONASTERISK+$TIP_NOSOUND  )
EndIf

TrayCreateItem("Stash Helper " & $currentVersion )  					; 0
TrayCreateItem("")										; 1

Global $trayMenuScenes = TrayCreateMenu("Scenes")		; 2
_TrayMenuAddImage($hIcons[0], 2)
Global $trayMenuImages = TrayCreateMenu("Images")		; 3
_TrayMenuAddImage($hIcons[1], 3)
Global $trayMenuMovies = TrayCreateMenu("Movies")		; 4
_TrayMenuAddImage($hIcons[2], 4)
Global $trayMenuMarkers = TrayCreateMenu("Markers")		; 5
_TrayMenuAddImage($hIcons[3], 5)
Global $trayMenuGalleries = TrayCreateMenu("Galleries")	; 6
_TrayMenuAddImage($hIcons[4], 6)
Global $trayMenuPeformers = TrayCreateMenu("Performers"); 7
_TrayMenuAddImage($hIcons[5], 7)
Global $trayMenuStudios = TrayCreateMenu("Studios")		; 8
_TrayMenuAddImage($hIcons[6], 8)
Global $trayMenuTags = TrayCreateMenu("Tags")			; 9
_TrayMenuAddImage($hIcons[7], 9)
TrayCreateItem("")										; 10
Global $trayPlayScene = TrayCreateItem("Play Current Scene") ;11
GUICtrlSetTip(-1, "Play the current scene with external media player specified in the settings.")
_TrayMenuAddImage($hIcons[12], 11)
Global $trayScrapers = TrayCreateItem("Scrapers Manager");12
GUICtrlSetTip(-1,"Install or remove website scrapers used by Stash.")
_TrayMenuAddImage($hIcons[8], 12)
Global $traySettings = TrayCreateItem("Settings")		; 13
_TrayMenuAddImage($hIcons[9], 13)
TrayCreateItem("")										; 14
Global $trayAbout = TrayCreateItem("About")				; 15
_TrayMenuAddImage($hIcons[10], 15)
Global $trayExit = TrayCreateItem("Exit")				; 16
_TrayMenuAddImage($hIcons[11], 16)

; No need for those icons any more
_IconDestroy($hIcons)

; Now sub menu items. 0 is the handle, 1 is title, 2 is the link
Global $traySceneLinks[$iMaxSubItems][3]
Global $trayImageLinks[$iMaxSubItems][3]
Global $trayMovieLinks[$iMaxSubItems][3]
Global $trayMarkerLinks[$iMaxSubItems][3]
Global $trayGalleryLinks[$iMaxSubItems][3]
Global $trayPerformerLinks[$iMaxSubItems][3]
Global $trayStudioLinks[$iMaxSubItems][3]
Global $trayTagLinks[$iMaxSubItems][3]

Global $customScenes, $customImages, $customMovies, $customMarkers, $customGalleries
Global $customPerformers, $customStudios, $customTags

; Now get WebDriver Ready

; Hide the console, OR NOT
If Not $showWDConsole Then
	$_WD_DEBUG = $_WD_DEBUG_None
EndIf

Switch $stashBrowser
	Case "Firefox"
		SetupFirefox()
	Case "Chrome"
		SetupChrome()
	Case "Edge"
		SetupEdge()
	Case Else
		$stashBrowser = "Edge"
		SetupEdge()  ; Edge is more universally available.
EndSwitch

; Slow down a bit here, or the web driver is not ready.
Sleep(1000)

Global $iConsolePID = _WD_Startup()
If @error <> $_WD_ERROR_Success Then BrowserError(@extended)

$sSession = _WD_CreateSession($sDesiredCapabilities)
If @error <> $_WD_ERROR_Success Then BrowserError(@extended)

Global $sBrowserHandle

#EndRegion Globals

#Region Tray Menu Handling

CreateSubMenu()

TraySetState($TRAY_ICONSTATE_SHOW)
; Launch the web page
OpenURL($stashURL)
HotKeySet("^{ENTER}", "CloseSession")
; Looping to get message
While True
	$nMsg = TrayGetMsg()
	Switch $nMsg
		Case 0
			; Nothing should be here, but Case 0 here is very necessary.
		Case $trayAbout
			MsgBox(64,"Stash Helper " & $currentVersion,"Stash helper " & $currentVersion & ", written by Philip Wang, at your service." _
				& @CRLF & "Hopefully this little program will make you navigate the powerful Stash App more easily." _
				& @CRLF & "Kudos to the great Stash App team ! kermieisinthehouse, WithoutPants, bnkai ... and all other great contributors working for this huge project." _
				& @CRLF & "Kudos also go to Christian Faderl's ISN AutoIt Studio! It's such a powerful AutoIt IDE, which making this program much easier to write." _
				& @CRLF & "Also thanks to InstallForge.net for providing me such an easy-to-build installer!" ,20)
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
		Case $customMovies
			CustomList("Movies", $trayMovieLinks)
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
		Case $trayPlayScene
			PlayCurrentScene()
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
			For $i = 0 to UBound($trayMovieLinks)-1
				If $trayMovieLinks[$i][$ITEM_HANDLE] = $nMsg Then
					OpenURL($trayMovieLinks[$i][$ITEM_LINK])
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
	EndSwitch
Wend
Exit

#EndRegion Tray menu

#Region Functions

Func PlayCurrentScene()
	; Play the current scene with external media player
	If $sMediaPlayerLocation = "" Then 
		MsgBox(48,"Media player missing.","You need to set the external media player in the 'Settings' first.",0)
		Return
	ElseIf Not FileExists($sMediaPlayerLocation) Then 
		MsgBox(48,"Media player missing.","The external media player in the 'Settings' is not valid.",0)
		Return
	EndIf
	
	; First check the current tab is a scene.
	$sURL = _WD_Action($sSession, "url")
	If StringRegExp($sURL, "\/scenes\/\d+\?") Then 
		ClickAndPlay()
		Return 
	EndIf 
	; Not the current tab, get the scenes list
	Local $aHandles = _WD_WINDOW($sSession, "Handles")
	If @error <> $_WD_ERROR_Success Or Not IsArray($aHandles) Then 
		MsgBox(48,"Error in browser.","Error retrieving browser handles.",0)
		Return
	EndIf
	Local $iTabCount = UBound($aHandles)
	Local $bFound = False, $i, $sURL ; With $i we can get the handle.
	For $i = 0 To $iTabCount-1
		; Switch to this tab
		_WD_Window($sSession, "Switch", '{"handle":"' & $aHandles[$i] & '"}' )
		$sURL = _WD_Action($sSession, "url")
		If StringRegExp($sURL, "\/scenes\/\d+\?") Then 
			; Match. This is a scene
			$bFound = True
			ExitLoop 
		EndIf
	Next
	If Not $bFound Then 
		MsgBox(48,"Where is the scene?","Sorry, but I cannot find the browser tab with the scene you want to play.",0)
		Return 
	Else 
		; Found the scene, handle it now.
		ClickAndPlay()
	EndIf
EndFunc

Func ClickAndPlay()
	; This will click the "File Info" and get the info we need and play the file
	_WD_LinkClickByText($sSession, "File Info", False)  ; Click the "File Info", not partial search.
	If @error <> $_WD_ERROR_Success Then 
		MsgBox(48,"Oops !","Sorry, but I cannot find the 'File Info' link in the web page.",0)
		Return 
	EndIf
	Sleep(1000) ; Let the javascript works
	$sDivID = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[contains(text(),'file://')]" )
	If @error <> $_WD_ERROR_Success Then 
		MsgBox(48,"Oops !","Sorry, but I cannot find the file element in the web page.",0)
		Return 
	EndIf
	Local $sFileURL = _WD_ElementAction($sSession, $sDivID, "Text")
	If @error <> $_WD_ERROR_Success Then 
		MsgBox(48,"Oops !","Sorry, but I cannot get the file location in the web page.",0)
		Return 
	EndIf
	; Now this will be pure file path and name
	$sFileURL = StringReplace($sFileURL, "file://", "", 1, 2)
	Local $sFilePath = StringLeft($sFileURL, StringInStr($sFileURL, "\", -1) )
	ShellExecute($sMediaPlayerLocation, Q($sFileURL), $sFilePath, $SHEX_OPEN)
EndFunc

Func CloseSession()
	; Immediately close the web browser
	_WD_DeleteSession($sSession)
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
	_WD_Option('DriverClose', True)
	_WD_Option('DriverParams', '--log trace')
	_WD_Option('Port', 4444)

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
EndFunc   ;==>SetupGecko

Func SetupChrome()
	If Not FileExists( @AppDataDir & "\Webdriver\" & "chromedriver.exe") Then
		Local $bGood = _WD_UPdateDriver ("chrome", @AppDataDir & "\Webdriver" , Default, True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'chromedriver.exe')
	_WD_Option('DriverClose', True)
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @AppDataDir & "\Webdriver\chrome.log")

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
EndFunc   ;==>SetupChrome

Func SetupEdge()
	If Not FileExists(@AppDataDir & "\Webdriver\" & "msedgedriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("msedge", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf


	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'msedgedriver.exe')
	_WD_Option('DriverClose', True)
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @AppDataDir & "\Webdriver\msedge.log")

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
EndFunc   ;==>SetupEdge

Func BrowserError($code)
	MsgBox(48,"Oops !","Something wrong with the browser's driver. Cannot continue." _
		 & @CRLF & "WinHTTP status code:" & $code,0)
	If $sSession Then _WD_DeleteSession($sSession)
	_WD_Shutdown()
	ExitScript()
EndFunc

Func OpenURL($url)
	$sBrowserHandle = _WD_Window($sSession, "Window")
	If $sBrowserHandle = "" Then
		; The session is invalid.
		$sSession = _WD_CreateSession($sDesiredCapabilities)
	EndIf

	_WD_Navigate($sSession, $url)
EndFunc

Func Alert($sMessage)
	; No quotes in the message.
	$sMessage = StringReplace($sMessage, "'", "`")
	$sMessage = StringReplace($sMessage, '"', "`")

	_WD_ExecuteScript($sSession, "alert('" & $sMessage& "')", Default , True )
EndFunc

Func CreateSubMenu()
	Local $i
	; Load the data from Registry

	; Scene data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ScenesList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($traySceneLinks,0, 0, "All Scenes", $stashURL & "scenes")
	Else
		; Setting all the data
		; Data is like "0|All Movies|http://localhost...@crlf 1|Second Item|http:..."
		DataToArray($sData, $traySceneLinks)
	EndIf

	; Image data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ImagesList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayImageLinks,0, 0, "All Images", $stashURL & "images")
	Else
		DataToArray($sData, $trayImageLinks)
	EndIf

	; Movie data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "MoviesList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayMovieLinks,0 , 0, "All Movies", $stashURL & "movies")
	Else
		DataToArray($sData, $trayMovieLinks)
	EndIf

	; Marker data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "MarkersList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayMarkerLinks,0, 0, "All Markers", $stashURL & "markers")
	Else
		DataToArray($sData, $trayMarkerLinks)
	EndIf

	; Gallery data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "GalleriesList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayGalleryLinks,0, 0, "All Galleries", $stashURL & "galleries")
	Else
		DataToArray($sData, $trayGalleryLinks)
	EndIf

	; Performer data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "PerformersList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayPerformerLinks,0, 0, "All Performers", $stashURL & "performers")
	Else
		DataToArray($sData, $trayPerformerLinks)
	EndIf

	; Studio data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StudiosList")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($trayStudioLinks,0, 0, "All Studios", $stashURL & "studios")
	Else
		DataToArray($sData, $trayStudioLinks)
	EndIf

	; Tag data
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "TagsList")
	If @error Then
		; No data yet. Set the first item in array
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
	; Populate the movies sub menu
	For $i = 0 To UBound($trayMovieLinks) -1
		If $trayMovieLinks[$i][$ITEM_TITLE] <> "" Then
			$trayMovieLinks[$i][$ITEM_HANDLE] = TrayCreateItem($trayMovieLinks[$i][$ITEM_TITLE], $trayMenuMovies)
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
	$customMovies = TrayCreateItem("Customize...", $trayMenuMovies)
	$customMarkers = TrayCreateItem("Customize...", $trayMenuMarkers)
	$customGalleries = TrayCreateItem("Customize...", $trayMenuGalleries)
	$customPerformers = TrayCreateItem("Customize...", $trayMenuPeformers)
	$customStudios = TrayCreateItem("Customize...", $trayMenuStudios)
	$customTags = TrayCreateItem("Customize...", $trayMenuTags)

EndFunc

Func ReloadMenu()
	; Delete all sub-menu items
	DeleteAllSubMenu()
	; Recreate all sub-menu items
	CreateSubMenu()
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

	; Delete Movies submenu
	For $i = 0 to UBound($trayMovieLinks)-1
		If $trayMovieLinks[$i][$ITEM_HANDLE] Then
			TrayItemDelete($trayMovieLinks[$i][$ITEM_HANDLE])
		EndIf
	Next
	TrayItemDelete($customMovies)

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
	; Data is like "0|All Movies|http://localhost...@crlf 1|Second Item|http:..."
	; Data in $aLink will be changed.
	$aLines = StringSplit($sData, "@@@", $STR_ENTIRESPLIT + $STR_NOCOUNT)

	For $i = 0 To UBound($aLines)-1
		; c("Line:" & $aLines[$i])
		$aItem = StringSplit($aLines[$i], "|", $STR_NOCOUNT)
		$aLink[$i][$ITEM_TITLE] = $aItem[$ITEM_TITLE]
		$aLink[$i][$ITEM_LINK] = $aItem[$ITEM_LINK]
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

Func ExitScript()
	If $iStashPID Then ProcessClose($iStashPID)
	if $sSession Then
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf
	Exit
EndFunc   ;==>ExitScript

Func c($str)
	ConsoleWrite($str & @CRLF)
EndFunc
#EndRegion Functions
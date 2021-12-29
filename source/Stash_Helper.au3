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
#include <Array.au3>

; opt("MustDeclareVars", 1)

#include <Forms\InitialSettingsForm.au3>
#include "DTC.au3"
#include "URL_Encode.au3"
#include "TrayMenuEx.au3"


If AlreadyRunning() Then
	MsgBox(48,"Stash Helper is still running.","Stash Helper is still running. Maybe it had an error and froze. " & @CRLF _
		& "You can use the 'task manager' to close it." & @CRLF _
		& "I don't recommend running two Stash Helper at the same time.",0)
	Exit
EndIf


; If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")

DllCall("User32.dll","bool","SetProcessDPIAware")

Global Const $currentVersion = "v2.2.4"

Global $sAboutText = "Stash helper " & $currentVersion & ", written by Philip Wang." _
				& @CRLF & "Hopefully this little program will make you navigate the powerful Stash App more easily." _
				& @CRLF & "Kudos to the great Stash App team ! kermieisinthehouse, WithoutPants, bnkai ... and all other great contributors working for this huge project." _
				& @CRLF & "Kudos also go to Christian Faderl's ISN AutoIt Studio! It's such a powerful AutoIt IDE, which making this program much easier to write." _
				& @CRLF & "Also thanks to InstallForge.net for providing me such an easy-to-build installer!" _
				& @CRLF & "Special thanks to BViking78 for the numerous pieces of advice," _
				& @CRLF & "and thank you gamerjax for your play list suggestions!" _
				& @CRLF & "Wraithstalker90, you made my program more solid, thank you !"


; This already declared in Custom.au3
Global Enum $ITEM_HANDLE, $ITEM_TITLE, $ITEM_LINK
Global Const $iMaxSubItems = 20
Global $iMediaPlayerPID = 0
; For Play list
Global Enum $LIST_TITLE, $LIST_DURATION, $LIST_FILE
Global $aPlayList[0][3]

TraySetIcon("helper2.ico")

#Region Globals Initialization
Opt("TrayAutoPause", 0)  ; No pause in tray
; Opt("TrayOnEventMode", 1) ; Enable tray on event mode. NO,NO, DON'T DO IT!

; Remove the trailing (x86) for 64bit windows
Global $sProgramFilesDir = ( @OSArch = "X64" ) ? StringReplace(@ProgramFilesDir, " (x86)", "", 1, 2) : @ProgramFilesDir

Global $stashFilePath = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath")
Global $stashPath = stringleft($stashFilePath, StringInStr($stashFilePath, "\", 2, -1))

If @error Or Not FileExists($stashFilePath) Then
	; First time run this program. Need to set the settings.
	InitialSettingsForm()
EndIf

; For v0.11 and above. Disable the browser from autostart
Global $sFileConfig = stringleft( $stashFilePath, stringinstr($stashFilePath, "\", 2, -1) ) & "config.yml"
Global $sNoBrowser = ""
If FileExists($sFileConfig) Then
	Local $sConfigContent = FileRead($sFileConfig)
	; If exist this setting, then it's v0.11 and above
	If StringInStr($sConfigContent, "autostart_video:", 2) <> 0 Then
		$sNoBrowser = " --nobrowser"
	EndIf
EndIf

Global $stashBrowser = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser")

Global $showStashConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowStashConsole")
If @error Then $showStashConsole = 0
Global $showWDConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowWDConsole")
if @error Then $showWDConsole = 0

Global $sDesiredCapabilities, $sSession
Global $stashVersion, $stashURL
Global $sMediaPlayerLocation = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "MediaPlayerLocation")

Global $iSlideShowSeconds = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "SlideShowSeconds")
if @error Then
	$iSlideShowSeconds = 10
	RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "SlideShowSeconds", "REG_DWORD", 10)
EndIf

Local $sIconPath = @ScriptDir & "\images\icons\"
Local $hIcons[21]	; 20 (0-19) bmps  for the tray menus
For $i = 0 to 20
	$hIcons[$i] = _LoadImage($sIconPath & $i & ".bmp", $IMAGE_BITMAP)
Next

; For SceneToMovieForm.
Global $mInfo = ObjCreate("Scripting.Dictionary")
If @error Then MsgExit("Error Creating global $minfo object.")

; All forms.
#include <Forms\SettingsForm.au3>
#include <Forms\CustomizeForm.au3>
#include <Forms\ScrapersForm.au3>
#include <Forms\SceneToMovieForm.au3>
#include <Forms\ManagePlayListForm.au3>
; Seems special scraper is no longer needed when visible CDP works much better.
; #include <Forms\ScrapeSpecial2Form.au3>

; Now this is running in the tray
; First run the Stash-Win program $sStashPath
Global $iStashPID
$stashURL = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL")

If $stashURL = "" Then
	; Never have $stashURL before. Run it for the first time.
	$iStashPID = ProcessExists("stash-win.exe")
	If $iStashPID <> 0 Then ProcessClose($iStashPID) ; Just in case.
	; Run it for the first time. Merged.
	$iStashPID = Run($stashFilePath & $sNoBrowser, $stashPath, @SW_HIDE, $STDERR_MERGED)
	Local $hTimer = TimerInit()
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
				Local $iPos1 = StringInStr($sLine, "http", 2)
				Local $iPos2 = StringInStr($sLine, " ", 2, 1, $iPos1 + 7)  ; Use space as the end.
				$stashURL = StringMid($sLine, $iPos1, $iPos2 -$iPos1)
				$stashURL = StringStripWS($stashURL, $STR_STRIPTRAILING)
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL", "REG_SZ", $stashURL)
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
Else
	; StashURL already saved.
	Local $aStr = StringRegExp($stashURL, "\:\/\/(.*)\:(\d+)", $STR_REGEXPARRAYMATCH )
	Local $sHost = $aStr[0], $sPort = $aStr[1]
	If $sHost = "localhost" Then
		$iStashPID = ProcessExists("stash-win.exe")
		If $iStashPID = 0 Then
			; Not running.
			If $showStashConsole Then
				$iStashPID = Run($stashFilePath & $sNoBrowser, $stashPath, @SW_SHOW)
			Else
				$iStashPID = Run($stashFilePath & $sNoBrowser, $stashPath, @SW_HIDE)
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

; This must run after $stashURL
#include "URLtoQuery.au3"
#include "CurrentImagesViewer.au3"

Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected.
; Now create the top level tray menu items.

; Use query to get the version
Local $sResult = Query('{"query":"{version{version,hash}}"}')
If Not @error Then
	; Query and Get current version.
	Local $oResult = Json_Decode($sResult)
	If IsObj($oResult) Then
		Local $oVersion = Json_ObjGet($oResult, "data.version")
		$stashVersion = $oVersion.Item("version")
		Local $stashVersionHash = $oVersion.Item("hash")

		; Now get the latest version. Only above 0.11
		$sResult = Query('{"query":"{latestversion{shorthash,url}}"}')
		If Not @error Then
			; Successfully get the info about latest version.
			$oResult = Json_Decode($sResult)
			If IsObj($oResult) Then
				Local $oLatestVersion = Json_ObjGet($oResult, "data.latestversion")
				Local $sLatestVersionHash = $oLatestVersion.Item("shorthash")
				Local $sLatestVersionURL = $oLatestVersion.Item("url")
				Local $sIgnoreHash = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "IgnoreHash")
				; c( "Latest Version Hash:" & $sLatestVersionHash & " VersionHash:" & $stashVersionHash & " latestVersionURL:" & $sLatestVersionURL)
				If $sLatestVersionHash <> $stashVersionHash And $sLatestVersionHash <> $sIgnoreHash Then
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
								ProcessClose($iStashPID)
								InetGet($sLatestVersionURL, @TempDir & "\stash-win.exe" )
								If Not @error Then
									$stashVersion = ""
									; Download successful.
									FileDelete($stashFilePath)
									FileMove(@TempDir & "\stash-win.exe", $stashFilePath, $FC_OVERWRITE)
									; Run it now.
									If $showStashConsole Then
										$iStashPID = Run($stashFilePath & $sNoBrowser, $stashPath, @SW_SHOW)
									Else
										$iStashPID = Run($stashFilePath & $sNoBrowser, $stashPath, @SW_HIDE)
									EndIf
								EndIf
							case 7 ;NO, ignore.
								RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "IgnoreHash", "REG_SZ", $sLatestVersionHash)
							case 2 ;CANCEL
						endswitch
					EndIf 
				EndIf
			EndIf ; End of if $oResult is object.
		EndIf ; End of Query latest version no error
	EndIf ; End of if $oResult is object
Else
	; Error getting version
	c("Version result:" & $sResult)
EndIf

If $stashVersion <> "" Then
	TrayTip("Stash is Active", $stashVersion, 5, $TIP_ICONASTERISK+$TIP_NOSOUND  )
EndIf

TrayCreateItem("Stash Helper " & $currentVersion ) ; 0
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
Global $trayMenuBookmark = TrayCreateItem("Bookmark    Ctrl-Alt-B") ; 10
_TrayMenuAddImage($hIcons[17], 10)
TrayCreateItem("")										; 11

Global $trayPlayScene = TrayCreateItem("Play Current Scene") ;12
; GUICtrlSetTip(-1, "Play the current scene with external media player specified in the settings.")
_TrayMenuAddImage($hIcons[12], 12)
Global $trayPlayMovie = TrayCreateItem("Play Current Movie") ;13
; GUICtrlSetTip(-1, "Play the current movie with external media player specified in the settings.")
_TrayMenuAddImage($hIcons[13], 13)

Global $trayPlayImages = TrayCreateItem("Play Current Gallery/Images"); 14
_TrayMenuAddImage($hIcons[20], 14)

Global $trayScrapers = TrayCreateItem("Scrapers Manager"); 15
; GUICtrlSetTip(-1,"Install or remove website scrapers used by Stash.")
_TrayMenuAddImage($hIcons[8], 15)
Global $trayScan = TrayCreateItem("Scan New Files") 	; 16
_TrayMenuAddImage($hIcons[14], 16)
; GUICtrlSetTip(-1,"Let Stash scans for any new files added to your locations.")
Global $trayMovie2Scene = TrayCreateItem("Create movie from scene...") ; 17
_TrayMenuAddImage($hIcons[15], 17)
; GUICtrlSetTip(-1,"Create a movie from current scene.")
Global $trayOpenFolder =  TrayCreateItem("Open Media Folder   Ctrl-Alt-O") ; 18
_TrayMenuAddImage($hIcons[18], 18)

Global $trayMenuCSS = TrayCreateMenu("CSS Magic") ; 19
_TrayMenuAddImage($hIcons[19], 19)
Global $aCSSItems[0][4]
; Enums for the array row.
Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE, $CSS_HANDLE
; Create the css menu with a function.
CreateCSSMenu()

Global $trayMenuPlayList = TrayCreateMenu("Play List")		; 20
_TrayMenuAddImage($hIcons[16], 20)
Global $trayAddItemToList = TrayCreateItem("Add Scene/Movie/Image/Gallery to Play List         Ctrl-Alt-A", $trayMenuPlayList)
Global $trayManageList = 			TrayCreateItem("Manage Current Play List                     Ctrl-Alt-M", $trayMenuPlayList)
Global $trayListPlay = 				TrayCreateItem("Send the Current Play List to Media Player   Ctrl-Alt-P", $trayMenuPlayList)
Global $trayClearList = 			TrayCreateItem("Clear the Play List                          Ctrl-Alt-C", $trayMenuPlayList)


TrayCreateItem("")										; 21
Global $traySettings = TrayCreateItem("Settings")		; 22
_TrayMenuAddImage($hIcons[9], 22)
Global $trayAbout = TrayCreateItem("About")				; 23
_TrayMenuAddImage($hIcons[10], 23)
Global $trayExit = TrayCreateItem("Exit")				; 24
_TrayMenuAddImage($hIcons[11], 24)

; Sub menu items for tools

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

; c("Session ID:" & $sSession)

Global $sBrowserHandle

#EndRegion Globals

#Region Tray Menu Handling

; Create all the sub menu for scenes, movies, studio...etc
CreateSubMenu()

TraySetState($TRAY_ICONSTATE_SHOW)
; Launch the web page
OpenURL($stashURL)
; Ctrl + Enter to close all web sessions and media player
HotKeySet("^{ENTER}", "CloseSession")
; Ctrl+Alt+A to add scene/movie to the playlist.
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
;~ 		Case $trayScrapeSpecial
;~ 			ScrapeSpecial()
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
			PlayScene()
		Case $trayPlayMovie
			PlayMovie()
		Case $trayPlayImages
			CurrentImagesViewer()
		Case $trayScan
			ScanFiles()
		Case $trayMovie2Scene
			Scene2Movie()
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
					Local $sFile = $stashPath & "custom.css"
					Local $sCSS =  FileRead($sFile)
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
							; Local $hFile = FileOpen($sFile, $FO_OVERWRITE )
							;If $hFile = -1 Then
							;	MsgBox(0, "error writing to file", "Error occur when trying to write to custom.css")
							;	ContinueLoop
							;EndIf
							;FileWrite($hFile, $sCSS)
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
						;Local $hFile = FileOpen($sFile, $FO_OVERWRITE )
						;If $hFile = -1 Then
						;	MsgBox(0, "error writing to file", "Error occur when trying to write to custom.css")
						;	ContinueLoop
						;EndIf
						;FileWrite($hFile, $sCSS)
						ApplyCSS($sCSS)
						$aCSSItems[$i][$CSS_ENABLE] = 1
						TrayItemSetState($aCSSItems[$i][$CSS_HANDLE], $TRAY_CHECKED)
					EndIf
					; Now refresh the browser
					_WD_Action($sSession, "refresh")
				EndIf
			Next

	EndSwitch
Wend


Exit

#EndRegion Tray menu

#Region Functions

Func ApplyCSS($str)
	$str = StringReplace($str, @CRLF, "\\n", 0, 2)
	$str = StringReplace($str, @LF, "\\n", 0, 2)
	If StringLeft($str, 3) = "\\n" Then
		$str = StringMid($str, 4)
	EndIf
	$sQuery = 'mutation{configureInterface(input:{css:\"' & $str & '\" cssEnabled: true }){css}}'
	Query2($sQuery)
	if @error then return SetError(1)
EndFunc

Func CreateCSSMenu()
	; Create the sub items for CSS Magic menu
	; Global $trayMenuCSS
	; Global $aCSSItems[0][4]
	; Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE, $CSS_HANDLE
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
	; Global $trayCSSItems[0][3]
	; Global Enum $CSS_TITLE, $CSS_CONTENT, $CSS_ENABLE
	ReDim $a[18][4]
	$a[0][0] = "Scene - Fit More Thumbnails on Each Row."
	$a[0][1] = ".grid { padding: 0px !important; }"

	$a[1][0] = "Scene - Longer Studio Text in Scene Cards"
	$a[1][1] = ".scene-studio-overlay { font-weight: 600 !important; opacity: 1 !important; width: 60% !important; text-overflow: ellipsis !important;}"

	$a[2][0] = "Scene - Hide Scene Specs from Scene Cards"
	$a[2][1] = ".scene-specs-overlay{display: none;}"

	$a[3][0] = "Scene - Hide Studio from Scene Cards"
	$a[3][1] = ".scene-studio-overlay{display: none;}"

	$a[4][0] = "Scene - Tags use less width"
	$a[4][1] = ".bs-popover-bottom{max-width: 500px}"

	$a[5][0] = "Scene - Swap Studio and Specs in Scene Cards"
	$a[5][1] = ".scene-studio-overlay{bottom: 1rem; right: 0.7rem; height: inherit; top: inherit;}" & @LF _
		& ".scene-specs-overlay { right: 0.7rem; top: 0.7rem; bottom: inherit;}"

	$a[6][0] = "Scene - Adjust Mouse Over Behavior in Wall Mode"
	$a[6][1] = "@media (min-width: 576px) { .wall-item:hover::before { opacity: 0; }" & @LF _
		& ".wall-item:hover .wall-item-container { transform: scale(1.5); }}"

	$a[7][0] = "Scene - Disable Zoom on Hover in Wall Mode"
	$a[7][1] = ".wall-item:hover .wall-item-container {transform: none;} " & @LF _
		& ".wall-item:before { opacity: 0 !important;}"

	$a[8][0] = "Scene - Hide the Scene Scrubber"
	$a[8][1] = ".scrubber-wrapper { display: none;}" & @LF _
		& "#jwplayer-container > div:first-child { height: 100%;}"

	$a[9][0] = "Performer - Show Entire Performer's Image"
	$a[9][1] = ".performer.image { background-size: contain !important;}"

	$a[10][0] = "Performer - Move Edit Buttons to the Top"
	$a[10][1] = "form#performer-edit {display: flex; flex-direction: column;}" & @LF _
		& "#performer-edit > .row { order: 1;}" & @LF _
		& "#performer-edit > .row:last-child { order: 0; margin-bottom: 1rem;}"

	$a[11][0] = "Gallery - Grid View for Galleries"
	$a[11][1] = ".col.col-sm-6.mx-auto.table .d-none.d-sm-block { display: none !important;}" & @LF _
		& ".col.col-sm-6.mx-auto.table .w-100.w-sm-auto { width: 175px !important; background-color: rgba(0, 0, 0, .45); box-shadow: 0 0 2px rgba(0, 0, 0, .35);}" & @LF _
		& ".col.col-sm-6.mx-auto.table tr { display: inline-table;}"

	$a[12][0] = "Images - Disable Lightbox Animation"
	$a[12][1] = ".Lightbox-carousel { transition: none;}"

	$a[13][0] = "Images - Don't Crop Preview Thumbnails"
	$a[13][1] = ".flexbin > * > img { object-fit: inherit; max-width: none; min-width: initial;}"

	$a[14][0] = "Movies - Better Layout for Desktops 1 - Regular Posters"
	$a[14][1] = ".movie-details.mb-3.col.col-xl-4.col-lg-6 { flex: 0 0 70%; max-width: 70%}" & @LF _
		& ".col-xl-8.col-lg-6{ flex: 0 0 30%; max-width: 30% }" & @LF _
		& ".movie-images{  flex-wrap: wrap}" & @LF _
		& ".movie-image-container { flex: 0 0 500px}"

	$a[15][0] = "Movies - Better Layout for Desktops 2 - Larger Posters"
	$a[15][1] = ".movie-details.mb-3.col.col-xl-4.col-lg-6 { flex:0 0 70%; max-width: 70%}" & @LF _
		& ".col-xl-8.col-lg-6{ flex: 0 0 30%; max-width: 30% }" & @LF _
		& ".movie-images{ flex-direction: column; flex-wrap: wrap}" & @LF _
		& ".movie-image-container { flex: 1 1 700px}"

	$a[16][0] = "Global - Hide the Donation Button"
	$a[16][1] = ".btn-primary.btn.donate.minimal { display: none;}"

	$a[17][0] = "Global - Blur NSFW Images"
	$a[17][1] = ".scene-card-preview-video, .scene-card-preview-image, .image-card-preview-image, .image-thumbnail, .gallery-card-image," & @LF _
		& ".performer-card-image, img.performer, .movie-card-image, .gallery .flexbin img, .wall-item-media, .scene-studio-overlay .image-thumbnail," & @LF _
		& ".image-card-preview-image, #scene-details-container .text-input, #scene-details-container .scene-header, #scene-details-container .react-select__single-value," & @LF _
		& ".scene-details .pre, #scene-tabs-tabpane-scene-file-info-panel span.col-8.text-truncate > a, .gallery .flexbin img, .movie-details .logo " & @LF _
		& "{filter: blur(8px);}" & @LF _
		& ".scene-card-video {filter: blur(13px);}" & @LF _
		& ".jw-video, .jw-preview, .jw-flag-floating, .image-container, .studio-logo, .scene-cover { filter: blur(20px);}" & @LF _
		& ".movie-card .text-truncate, .scene-card .card-section { filter: blur(4px); }"

	; Read the custom.css and set the CSS_Enable value
	Local $sFile = $stashPath & "custom.css"
	Local $sCSS =  FileRead($sFile)
	If @error Then $sCSS = ""
	; Use /* Start:$a[xx][0] */ as the starting point
	; /* End:$a[xx][0] */ as the ending point
	For $i = 0 To UBound($a) -1
		Local $sSearch = "/* Start:" & $a[$i][0] & " */"
		$a[$i][$CSS_ENABLE] = (StringInStr($sCSS, $sSearch, 2) <> 0) ? 1 : 0
	Next

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
	$sResult = GetCurrentTabCategoryAndNumber()
	If @error Then Return SetError(1)
	; Return string is like "scenes-11" or "scenes"
	If StringInStr($sResult, "-") = 0 Then
		; in main category or collection
		MsgBox(0, "Need specific item", "The current browser is showing a collection, need to show specific scene/movie/image/gallery." )
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
			MsgBox(0, "Cannot be markers", "Sorry, no support for markers yet.")
			Return
		Case "movies"
			; Now get the movie info
			$sQuery = '{ "query": "{findMovie(id: ' & $aStr[2] & '){name,scene_count,scenes{id}}}" }'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)

			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			Local $oMovieData = Json_ObjGet($oResult, "data.findMovie")
			; name, scene_count, scenes->id
			Local $iCount = Int( $oMovieData.Item("scene_count") )  ; better to convert it.
			If $iCount = 0 Then
				MsgBox(0, "No scene", "There is no scene in this movie.")
				Return SetError(1)
			EndIf
			; Just need the first scene location
			Local $nSceneID = $oMovieData.Item("scenes")[0].Item("id")
			$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			Local $oSceneData = Json_ObjGet($oResult, "data.findScene")
			Local $sFilePath = $oSceneData.Item("path")
			; Geth the path only
			Local $iPos =  StringInStr($sFilePath, "\", 2, -1)
			Local $sPath = StringLeft($sFilePath, $iPos)
			ShellExecute($sPath)

		Case "scenes"
			$sQuery = '{"query":"{findScene(id:' & $aStr[2] & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findScene")
			$sFilePath = $oSceneData.Item("path")
			; Geth the path only
			$iPos =  StringInStr($sFilePath, "\", 2, -1)
			$sPath = StringLeft($sFilePath, $iPos)
			ShellExecute($sPath)
		Case "images"
			$sQuery = '{"query":"{findImage(id:' & $aStr[2] & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findImage")
			$sFilePath = $oSceneData.Item("path")
			; Geth the path only
			$iPos =  StringInStr($sFilePath, "\", 2, -1)
			$sPath = StringLeft($sFilePath, $iPos)
			ShellExecute($sPath)
		Case "galleries"
			$sQuery = '{"query":"{findGallery(id:' & $aStr[2] & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			If Not IsObj($oResult) Then
				MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
				Return SetError(1)
			EndIf
			$oSceneData = Json_ObjGet($oResult, "data.findGallery")
			$sFilePath = $oSceneData.Item("path")
			; Geth the path only
			$iPos =  StringInStr($sFilePath, "\", 2, -1)
			$sPath = StringLeft($sFilePath, $iPos)
			ShellExecute($sPath)

	EndSwitch
EndFunc

Func ReloadScrapers()
	; Get the current handle.
	$sQuery = '{"query":"mutation{reloadScrapers}"}'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	Local $sHandle = _WD_Window($sSession, "Window")
	If $sHandle <> "" Then
		; Valid session. Reload the content.
		_WD_Action($sSession, "refresh")
	EndIf
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
	Local $aHandles =  _WD_Window($sSession, 'Handles')
	Switch  UBound($aHandles)
		case 0
			; No wd windows opened.
			MsgBox(0, "No Stash browser", "Currently no Stash browser is opened. Please open one by using the bookmarks.")
			Return SetError(1)
		case 1
			Local $sResult = _WD_Action($sSession, "url")
			If @error <> $_WD_ERROR_Success Then
				; Set the last tab as the current browser tab
				Local $sHandle =  $aHandles[UBound($aHandles)-1]
				_WD_Window($sSession, "Switch", '{"handle":"'& $sHandle & '"}')
				$sResult = _WD_Action($sSession, "url")
			EndIf
		case Else
			; Multi-tab situation. No good solution here.
			Local $sHandle =  $aHandles[0]
			_WD_Window($sSession, "Switch", '{"handle":"'& $sHandle & '"}')
			$sResult = _WD_Action($sSession, "url")
	EndSwitch
	Return _URLDecode($sResult)
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
			; Single scene/movie
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

		Case "movies"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $trayMovieLinks )
			TrayItemDelete($customMovies)
			$trayMovieLinks[$iRow][$ITEM_HANDLE] = TrayCreateItem($sDescription, $trayMenuMovies )
			$customMovies = TrayCreateItem("Customize...", $trayMenuMovies)
			SaveMenuItems($sCategory, $trayMovieLinks)

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
	RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", $sCat & "List", "REG_SZ", $str)
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

	c("URL:" & $sURL)

	Local $sCategory = GetCategory($sURL)
	if @error Then Return SetError(1)

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
	if @error then Return SetError(1)

	; If return just a single id.
	If StringLeft($sQuery, 3) = "id=" Then
		; No need to get query. Has one single id.
		Local $sID = PairValue($sQuery), $iNo
		Switch $sCategory
			Case "scenes"
				AddSceneToList($sID)
				If @error then Return
				MsgBox(0, "Done", "One scene was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList))
			Case "images"
				AddImageToList($sID)
				If @error then Return
				MsgBox(0, "Done", "One image was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList))
			Case "movies"
				$iNo = AddMovieToList($sID)
				If @error then Return
				MsgBox(0, "Done", "One movie with " & $iNo & " scenes was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList))
			Case "galleries"
				$iNo = AddGalleryToList($sID)
				If @error then Return
				MsgBox(0, "Done", "One gallery with " & $iNo & " images was added to the current play list." & @CRLF _
					& "Total entities in play list:  " & UBound($aPlayList))
		EndSwitch
		Return
	ElseIf $sQuery = "not support" Then
		MsgBox(0, "Not support", "Too bad, this kind of query is not support.")
		Return
	EndIf


	$sResult = Query2($sQuery)
	if @error Then Return SetError(1)
	Local $oData = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf

	; Start to add scenes, movies... to the play list.
	Switch $sCategory
		Case "scenes"
			Local $aScenes = Json_ObjGet($oData, "data.findScenes.scenes")
			If UBound($aScenes) = 0 Then
				MsgBox(0, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(1)
			EndIf
			Local $i = 0
			For $oScene in $aScenes
				$i += AddSceneToList($oScene.item("id"))
			Next
			MsgBox(0, "Done", "Totally "& $i & " scenes was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList))
		Case "images"
			Local $aImages = Json_ObjGet($oData, "data.findImages.images")
			If UBound($aImages) = 0 Then
				MsgBox(0, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(1)
			EndIf
			Local $i = 0
			For $oImage in $aImages
				$i += AddImageToList($oImage.item("id"))
			Next
			MsgBox(0, "Done", "Totally "& $i & " images was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList) & @CRLF _
				& "Beware: Most media players do not support playing images stored in .zip files." )
		Case "movies"
			Local $aMovies = Json_ObjGet($oData, "data.findMovies.movies")
			If UBound($aMovies) = 0 Then
				MsgBox(0, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(1)
			EndIf
			Local $i = 0
			For $oMovie in $aMovies
				$i += AddMovieToList($oMovie.item("id"))
			Next
			MsgBox(0, "Done", "Totally "& UBound($aMovies) & " movies with "& $i & " scenes was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList))
		Case "galleries"
			Local $aGalleries = Json_ObjGet($oData, "data.findGalleries.galleries")
			If UBound($aGalleries) = 0 Then
				MsgBox(0, "strange", "Weird, program error. There is nothing to add to the list.")
				Return SetError(1)
			EndIf
			Local $i = 0
			For $oGallery in $aGalleries
				$i += AddGalleryToList($oGallery.item("id"))
			Next
			MsgBox(0, "Done", "Totally "& UBound($aGalleries) & " galleries with "& $i & " images was added to the current play list." & @CRLF _
				& "Total entities in play list:  " & UBound($aPlayList) & @CRLF _
				& "Beware: Most media players do not support playing images stored in .zip files." )
		Case Else
			MsgBox(0, "Not supported", "Sorry, only scene/image/movie/gallery are supported.")
	EndSwitch

EndFunc

Func AddImageToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	$sQuery = '{"query":"{findImage(id:' & $sID & '){title,path}}"}'
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
	$aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("path"))
	Return 1  ; Once scene added to the list
EndFunc

Func AddGalleryToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	$sQuery = '{"query":"{findGallery(id:' & $sID & '){title,image_count,path,images{path}}}"}'
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
	; Treat a gallery like a movie, just add all images to the list
	Local $iCount = 0
	For $oImage In $aImages
		$iCount += 1
		$i = UBound($aPlayList)
		ReDim $aPlayList[$i+1][3]
		$aPlayList[$i][$LIST_TITLE] = "Gallery: " & $oData.Item("title") & " Image: " & $iCount
		$aPlayList[$i][$LIST_DURATION] = $iSlideShowSeconds
		$aPlayList[$i][$LIST_FILE] = FixPath($oImage.Item("path"))
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

Func AddMovieToList($sID)
	If $sID = "" Then Return 0 ; Just in case.
	; Now get the movie info
	$sQuery = '{ "query": "{findMovie(id: ' & $sID & '){name,scene_count,scenes{id}}}" }'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oMovieData = Json_ObjGet($oResult, "data.findMovie")
	If $oMovieData = "" Then Return 0
	; name, scene_count, scenes->id
	Local $iCount = Int( $oMovieData.Item("scene_count") )  ; better to convert it.
	If $iCount = 0 Then
		Return 0
	EndIf
	For $i = 0 to $iCount-1
		Local $nSceneID = $oMovieData.Item("scenes")[$i].Item("id")
		; Now add this scene to the  play list
		$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){path,file{duration} }}"}'
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
		$aPlayList[$j][$LIST_TITLE] = "Movie: " & $oMovieData.Item("name") & " - Scene " & ($i+1)
		$aPlayList[$j][$LIST_DURATION] = Floor( $oSceneData.Item("file").Item("duration") )
		$aPlayList[$j][$LIST_FILE] = FixPath($oSceneData.Item("path"))
	Next
	Return $iCount
EndFunc


Func AddSceneToList($sID)
	If $sID = "" then return 0; Just in case.
	; Now get the info about this scene
	$sQuery = '{"query":"{findScene(id:' & $sID & '){title,path,file{duration}}}"}'
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
	$aPlayList[$i][$LIST_TITLE] = "Scene: " & $oData.Item("title")
	$aPlayList[$i][$LIST_DURATION] = Floor( $oData.Item("file").Item("duration") )
	$aPlayList[$i][$LIST_FILE] = FixPath($oData.Item("path"))
	Return 1  ; Once scene added to the list
EndFunc

Func FixPath($sPath)
	; Fix the path returned from Stash
	; g:\myvideo instead of g:myvideo
	If stringmid($sPath, 2, 1) = ":" AND stringmid($sPath, 2, 2) <> ":\" Then
		$sPath = StringLeft($sPath, 1) & ":\" & StringMid($sPath, 3)
	EndIf
	; g:\myvideo\mypath instead of g:\myvideo\\mypath
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
	$iPos1 = StringInStr($sURL, "/" & $sCategory & "/", 2) + StringLen($sCategory) +2  ; beginning of the movie number
	$iPos2 = StringInStr($sURL, "?", 2) ; the ? position
	If  $iPos2 = 0 Then
		; with no query mark ?
		return  StringMid($sURL, $iPos1)
	Else
		; with query mark ?
		return  StringMid($sURL, $iPos1, $iPos2-$iPos1)
	EndIf
	; like "589" in string mode.
EndFunc

Func ScanFiles()
	; Scan new files in Stash
	Query('{"query": "mutation { metadataScan ( input: { useFileMetadata: true } ) } "}')
	OpenURL("http://localhost:9999/settings?tab=tasks")
	MsgBox(0, "Command sent", "The scan command is sent. You can check the progress in Settings->Tasks.", 10)
EndFunc

Func PlayMovie()
	; Play the current movie with external media player
	CheckMediaPlayer()
	If @error Then Return SetError(1)

	SwitchToTab("movies")
	If @error then return SetError(1)

	; Movie tab found and set current
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $nMovie = GetNumber($sURL, "movies")
	PlayMovieInCurrentTab($nMovie)
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

Func SwitchToTab($sCategory)
	; It will switch to the tab that contains the category, then return the no.
	; First check if the currrent tab is the right one
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $sSearchRegEx = "\/" & $sCategory & "\/\d+"
	If StringRegExp($sURL, $sSearchRegEx) Then
		; Current tab matches. It's a scene or movie.
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

Func PlayMovieInCurrentTab($nMovie)
	; Use graphql to get the scenes in movies
	$sResult = Query( '{"query": "{findMovie(id:' & $nMovie & '){scenes{path}}}"}' )
	If @error Then Return
	Local $oData = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	; Get the scenes array
	Local $aScenes = Json_ObjGet($oData, "data.findMovie.scenes")
	c("aScenes:" & UBound($aScenes))
	Switch UBound($aScenes)
		Case 0
			; Do nothing.
		Case 1
			; Just play it.
			Play( $aScenes[0].Item("path") )
		Case Else
			; write a temp m3u file
			Local $hFile = FileOpen(@TempDir & "\StashMovie.m3u", $FO_OVERWRITE )
			If $hFile = -1 Then
				MsgBox(0, "m3u create error", "failed to create a m3u file for this movie.")
				Return
			EndIf
			; First line
			FileWriteLine($hFile, "#EXTM3U")

			For $i = 0 to UBound($aScenes) - 1
				FileWriteLine($hFile, "#EXTINF:-1,")
				FileWriteLine($hFile, $aScenes[$i].Item("path") )
			Next
			FileClose($hFile)

			; Now play the m3u file
			Play(@TempDir & "\StashMovie.m3u")
	EndSwitch
EndFunc

Func Play($sFile)
	; Use external player to play the file
	Local $sPath = StringLeft($sFile, StringInStr($sFile, "\", -1) )
	$iMediaPlayerPID = ShellExecute($sMediaPlayerLocation, Q($sFile), Q($sPath), $SHEX_OPEN)
	If $iMediaPlayerPID = -1 Then $iMediaPlayerPID = 0
EndFunc

Func QueryResultError($sResult)
	; the result itself says errors.
	Return StringLeft($sResult,10) = '{"errors":'
EndFunc

Func Query2($sQuery)
	; This one will wrap the {"query":" "} around $sQuery. Easier to program.
	c("QueryString:" & '{"query":"'& $sQuery& '"}')
	$sResult = Query('{"query":"'& $sQuery& '"}')
	If @error Then Return SetError(1, 0, $sResult)
	Return $sResult
EndFunc

Func Query($sQuery)
	; Use Stash's graphql to get results or do something
	Local $hOpen = _WinHttpOpen()
	Local $aMatch = StringRegExp( $stashURL, "http:\/\/(.+):(\d+)",1)
	; c("match[0]:" & $aMatch[0] & " match1:" & $aMatch[1])
	Local $hConnect = _WinHttpConnect($hOpen, $aMatch[0], Int($aMatch[1]))
	If $hConnect = 0 Then
		MsgBox(0, "error connect",  "error connecting to stash server.")
		; Close handles
		_WinHttpCloseHandle($hOpen)
		Return SetError(1)
	EndIf
	Local $result = _WinHttpSimpleRequest($hConnect, "POST", "/graphql", Default, _
		$sQuery, "Content-Type: application/json" )
	; c("result:" & $result)
	; Close handles
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
	If @error Then
		MsgBox(0, "got data error",  "Error getting data from the stash server.")
		Return SetError(1)
	ElseIf QueryResultError($result) Then
		MsgBox(0, "oops.", "Error in the query result:" & $result, 10)
		Return SetError(1)
	EndIf
	Return $result
EndFunc


Func PlayScene()
	; Play the current scene with external media player
	CheckMediaPlayer()
	If @error Then Return SetError(1)

	SwitchToTab("scenes")
	If @error Then Return SetError(1)

	PlayCurrentScene()
EndFunc

Func PlayCurrentScene()
	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $aMatch = StringRegExp($sURL, "\/scenes\/(\d+)\?", $STR_REGEXPARRAYMATCH )
	c("scene id:" & $aMatch[0])
	$sQuery = '{"query": "{findScene(id:' & $aMatch[0] & '){path}}"}'
	c("scene query:" & $sQuery)

	; This will query the graphql and get the path info
	$sResult = Query( $sQuery )
	If @error  Then Return SetError(1)

	Local $oData = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	If Not Json_IsObject($oData) Then
		MsgBox(0, "Data error.", "The data return from stash has errors.")
		Return
	EndIf
	; Get the scenes file path and play
	$sFile = Json_ObjGet($oData, "data.findScene.path")
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
	; Probably it's close or no windows at all.
	Local $aHandles =  _WD_Window($sSession, 'Handles')
	If UBound($aHandles) = 0 Then
			; No browser at all, open a new session.
			$sSession = _WD_CreateSession($sDesiredCapabilities)
			_WD_Navigate($sSession, $url)
			$sBrowserHandle = _WD_Window($sSession, "Window")
	Else
			; The session is still alive. Switch to the last handle to make sure that's the current one
			$sBrowserHandle = $aHandles[UBound($aHandles)-1]
			_WD_Window($sSession, "switch", '{"handle":"' & $sBrowserHandle & '"}' )
			_WD_Navigate($sSession, $url)
	EndIf
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

Func ReloadMenu($sCategory)
	; Delete all sub-menu items
	; DeleteAllSubMenu()
	; Recreate all sub-menu items
	; CreateSubMenu()
	Switch $sCategory
		Case "scenes"
			TrayItemDelete($customScenes)
			ReloadSubMenu($sCategory, $traySceneLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuScenes)

		Case "images"
			TrayItemDelete($customImages)
			ReloadSubMenu($sCategory, $trayImageLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuImages)

		Case "movies"
			TrayItemDelete($customMovies)
			ReloadSubMenu($sCategory, $trayMovieLinks)
			$customScenes = TrayCreateItem("Customize...", $trayMenuMovies)

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
	; $sCategory is like "movies","scenes"...
	; Make the first one capital letter.
	Local $sCat = StringUpper(stringleft($sCategory, 1)) & StringMid($sCategory, 2)
	; Delete all the submenu items
	For $i = 0 To UBound($aArray) -1
		If $aArray[$i][$ITEM_HANDLE] <> Null Then
			TrayItemDelete($aArray[$i][$ITEM_HANDLE])
		EndIf
	Next
	; Load data from registry.
	Local $sData = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", $sCat & "List")
	If @error Then
		; No data yet. Set the first item in array
		SetMenuItem($aArray,0, 0, "All " & $sCat, $stashURL & $sCategory)
	Else
		; Setting all the data
		; Data is like "0|All Movies|http://localhost...@crlf 1|Second Item|http:..."
		DataToArray($sData, $aArray)
	EndIf
	; Now $aArray is like [1][null][Title1][Link1],[2][null][title2][link2]...
		; Populate the scenes sub menu
	For $i = 0 To UBound($aArray) -1
		If $aArray[$i][$ITEM_TITLE] <> "" Then
			$aArray[$i][$ITEM_HANDLE] = TrayCreateItem($aArray[$i][$ITEM_TITLE], Execute("$trayMenu" & $sCat))
		EndIf
	Next

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
	Local $aLines = StringSplit($sData, "@@@", $STR_ENTIRESPLIT + $STR_NOCOUNT)
	Local $aItem
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
	If $iStashPID <> 0 Then
		If ProcessExists($iStashPID) Then ProcessClose($iStashPID)
	EndIf
	if $sSession Then
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf
	Exit
EndFunc   ;==>ExitScript

Func c($str)
	ConsoleWrite($str & @CRLF)
EndFunc

Func MsgExit($str)
	; For serious problems that has to exit.
	MsgBox(16,"Error !",$str,0)
	ExitScript()
EndFunc
#EndRegion Functions
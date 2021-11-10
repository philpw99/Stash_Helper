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
#include <Array.au3>
#include "DTC.au3"
; #include "MiniWebServer.au3"

; If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")

DllCall("User32.dll","bool","SetProcessDPIAware")

Global Const $currentVersion = "v1.9"

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

Global $stashBrowser = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser")

Global $showStashConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowStashConsole")
If @error Then $showStashConsole = 0
Global $showWDConsole = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "ShowWDConsole")
if @error Then $showWDConsole = 0

Global $sDesiredCapabilities, $sSession
Global $stashVersion, $stashURL
Global $sMediaPlayerLocation = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "MediaPlayerLocation")

Local $sIconPath = @ScriptDir & "\images\icons\"
Local $hIcons[19]	; 18 (0-17) bmps  for the tray menus
For $i = 0 to 18
	$hIcons[$i] = _LoadImage($sIconPath & $i & ".bmp", $IMAGE_BITMAP)
Next

Global $minfo = ObjCreate("Scripting.Dictionary")

; All forms.
#include <Forms\SettingsForm.au3>
#include <Forms\CustomizeForm.au3>
#include <Forms\ScrapersForm.au3>
#include <Forms\SceneToMovieForm.au3>
#include <Forms\ManagePlayListForm.au3>
; #include <Forms\ScrapeSpecialForm.au3>

; Now this is running in the tray
; First run the Stash-Win program $sStashPath
Global $iStashPID
$stashURL = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "StashURL")

If $stashURL = "" Then
	; Never have $stashURL before. Run it for the first time.
	$iStashPID = ProcessExists("stash-win.exe")
	If $iStashPID <> 0 Then ProcessClose($iStashPID) ; Just in case.
	; Run it for the first time. Merged.
	$iStashPID = Run($stashFilePath, $stashPath, @SW_HIDE, $STDERR_MERGED)
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
	$sHost = $aStr[0]
	$sPort = $aStr[1]
	If $sHost = "localhost" Then
		$iStashPID = ProcessExists("stash-win.exe")
		If $iStashPID = 0 Then
			; Not running.
			If $showStashConsole Then
				$iStashPID = Run($stashFilePath, $stashPath, @SW_SHOW)
			Else
				$iStashPID = Run($stashFilePath, $stashPath, @SW_HIDE)
			EndIf
		Else
			; Already running. Get the PID which is listening to that port
			$iPid = Run(@ComSpec & ' /C netstat -ano|find "0.0.0.0:' & $sPort & '"',"",@SW_HIDE, $STDOUT_CHILD )
			ProcessWaitClose($iPid)
			$sReadOut = StdoutRead($iPid)
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

Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected.
; Now create the top level tray menu items.
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
Global $trayScrapers = TrayCreateItem("Scrapers Manager"); 14
; GUICtrlSetTip(-1,"Install or remove website scrapers used by Stash.")
_TrayMenuAddImage($hIcons[8], 14)
Global $trayScan = TrayCreateItem("Scan New Files") 	; 15
_TrayMenuAddImage($hIcons[14], 15)
; GUICtrlSetTip(-1,"Let Stash scans for any new files added to your locations.")
Global $trayMovie2Scene = TrayCreateItem("Create movie from scene...") ; 16
_TrayMenuAddImage($hIcons[15], 16)
; GUICtrlSetTip(-1,"Create a movie from current scene.")
Global $trayOpenFolder =  TrayCreateItem("Open Media Folder   Ctrl-Alt-O") ; 17
_TrayMenuAddImage($hIcons[18], 17)

Global $trayMenuPlayList = TrayCreateMenu("Play List")		; 18
_TrayMenuAddImage($hIcons[16], 18)
Global $trayAddSceneOrMovieToList = TrayCreateItem("Add Current Scene/Movie to Play List         Ctrl-Alt-A", $trayMenuPlayList)
Global $trayManageList = 			TrayCreateItem("Manage Current Play List                     Ctrl-Alt-M", $trayMenuPlayList)
Global $trayListPlay = 				TrayCreateItem("Send the Current Play List to Media Player   Ctrl-Alt-P", $trayMenuPlayList)
Global $trayClearList = 			TrayCreateItem("Clear the Play List                          Ctrl-Alt-C", $trayMenuPlayList)


TrayCreateItem("")										; 19
Global $traySettings = TrayCreateItem("Settings")		; 20
_TrayMenuAddImage($hIcons[9], 19)
Global $trayAbout = TrayCreateItem("About")				; 21
_TrayMenuAddImage($hIcons[10], 20)
Global $trayExit = TrayCreateItem("Exit")				; 22
_TrayMenuAddImage($hIcons[11], 21)

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
HotKeySet("^!a", "AddSceneOrMovieToList")
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
	$nMsg = TrayGetMsg()
	Switch $nMsg
		Case 0
			; Nothing should be here, but Case 0 here is very necessary.
		Case $trayAbout
			MsgBox(64,"Stash Helper " & $currentVersion,"Stash helper " & $currentVersion & ", written by Philip Wang, at your service." _
				& @CRLF & "Hopefully this little program will make you navigate the powerful Stash App more easily." _
				& @CRLF & "Kudos to the great Stash App team ! kermieisinthehouse, WithoutPants, bnkai ... and all other great contributors working for this huge project." _
				& @CRLF & "Kudos also go to Christian Faderl's ISN AutoIt Studio! It's such a powerful AutoIt IDE, which making this program much easier to write." _
				& @CRLF & "Also thanks to InstallForge.net for providing me such an easy-to-build installer!" _
				& @CRLF & "Special thanks to BViking78 for the numerous pieces of advice!"	,20)
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
		Case $trayScan
			ScanFiles()
		Case $trayMovie2Scene
			Scene2Movie()
		Case $trayAddSceneOrMovieToList
			AddSceneOrMovieToList()
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
			$oMovieData = Json_ObjGet($oResult, "data.findMovie")
			; name, scene_count, scenes->id
			$iCount = Int( $oMovieData.Item("scene_count") )  ; better to convert it.
			If $iCount = 0 Then
				MsgBox(0, "No scene", "There is no scene in this movie.")
				Return SetError(1)
			EndIf
			; Just need the first scene location
			$nSceneID = $oMovieData.Item("scenes")[0].Item("id")
			$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
			$oSceneData = Json_ObjGet($oResult, "data.findScene")
			$sFilePath = $oSceneData.Item("path")
			; Geth the path only
			$iPos =  StringInStr($sFilePath, "\", 2, -1)
			$sPath = StringLeft($sFilePath, $iPos)
			ShellExecute($sPath)
			
		Case "scenes"
			$sQuery = '{"query":"{findScene(id:' & $aStr[2] & '){path}}"}'
			$sResult = Query($sQuery)
			If @error Then Return SetError(1)
			; Query and Get the full path\filename
			$oResult = Json_Decode($sResult)
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
	$sHandle = _WD_Window($sSession, "Window")
	If $sHandle = "" Then
		; invalid session. create a new one.
		$sSession = _WD_CreateSession($sDesiredCapabilities)
		$sHandle = _WD_NewTab($sSession, Default, Default, "http://localhost:9999/" , Default)
	EndIf
	$sHandle = '{"handle":"' & $sHandle & '"}'
	; New tab for scraper reload.
	_WD_NewTab($sSession, Default, Default, "http://localhost:9999/settings?tab=scraping" , Default)
	; OpenURL("http://localhost:9999/settings?tab=scraping")
	$sButtonID = _WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, '//span[text()="Reload scrapers"]', 500, 10000) ; start at 500ms, expired at 10 seconds
	Sleep(2000)  ; Just to be safe.
	If @error =  $_WD_ERROR_Success Then
		_WD_ElementAction($sSession, $sButtonID, "Click")
	EndIf
	Sleep(2000)
	; Close the tab
	_WD_Window($sSession, "Close")
	; Switch back to the previous tab
	_WD_Window($sSession, "switch", $sHandle)
EndFunc

Func GetCurrentTabCategoryAndNumber()
	Local $sURL = GetURL()
	If @error then Return SetError(1)
	; Get the text after http://localhost:9999/
	$sStr = StringMid($sURL, StringLen($stashURL) +1 )
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
	
	If $aStr[0] >= 2 Then
		Return $aStr[1] & "-" & $aStr[2]
	Else
		Return $aStr[1]
	EndIf

EndFunc

Func GetURL()
	Local $sURL = _WD_Action($sSession, "url")
	If $sURL = "" Then
		MsgBox(0, "No Stash browser", "Currently no Stash browser is opened. Please open one by using the bookmarks.")
		Return SetError(1)
	EndIf
	Return $sURL
EndFunc

Func BookmarkCurrentTab()
	$sResult = GetCurrentTabCategoryAndNumber()
	If @error Then Return SetError(1)
	$sURL = GetURL()
	If @error Then Return SetError(1)

	local $sThing = "thing"
	$aStr = StringSplit($sResult, "-")
	$sCategory = $aStr[1]

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
	$sDescription = InputBox("Title required", "Please enter a brief description/title for this " & $sThing & ".")
	If $sDescription = "" Then Return
	$sDescription = StringLeft($sDescription, 50)

	Switch $sCategory
		Case "scenes"
			$iRow = AddBookmarkToArray($sDescription, $sURL, $traySceneLinks )
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
	$sCat = StringUpper(stringleft($sCategory, 1)) & stringmid($sCategory, 2)
	; First item
	$str = "1|" & $aArray[0][$ITEM_TITLE] & "|" & $aArray[0][$ITEM_LINK]
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

Func AddSceneOrMovieToList()

	$sURL = GetURL()
	If @error Then Return SetError(1)

	If StringRegExp($sURL, "\/scenes\/\d+") Then
		; A Scene
		AddSceneToList()
	ElseIf StringRegExp($sURL, "\/movies\/\d+") Then
		; A Movie
		AddMovieToList()
	Else
		MsgBox(0, "Not a movie or scene", "Sorry, the current browser is neither a movie or a scene.")
	EndIf
EndFunc

Func SendPlayerList()
	; Send the media player a temporary list and let it play.
	CheckMediaPlayer()
	If @error Then Return SetError(1)
	If UBound($aPlayList, $UBOUND_ROWS ) = 0 Then
		MsgBox(48,"Play list is empty","There is nothing in the play list. Cannot play it.",10)
		Return SetError(1)
	EndIf
	$sFileName = @TempDir & "\StashPlayList.m3u"

	Local $hFile = FileOpen($sFileName, $FO_OVERWRITE)
	If $hFile = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when creating the file.", 10)
		Return SetError(1)
	EndIf

	; Write the required first line.
	FileWriteLine($hFile, "#EXTM3U")
	; Now write the file/path list
	Local $iCount = UBound($aPlayList)
	Local $sTitle, $sFile
	For $i = 0 to $iCount-1
		$sTitle = $aPlayList[$i][$LIST_TITLE]
		$iDuration = $aPlayList[$i][$LIST_DURATION]
		$sFile = $aPlayList[$i][$LIST_FILE]
		Local $line = "#EXTINF:" & $iDuration & "," & $sTitle
		FileWriteLine($hFile, $line ) ; $aData[2] is the name of the file.
		; Write the real file/path on second line.
		FileWriteLine($hFile, $sFile)
	Next
	FileClose($hFile)
	; Now play it.
	Play(@TempDir & "\StashPlayList.m3u")
EndFunc

Func AddMovieToList()
	; SwitchToTab("movies")
	; If @error Then Return SetError(1)

	$sURL = GetURL()
	If @error Then Return SetError(1)

	$nMovieID = GetNumber($sURL, "movies")

	; Now get the movie info
	$sQuery = '{ "query": "{findMovie(id: ' & $nMovieID & '){name,scene_count,scenes{id}}}" }'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	$oMovieData = Json_ObjGet($oResult, "data.findMovie")
	; name, scene_count, scenes->id
	$iCount = Int( $oMovieData.Item("scene_count") )  ; better to convert it.
	If $iCount = 0 Then
		MsgBox(0, "No scene", "There is no scene in this movie.")
		Return SetError(1)
	EndIf
	For $i = 0 to $iCount-1
		$nSceneID = $oMovieData.Item("scenes")[$i].Item("id")
		; Now add this scene to the  play list
		$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){path,file{duration} }}"}'
		$sResult = Query($sQuery)
		If @error Then Return SetError(1)

		$oResult = Json_Decode($sResult)
		$oSceneData = Json_ObjGet($oResult, "data.findScene")
		; path
		$j = UBound($aPlayList)
		ReDim $aPlayList[$j+1][3]
		$aPlayList[$j][$LIST_TITLE] = "Movie: " & $oMovieData.Item("name") & " - Scene " & ($i+1)
		$aPlayList[$j][$LIST_DURATION] = Floor( $oSceneData.Item("file").Item("duration") )
		$aPlayList[$j][$LIST_FILE] = $oSceneData.Item("path")

	Next
	MsgBox(0, "Done", "Movie: " & $oMovieData.Item("name") _
		& @CRLF & "was added to the current play list." & @CRLF & "Total entities in play list:  " & UBound($aPlayList))

EndFunc


Func AddSceneToList()
	SwitchToTab("scenes")
	If @error Then Return SetError(1)

	$sURL = GetURL()
	If @error Then Return SetError(1)

	$nSceneID = GetNumber($sURL, "scenes")

	; Now get the info about this scene
	$sQuery = '{"query":"{findScene(id:' & $nSceneID & '){title,path,file{duration}}}"}'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	$oResult = Json_Decode($sResult)
	$oData = Json_ObjGet($oResult, "data.findScene")
	; $oData.Item("title") $oData.Item("path")
	$i = UBound($aPlayList)
	ReDim $aPlayList[$i+1][3]
	$aPlayList[$i][$LIST_TITLE] = "Scene: " & $oData.Item("title")
	$aPlayList[$i][$LIST_DURATION] = Floor( $oData.Item("file").Item("duration") )
	$aPlayList[$i][$LIST_FILE] = $oData.Item("path")
	MsgBox(0, "Done", "Scene:  " & $aPlayList[$i][$LIST_TITLE] _
		& @CRLF & "was added to the current play list." & @CRLF & "Total entities in play list:  " & UBound($aPlayList))

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
	$sURL = GetURL()
	If @error Then Return SetError(1)

	$nMovie = GetNumber($sURL, "movies")
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
	$sURL = GetURL()
	If @error Then Return SetError(1)

	$sSearchRegEx = "\/" & $sCategory & "\/\d+"
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
		$sItem = StringLeft($sCategory, stringlen($sCategory)-1)
		MsgBox(48,"Cannot find the " & $sItem,"Sorry, but I cannot find the browser tab with the " & $sItem & " you want.",0)
		Return SetError(1)
	EndIf
EndFunc

Func PlayMovieInCurrentTab($nMovie)
	; Use graphql to get the scenes in movies
	$sResult = Query( '{"query": "{findMovie(id:' & $nMovie & '){scenes{path}}}"}' )
	If @error Then Return
	$oData = Json_Decode($sResult)
	If Not Json_IsObject($oData) Then
		MsgBox(0, "Data error.", "The data return from stash has errors.")
		Return
	EndIf
	; Get the scenes array
	$aScenes = Json_ObjGet($oData, "data.findMovie.scenes")
	c("aScenes:" & UBound($aScenes))
	Switch UBound($aScenes)
		Case 0
			; Do nothing.
		Case 1
			; Just play it.
			Play( $aScenes[0].Item("path") )
		Case Else
			; write a temp m3u file
			$hFile = FileOpen(@TempDir & "\StashMovie.m3u", $FO_OVERWRITE )
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
	$result = _WinHttpSimpleRequest($hConnect, "POST", "/graphql", Default, _
		$sQuery, "Content-Type: application/json" )
	c("result:" & $result)
	If @error Then
		MsgBox(0, "got data error",  "Error getting data from the stash server.")
		; Close handles
		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
		Return SetError(1)
	ElseIf QueryResultError($result) Then
		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
		MsgBox(0, "oops.", "Error in the query result:" & $result, 10)
	EndIf
	; Close handles
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
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
	$sURL = GetURL()
	If @error Then Return SetError(1)

	$aMatch = StringRegExp($sURL, "\/scenes\/(\d+)\?", $STR_REGEXPARRAYMATCH )
	c("scene id:" & $aMatch[0])
	$sQuery = '{"query": "{findScene(id:' & $aMatch[0] & '){path}}"}'
	c("scene query:" & $sQuery)

	; This will query the graphql and get the path info
	$sResult = Query( $sQuery )
	If @error  Then Return SetError(1)

	$oData = Json_Decode($sResult)
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
	$sCat = StringUpper(stringleft($sCategory, 1)) & StringMid($sCategory, 2)
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
#EndRegion Functions
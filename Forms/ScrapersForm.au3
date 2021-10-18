; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <GuiListView.au3>
#include <InetConstants.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <Array.au3>

Global $sScraperPath

Func ScrapersManager()

	If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")
	
	; Open the config.xml to see the folder.
	$stashPath = StringLeft( $stashFilePath, StringInStr($stashFilePath, "\", 2, -1) )
	; $stashPath has "\" in the end.
	$hFile = FileOpen($stashPath & "config.yml")
	If $hFile = -1 Then 
		MsgBox(16,"Error open config.yml","Error opening the Stash's config file: config.yml",0)
		Return 
	EndIf
	
	While True 
		$sLine =  FileReadLine($hFile)
		If @error = -1 Then
			; Reach the end of the file
			$sLine = "scrapers_path: scrapers"
			ExitLoop 
		ElseIf @error Then 
			MsgBox(16,"Error reading config.yml","Error reading the Stash's config file: config.yml",0)
			FileClose($hFile)
			Return 
		EndIf
		If StringLeft($sLine, 14) = "scrapers_path:" Then ExitLoop 
	Wend
	FileClose($hFile)
	
	; Get scraper path, create the path if it doesn't exist
	$sScraperPath = $stashPath & StringMid($sLine, 16 ) & "\"
	If Not FileExists($sScraperPath) Then 
		DirCreate($sScraperPath)
	EndIf

	Local $bGetList = True 
	
	If FileExists($sScraperPath & "SCRAPERS-LIST.md") Then 
		$sTime = FileGetTime($sScraperPath & "SCRAPERS-LIST.md", $FT_CREATED, $FT_STRING)
		If stringleft($sTime, 8) = @YEAR & @MON & @MDAY Then
			; If same day, no need to download the file
			$bGetList = False
		EndIf
	EndIf
	; Download the Scraper List raw.
	If $bGetList Then 
		InetGet("https://raw.githubusercontent.com/stashapp/CommunityScrapers/master/SCRAPERS-LIST.md", _ 
			$sScraperPath & "SCRAPERS-LIST.md")
		If @error Then 
			MsgBox(16,"Error downloading scrapers list","Error downloading the Stash's scraper list from its repo.",0)
			Return
		EndIf
	EndIf 
	$hFile = FileOpen($sScraperPath & "SCRAPERS-LIST.md")
	If $hFile = -1 Then 
		MsgBox(16,"Error open SCRAPERS-LIST.md","Error opening stash's scraper list file.",0)
		Return 
	EndIf
	
	; Skip all the lines until "---------"
	While True 
		$sLine = FileReadLine($hFile)
		If stringleft($sLine, 10) = "----------" Then 
			ExitLoop
		ElseIf @error Then 
			MsgBox(16,"Error reading SCRAPERS-LIST.md","Error reading stash's scraper list file.",0)
			Return 
		EndIf
	WEnd 
	
	; Create the GUI first, then read the data later.
	
	$Scrapers = GUICreate("Scrapers Management",1703,1434,-1,-1,$WS_SIZEBOX,-1)
	$scraperList = GUICtrlCreatelistview("Website|Scraper|Scene|Gallery|Movie|Performers|Installed|ExtraReq|Contents",40,330,1620,1056,-1,BitOr($LVS_EX_FULLROWSELECT,$LVS_EX_GRIDLINES,$LVS_EX_CHECKBOXES,$LVS_EX_DOUBLEBUFFER,$WS_EX_CLIENTEDGE))
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,102)
	; Website
	_GUICtrlListView_SetColumnWidth($scraperList, 0, 400)
	; Scraper
	_GUICtrlListView_SetColumnWidth($scraperList, 1, 400)
	; Scene
	_GUICtrlListView_SetColumnWidth($scraperList, 2, 100)
	_GUICtrlListView_JustifyColumn($scraperList, 2, 2)
	; Gallery
	_GUICtrlListView_SetColumnWidth($scraperList, 3, 100)
	_GUICtrlListView_JustifyColumn($scraperList, 3, 2)
	; Movie
	_GUICtrlListView_SetColumnWidth($scraperList, 4, 100)
	_GUICtrlListView_JustifyColumn($scraperList, 4, 2)
	; Performer
	_GUICtrlListView_SetColumnWidth($scraperList, 5, 130)
	_GUICtrlListView_JustifyColumn($scraperList, 5, 2)
	; Installed
	_GUICtrlListView_SetColumnWidth($scraperList, 6, 130)
	_GUICtrlListView_JustifyColumn($scraperList, 6, 2)
	; ExtraReq
	_GUICtrlListView_JustifyColumn($scraperList, 7, 2)
	; Content
	_GUICtrlListView_JustifyColumn($scraperList, 8, 2)

	GUICtrlCreateLabel("Scrapers can fetch information about your scenes, studios, performers, tags...etc."&@crlf&"With scrapers, you don't need to type in the information manually any more."&@crlf&" * For performers, you can fetch the info by her/his name."&@crlf&" * For scenes, you put in the URL for that scene, and the scraper can get all the details, including performers, tags, front cover... for that scene."&@crlf&"Therefore, managing scrapers are important for Stash. You don't want too many scrapers, yet you need them to categorize and label your videos quickly."&@crlf&"Here I am trying to give you an easy way to manage the plugins.",130,30,1040,233,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,928)

	$btnInstall = GUICtrlCreateButton("Install",1065,252,167,49,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Install the scrapers with check marks.")
	GUICtrlSetResizing(-1,804)

	$btnRemove = GUICtrlCreateButton("Remove",1298,252,167,49,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Remove the scrapers with check marks.")
	GUICtrlSetResizing(-1,804)
	
	GUISetState(@SW_SHOW, $Scrapers)
	
	$aScraperFiles = _FileListToArray($sScraperPath, "*.yml", $FLTA_FILES)
	
	; Now read the real data and create all the items.
	While True 
		$sLine = FileReadLine($hFile)
		If @error = -1 Then 
			; End of the file
			ExitLoop 
		ElseIf @error Then
			; Other errors.
			MsgBox(16,"Error reading SCRAPERS-LIST lines","Error reading scraper list lines.",0)
			Return 
		EndIf
		
		$aData = StringSplit($sLine, "|")
		; Replace the check mark with check symbol, :x: with x
		$sLine = StringReplace($sLine, ":heavy_check_mark:", "√", 0, 2)
		$sLine = StringReplace($sLine, ":x:", "x", 0, 2)
		
		; Get the yml file name
		$iPos1 = StringInStr($sLine, "|", 2, 1)
		$iPos2 = StringInStr($sLine, "|", 2, 2)
		$sYml = StringMid($sLine, $iPos1 + 1, $iPos2-$iPos1-1 )
		; Search this one in the files array
		$result = _ArraySearch($aScraperFiles, $sYml, 0, 0, 0, 2)
		$sInstalled = "No|"
		If $result <> -1 Then 
			; installed.
			$sInstalled = "Yes|"
		EndIf
		
		; Add "Installed" column before the ExtraReq
		$iPos = StringInStr($sLine, "|", 2, -2)
		$sFinalLine = StringLeft($sLine, $iPos) & $sInstalled & StringMid($sLine, $iPos + 1)
		GUICtrlCreateListViewItem($sFinalLine, $scraperList)
	Wend
	FileClose($hFile)
	
	; Now It's all ready. Wait for "Install" or "Remove"
	While True
		$nMsg = GUIGetMsg()
		Switch $nMsg
			
			Case $btnInstall ; Install scrapers
				$iCount = _GUICtrlListView_GetItemCount($scraperList)
				For $i = 0 To $iCount -1
					If _GUICtrlListView_GetItemChecked($scraperList, $i) Then 
						$sScraperFile = _GUICtrlListView_GetItemText($scraperList, $i, 1)
						FetchScraper($sScraperFile)
						If @error Then 
							MsgBox(48,"Error downloading file","Sorry, cannot download this file from GitHub:" & $sScraperFile,0)
							ExitLoop 
						EndIf
						; Fetch is good. Now set it uncheck and "installed"
						_GUICtrlListView_SetItemChecked($scraperList, $i, False)
						_GUICtrlListView_SetItemText($scraperList, $i, "Yes", 6)
					EndIf
				Next
				
				OpenURL("http://localhost:9999/settings?tab=scraping")
				Sleep(1000)
				Alert("The checked Scrapers are installed. Now you still need to click on 'Reload Scrapers' here to take effect.")


			Case $btnRemove  ; Remove scrapers
				$iCount = _GUICtrlListView_GetItemCount($scraperList)
				For $i = 0 To $iCount -1
					If _GUICtrlListView_GetItemChecked($scraperList, $i) Then 
						$sScraperFile = _GUICtrlListView_GetItemText($scraperList, $i, 1)
						FileDelete($sScraperPath & $sScraperFile)
						$sPyFile = Stringleft($sScraperFile, stringinstr($sScraperFile, ".", 2, -1) -1) & ".py"
						If FileExists($sScraperPath & $sPyFile) Then 
							FileDelete($sScraperPath & $sPyFile)
						EndIf
						_GUICtrlListView_SetItemChecked($scraperList, $i, False)
						_GUICtrlListView_SetItemText($scraperList, $i, "No", 6)
					EndIf
				Next
				
				OpenURL("http://localhost:9999/settings?tab=scraping")
				Sleep(1000)
				Alert("The checked Scrapers are removed. Now you still need to click on 'Reload Scrapers' here to take effect.")

			Case $GUI_EVENT_CLOSE
				ExitLoop 
		EndSwitch
	Wend

	GUIDelete($Scrapers)
EndFunc

Func FetchScraper($sFile)
	; Global $stashFilePath, $sScraperPath
	; Download it from GitHub
	Const $sBase = "https://raw.githubusercontent.com/stashapp/CommunityScrapers/master/scrapers/"
	$result = InetGet( $sBase & $sFile, $sScraperPath & $sFile)
	If $result = 0 Then 
		Return SetError(1)
	EndIf
	; Success, now open it and see it.
	$hFile = FileOpen($sScraperPath & $sFile)
	While True
		$sLine = FileReadLine($hFile)
		If @error Then
			; ConsoleWrite("error return." & @CRLF)
			Return  ; End of file?
		EndIf
		If StringInStr($sLine, "- python") Then
			; Python script. Need to download the py file
			$sPyFile = Stringleft($sFile, stringinstr($sFile, ".", 2, -1) -1) & ".py"
			; ConsoleWrite("download py:" & $sBase & $sPyFile & @CRLF & "To:" & $sScraperPath & $sPyFile)
			InetGet( $sBase & $sPyFile, $sScraperPath & $sPyFile)
			Return 
		EndIf
		If stringinstr($sLine, "scrapeXPath") Then
			; It's a scrape by xpath, no need to download
			; ConsoleWrite("found xpath." & @CRLF)
			Return 
		EndIf
	WEnd 
EndFunc

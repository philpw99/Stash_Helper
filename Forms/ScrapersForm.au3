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

Global $sScraperPath, $aScraperArray[0], $aScraperFiles[0]

Func ScrapersManager()
	$sScraperPath = GetScraperPath()
	Local $aItemID[0][0]
	Local $iCurrentSearchIndex = 0
	If @error Then Return 
	; Set both $aScraperArray and $aScraperFiles
	SetScraperArray() 
	If @error Then Return 

	; Disable the tray clicks
	TraySetClick(0)
	
	$guiScrapers = GUICreate("Scrapers Management",1703,1438,-1,-1,$WS_SIZEBOX,-1)
	GUISetIcon("helper2.ico")
	
	$scraperList = GUICtrlCreatelistview("Website|Scraper|Scene|Gallery|Movie|Performers|Installed|ExtraReq|Contents",40,290,1621,1056,-1,BitOr($LVS_EX_FULLROWSELECT,$LVS_EX_GRIDLINES,$LVS_EX_CHECKBOXES,$LVS_EX_DOUBLEBUFFER,$WS_EX_CLIENTEDGE))
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

	GUICtrlCreateLabel("Scrapers can fetch information about your scenes, studios, performers, tags...etc. With scrapers, you don't need to type in the information manually any more."&@crlf&" * For performers, you can fetch the info by her/his name."&@crlf&" * For scenes, you put in the URL for that scene, and the scraper can get all the details, including performers, tags, front cover... for that scene."&@crlf&"Therefore, managing scrapers are important for Stash. You don't want too many scrapers, yet you need them to categorize and label your videos quickly.",54,30,1597,205,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,38)

	$btnInstall = GUICtrlCreateButton("Install",1065,212,167,49,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Install the scrapers with check marks.")
	GUICtrlSetResizing(-1,804)

	$btnRemove = GUICtrlCreateButton("Remove",1298,212,167,49,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Remove the scrapers with check marks.")
	GUICtrlSetResizing(-1,804)
	
	GUISetState(@SW_SHOW, $guiScrapers)
	
	$inputFind = GUICtrlCreateInput("",42,218,570,35,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,550)
	
	$btnFind = GUICtrlCreateButton("Find",640,220,148,33,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)
	
	; Now all the items in the list, [0] is handle [1] is check/uncheck
	ReDim $aItemID[UBound($aScraperArray)][2]
	For $i = 0 to UBound($aScraperArray) -1
		$aItemID[$i][0] = GUICtrlCreateListViewItem($aScraperArray[$i], $scraperList)
		$aItemID[$i][1] = False ; Unchecked.
	Next 
	
	; Now It's all ready. Wait for "Install" or "Remove"
	Local $aFiles[0]

	While True
		; if click on tray icon, activate the current GUI
		$nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiScrapers)
 		EndSwitch 
		
		; Main control loop
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $inputFind, $btnFind
				$sText = GUICtrlRead($inputFind)
				$iFound = _GUICtrlListView_FindInText($scraperList, $sText, $iCurrentSearchIndex, False )
				If $iFound = -1 Then 
					; Not found, reset the index
					$iCurrentSearchIndex = 0
					MsgBox(48,"Not found","Search reach the end and Cannot find your search of " & $sText,0)
				Else 
					; Found the index, set it highlighted and visible.
					$iCurrentSearchIndex = $iFound
					_GUICtrlListView_EnsureVisible($scraperList, $iFound )
					_GUICtrlListView_SetItemSelected($scraperList, $iFound)
					GUICtrlSetState($scraperList, $GUI_FOCUS)
				EndIf
			Case $btnInstall ; Install scrapers
				$iCount = _GUICtrlListView_GetItemCount($scraperList)
				$iTotalInstalled = 0
				ReDim $aFiles[0]  ; clear the array
				For $i = 0 To $iCount -1
					; go through the whole list
					If _GUICtrlListView_GetItemChecked($scraperList, $i) Then
						$sScraperFile = _GUICtrlListView_GetItemText($scraperList, $i, 1)
						If _ArraySearch($aFiles, $sScraperFile) = -1 Then
							; Not in file array
							$i = UBound($aFiles)
							ReDim $aFiles[$i + 1]
							; Add it to the list
							$aFiles[$i] = $sScraperFile
						EndIf 
						; Now set it uncheck and "installed"
						_GUICtrlListView_SetItemChecked($scraperList, $i, False)
						_GUICtrlListView_SetItemText($scraperList, $i, "Yes", 6)
					EndIf
				Next
				
				; Now go through the file list
				For $i = 0 To UBound($aFiles) -1
					FetchScraper($aFiles[$i])
					If @error Then 
						MsgBox(48,"Error downloading file","Sorry, cannot download this file from GitHub:" & $sScraperFile,0)
					Else 
						$iTotalInstalled += 1
					EndIf
				Next 
				
				If $iTotalInstalled > 0 Then
					; Reload scrapers
					
					; Set mouse cursor to wait.
					$old_cursor = MouseGetCursor()
					GUISetCursor(15, 1, $guiScrapers)

					OpenURL("http://localhost:9999/settings?tab=scraping")
					$sButtonID = _WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, '//span[text()="Reload scrapers"]', 500, 10000) ; start at 500ms, expired at 10 seconds
					Sleep(1000)
					If @error =  $_WD_ERROR_Success Then 
						_WD_ElementAction($sSession, $sButtonID, "Click")
					EndIf

					; Set cursor back.
					GUISetCursor($old_cursor, 1, $guiScrapers)

					MsgBox(64,$iTotalInstalled & " Scrapers Installed",$iTotalInstalled & " Scrapers are now installed and working.",20)
				EndIf 

			Case $btnRemove  ; Remove scrapers
				$iCount = _GUICtrlListView_GetItemCount($scraperList)
				$iTotalRemoved = 0
				ReDim $aFiles[0]  ; clear the array
				For $i = 0 To $iCount -1
					; go through the whole list
					If _GUICtrlListView_GetItemChecked($scraperList, $i) Then 
						$sScraperFile = _GUICtrlListView_GetItemText($scraperList, $i, 1)
						If _ArraySearch($aFiles, $sScraperFile) = -1 Then
							; Not in file array
							$i = UBound($aFiles)
							ReDim $aFiles[$i + 1]
							; Add it to the list
							$aFiles[$i] = $sScraperFile
						EndIf 
						_GUICtrlListView_SetItemChecked($scraperList, $i, False)
						_GUICtrlListView_SetItemText($scraperList, $i, "No", 6)
					EndIf 	
				Next		
				; Now go through the file list
				For $i = 0 To UBound($aFiles)-1
					FileDelete($sScraperPath & $sScraperFile)
					$sPyFile = Stringleft($sScraperFile, stringinstr($sScraperFile, ".", 2, -1) -1) & ".py"
					If FileExists($sScraperPath & $sPyFile) Then 
						FileDelete($sScraperPath & $sPyFile)
					EndIf
					$iTotalRemoved += 1
				Next
				
				If $iTotalRemoved > 0 Then 
					; Reload scrapers
					
					; Set mouse cursor to wait.
					$old_cursor = MouseGetCursor()
					GUISetCursor(15, 1, $guiScrapers)
					
					OpenURL("http://localhost:9999/settings?tab=scraping")
					$sButtonID = _WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, '//span[text()="Reload scrapers"]', 500, 10000) ; start at 500ms, expired at 10 seconds
					Sleep(1000)
					If @error =  $_WD_ERROR_Success Then 
						_WD_ElementAction($sSession, $sButtonID, "Click")
					EndIf

					
					; Set cursor back.
					GUISetCursor($old_cursor, 1, $guiScrapers)
					
					MsgBox(64,$iTotalRemoved & " Scrapers removed",$iTotalRemoved & " Scrapers are now removed.",20)
				EndIf 
			Case $GUI_EVENT_CLOSE
				ExitLoop 
		EndSwitch
		; Match the Items
		For $i = 0 to UBound($aItemID)-1
			If $nMsg = $aItemID[$i][0] Then
				; Item ID matched. 
				; if search, search from here.
				$iCurrentSearchIndex = $i
				
				$bItemChecked = _GUICtrlListView_GetItemChecked($scraperList, $i)
				If $bItemChecked <> $aItemID[$i][1] Then
					; Check status changed.
					$aItemID[$i][1] = $bItemChecked
					; Now set all the item with same yml file to the same check status
					$sYMLfile = StringStripWS( _GUICtrlListView_GetItemText($scraperList, $i, 1), 3)
					; Find the item with same file
					For $j = 0 To UBound($aScraperArray) -1
						Local $aStr = StringSplit($aScraperArray[$j], "|")
						If StringStripWS($aStr[2], 3) = $sYMLfile Then 
							; This item matches
							_GUICtrlListView_SetItemChecked($scraperList, $j, $bItemChecked)
							$aItemID[$j][1] = $bItemChecked
						EndIf
					Next
				EndIf
				; Click on only 1 item, so once a match is found, it's good.
				ExitLoop
			EndIf
		Next
	Wend

	GUIDelete($guiScrapers)
	; Restore tray icon functions.
	TraySetClick(9)
EndFunc


	
Func GetScraperPath()
	; Open the config.xml to see the folder.
	; Return: the path string to the scrapers
	Local $stashPath = StringLeft( $stashFilePath, StringInStr($stashFilePath, "\", 2, -1) )
	; $stashPath has "\" in the end.
	Local $hFile = FileOpen($stashPath & "config.yml")
	If $hFile = -1 Then 
		MsgBox(16,"Error open config.yml","Error opening the Stash's config file: config.yml",0)
		Return SetError(1)
	EndIf
	Local $sLine
	; Read the config.yml
	While True 
		$sLine =  FileReadLine($hFile)
		If @error = -1 Then
			; Reach the end of the file, set to default as last resort
			$sLine = "scrapers_path: scrapers"
			ExitLoop 
		ElseIf @error Then 
			MsgBox(16,"Error reading config.yml","Error reading the Stash's config file: config.yml",0)
			FileClose($hFile)
			Return SetError(1)
		EndIf
		If StringLeft($sLine, 14) = "scrapers_path:" Then ExitLoop 
	Wend
	FileClose($hFile)
	
	; Get scraper path, create the path if it doesn't exist
	Local $sPath = $stashPath & StringMid($sLine, 16 ) & "\"
	If Not FileExists($sPath) Then 
		DirCreate($sPath)
	EndIf
	Return $sPath
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
Func SetScraperArray()
	; Set the global $aScraperArray
	$iCount = 0
	
	Local $bGetList = True, $sLine
	$aScraperFiles = _FileListToArray($sScraperPath, "*.yml", $FLTA_FILES)

	If FileExists($sScraperPath & "SCRAPERS-LIST.md") Then 
		Local $sTime = FileGetTime($sScraperPath & "SCRAPERS-LIST.md", $FT_CREATED, $FT_STRING)
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
			Return SetError(1)
		EndIf
	EndIf 
		
	$hFile = FileOpen($sScraperPath & "SCRAPERS-LIST.md")
	If $hFile = -1 Then 
		MsgBox(16,"Error open SCRAPERS-LIST.md","Error opening stash's scraper list file.",0)
		Return SetError(1)
	EndIf
	
	; Skip all the lines until "---------"
	While True 
		$sLine = FileReadLine($hFile)
		If stringleft($sLine, 10) = "----------" Then 
			ExitLoop
		ElseIf @error Then 
			MsgBox(16,"Error reading SCRAPERS-LIST.md","Error reading stash's scraper list file.",0)
			Return SetError(1)
		EndIf
	WEnd 

	; Read the data and set them in the array
	While True 
		$sLine = FileReadLine($hFile)
		If @error = -1 Then 
			; End of the file
			ExitLoop 
		ElseIf @error Then
			; Other errors.
			MsgBox(16,"Error reading SCRAPERS-LIST lines","Error reading scraper list lines.",0)
			Return SetError(1)
		EndIf
		
		Local $aData = StringSplit($sLine, "|")
		; Replace the check mark with check symbol, :x: with x
		$sLine = StringReplace($sLine, ":heavy_check_mark:", "√", 0, 2)
		$sLine = StringReplace($sLine, ":x:", "x", 0, 2)
		
		; Get the yml file name
		$iPos1 = StringInStr($sLine, "|", 2, 1)
		$iPos2 = StringInStr($sLine, "|", 2, 2)
		$sYml = StringMid($sLine, $iPos1 + 1, $iPos2-$iPos1-1 )

		; Search this one in the files array
		$result = _ArraySearch($aScraperFiles, $sYml, 0, 0, 0, 2)
		$sInstalled = ($result= -1 )? "No|" : "Yes|"
		
		; Add "Installed" to the array before the ExtraReq
		$iPos = StringInStr($sLine, "|", 2, -2)
		$sFinalLine = StringLeft($sLine, $iPos) & $sInstalled & StringMid($sLine, $iPos + 1)
		
		; Add the whole line to the end of the array.
		ReDim $aScraperArray[$iCount + 1]
		$aScraperArray[$iCount] = $sFinalLine
		$iCount += 1
	Wend
	FileClose($hFile)
	$hCurrentGUI = 0
EndFunc
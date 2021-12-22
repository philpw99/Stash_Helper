;ScrapeSpecial2.au3
; For special scrapers.

Global $sSpecialScrapersPath = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "SpecialScrapersPath")
Global $aSpecialScrapers[0][3]
Global Enum $SCRAPER_FILE, $SCRAPER_URL, $SCRAPER_TYPE

If $sSpecialScrapersPath = "" Then 
	$sSpecialScrapersPath = @AppDataDir & "\Stash_Helper\Scrapers\"
	If Not FileExists($sSpecialScrapersPath) Then DirCreate($sSpecialScrapersPath)
	RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "SpecialScrapersPath", "REG_SZ", $sSpecialScrapersPath)
	; For temp html and images
	If Not FileExists($sSpecialScrapersPath & "temp") Then DirCreate($sSpecialScrapersPath & "temp")
EndIf



Func ScrapeSpecial()
	; Show the explanation.
	Local  $iSkipScraperExplain = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "SkipScraperExplained")
	If $iSkipScraperExplain <> 1 Then 
		$guiScrapeExplained = GUICreate("Scrape The Unscrapable Explained",791,581,-1,-1,$WS_SIZEBOX,-1)
		GUICtrlCreateLabel("Q: Why we need special scrapers?"&@crlf&""&@crlf&"A: Some websites have paywalls/login/anti-scraping blocks, which will effective blocks the uses of any scrapers in Stash."&@crlf&""&@crlf&"This function will use Webdriver to open the webpage and let you bypass all those protections."&@crlf&""&@crlf&"Due to my program limits, image/cover scraping probably will fail.",60,30,687,292,-1,-1)
		GUICtrlSetFont(-1,10,400,0,"Tahoma")
		GUICtrlSetBkColor(-1,"-2")
		GUICtrlSetResizing(-1,102)
		$chkNotShowExplanation = GUICtrlCreateCheckbox("I got it. Don't show this again.",162,328,413,45,-1,-1)
		GUICtrlSetFont(-1,12,400,0,"Tahoma")
		GUICtrlSetResizing(-1,960)
		$btnOK = GUICtrlCreateButton("OK",217,398,271,53,-1,-1)
		GUICtrlSetFont(-1,12,400,0,"Tahoma")
		GUICtrlSetResizing(-1,960)
		GUISetState(@SW_SHOW)
		While True
			$nMsg = GUIGetMsg()
			Switch $nMsg
				Case $btnOK
					If GUICtrlRead($chkNotShowExplanation) = $GUI_CHECKED Then 
						; check to not show this again.
						RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "SkipScraperExplained", "REG_DWORD", 1)
					EndIf
					ExitLoop
				Case $GUI_EVENT_CLOSE
					ExitLoop 
			EndSwitch
		Wend
		GUIDelete($guiScrapeExplained)
	EndIf 

	$sURL = GetURL()
	if @error Then Return SetError(1)

	$sResult = GetCurrentTabCategoryAndNumber()
	If @error Then Return SetError(1)
	$aStr = StringSplit($sResult, "-")
	c("result:" & $sResult)
	$sCategory = $aStr[1]
	; If $aStr[0]=1 it's the main category
	; If the tab is a single scene/movie, $aStr[2] will be a number
	; If the tab is a collection, $aStr[2] will be "c"
	If $aStr[0] = 1 Then 
		MsgBox(0, "Cannot be in the main category.", "This will not work when the browser is in a main category.")
		Return 
	Elseif	$aStr[2] = "c" Then 
		MsgBox(0, "Need to be a single scene/movie/gallery/performer", "The current Stash browser tab should be a single scene/movie/gallery/performer.")
		Return
	ElseIf Not StringIsDigit($aStr[2]) Then
		MsgBox(0, "Oops!", "Program error, cannot get the id. Cannot proceed!")
		Return 
	EndIf
	$sID = $aStr[2]

	; Prepare the data	
	$sClip = ClipGet()
	If stringleft($sClip, 4) <> "http" Then $sClip = ""
	LoadSpecialScrapers()
	; _ArrayDisplay($aSpecialScrapers)

	$guiScrapeSpecial = GUICreate("ScrapeSpecial",1283,569,-1,-1,BitOr($WS_SIZEBOX,$WS_SYSMENU),BitOr($WS_EX_TOPMOST,$WS_EX_DLGMODALFRAME))
	GUICtrlCreateLabel("Current Stash Tab:",9,30,192,38,$SS_RIGHT,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,802)
	
	$inputStashURL = GUICtrlCreateInput("",230,30,668,36,$ES_READONLY,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,550)
	GUICtrlSetData($inputStashURL, $sURL)
	
	$lbStashStatus = GUICtrlCreateLabel("Stash OK.",926,32,159,36,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,804)
	
	GUICtrlCreateLabel("URL to Scrape:",46,96,155,32,$SS_RIGHT,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,802)

	$inputURL = GUICtrlCreateInput("",230,90,668,38,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,550)
	GUICtrlSetData($inputURL, $sClip)

	$lbURLStatus = GUICtrlCreateLabel("URL OK.",925,90,159,36,-1,-1)
	If $sClip = "" Then GUICtrlSetData($lbURLStatus, "Missing URL.")
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,804)
	
	GUICtrlCreateLabel("Special Scrapers:",9,160,192,29,$SS_RIGHT,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,802)
	
	$btnOpenScraperFolder = GUICtrlCreateButton("Open Scraper Folder",926,160,273,58,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)

	GUICtrlCreateLabel("Step 1: Load the Webpage by URL.",47,378,450,47,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,834)

	GUICtrlCreateLabel("Step 2: Webpage is ready. Scrape.",50,461,452,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,834)

	$btnStartScraping = GUICtrlCreateButton("Start Scraping",570,461,297,57,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,834)
	GUICtrlSetState($btnStartScraping, $GUI_DISABLE )

	$lvSpecialScrapers = GUICtrlCreatelistview("File|URL|Type",230,160,665,188,-1,BitOr($LVS_EX_GRIDLINES,$WS_EX_CLIENTEDGE))
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetResizing(-1,102)
	_GUICtrlListView_SetColumnWidth($lvSpecialScrapers, 0, 250)
	_GUICtrlListView_SetColumnWidth($lvSpecialScrapers, 1, 300)
	_GUICtrlListView_SetColumnWidth($lvSpecialScrapers, 2, 100)
	
	; Set listview data
	_GUICtrlListView_AddArray($lvSpecialScrapers, $aSpecialScrapers)

	$btnLoadWebPage = GUICtrlCreateButton("Load Web Page",570,368,297,57,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,834)
	GUICtrlSetState($btnLoadWebPage, $GUI_DISABLE)
	
	; Check if btnLoadWebPage should be enable or not.
	$sText = GUICtrlRead($inputURL)
	If StringLower(stringleft($sText, 4)) = "http" Then
		; Valid URL
		$iRow = GetSpecialScraperRow($sText, StringTrimRight($sCategory, 1) )
		If $iRow <> -1 Then
			; Found the row
			_GUICtrlListView_SetItemSelected($lvSpecialScrapers, $iRow)
			_GUICtrlListView_EnsureVisible($lvSpecialScrapers, $iRow)
			GUICtrlSetState($btnLoadWebPage, $GUI_ENABLE)
		EndIf
	EndIf


	GUISetState(@SW_SHOW, $guiScrapeSpecial)
	
	; Disable the tray clicks
	TraySetClick(0)

 	;  Save the current tab handle.
	$sHandle = _WD_Window($sSession, "Window")
	$sHandle = '{"handle":"' & $sHandle & '"}'

	While True 
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $inputURL
				$sText = GUICtrlRead($inputURL)
				If StringLower(stringleft($sText, 4)) = "http" Then
					; Valid URL
					$iRow = GetSpecialScraperRow($sText, StringTrimRight($sCategory, 1) )
					If $iRow <> -1 Then
						; Found the row
						_GUICtrlListView_SetItemSelected($lvSpecialScrapers, $iRow)
						_GUICtrlListView_EnsureVisible($lvSpecialScrapers, $iRow)
						GUICtrlSetState($btnLoadWebPage, $GUI_ENABLE)
					EndIf

				EndIf
			Case $btnOpenScraperFolder
				ShellExecute($sSpecialScrapersPath)
			Case $btnLoadWebPage
				$sText = GUICtrlRead($inputURL)
				_WD_NewTab($sSession, Default, Default, $sText , Default)
			Case $btnStartScraping
				; Start Scraping.

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	Wend
	GUIDelete($guiScrapeSpecial)
	; Enable the tray clicks
	TraySetClick(9)

EndFunc

Func GetSpecialScraperRow($sURL, $sType)
	For $i = 0 to UBound($aSpecialScrapers) -1
		If StringInStr($sURL, $aSpecialScrapers[$i][$SCRAPER_URL], 2) <> 0 _ 
			And $sType = $aSpecialScrapers[$i][$SCRAPER_TYPE] Then
			Return $i
		EndIf
	Next
	Return -1
EndFunc

Func LoadSpecialScrapers()
	; load the files to the array. Read the files and get their url
	; Global $aSpecialScrapers[0][3]
	; Global Enum $SCRAPER_FILE, $SCRAPER_URL, $SCRAPER_TYPE

	$aFiles = _FileListToArray($sSpecialScrapersPath, "*.yml", $FLTA_FILES)
	If $aFiles[0] = 0 Then
		c("No files.")
		Return 
	Else 
		c("files:" & $aFiles[0])
	EndIf
	
	Local $sType = "", $bURLstart = False 
	For $i = 1 to $aFiles[0]
		$hFile =  FileOpen($sSpecialScrapersPath & $aFiles[$i])
		c("Opening:" & $sSpecialScrapersPath & $aFiles[$i] & " hFile:" &  $hFile)
		If $hFile = -1 Then Return SetError(1)
		
		$sLine = StringStripWS( FileReadLine($hFile), 3)

		; Start to read lines in this file
		While $sLine <> "xPathScrapers:"
			$sLine = FileReadLine($hFile)
			; In case it reaches the end.
			If @error Then ExitLoop 
			$sLine = StringStripWS($sLine, 3)
			; c("Line:" & $sLine)
			Switch $sLine
				; Set the url type
				Case "sceneByURL:"
					$sType = "scene"
					ContinueLoop 
				Case "performerByURL:"
					$sType = "performer"
					ContinueLoop 
				Case "galleryByURL:"
					$sType = "gallery"
					ContinueLoop 
				Case "movieByURL:"
					$sType = "movie"
					ContinueLoop
				Case "URL:", "url:"
					; The following is URL
					$bURLstart = True 
					ContinueLoop 
			EndSwitch 
			If StringLower(StringLeft($sLine, 8)) = "scraper:" Then 
				; URL list is finished.
				$bURLstart = False 
				ContinueLoop 
			EndIf
			If stringleft($sLine,1) = "-" And $bURLstart Then 
				; Add one item to the array.
				$j = UBound($aSpecialScrapers)
				ReDim $aSpecialScrapers[$j + 1][3]
				$aSpecialScrapers[$j][$SCRAPER_FILE] = $aFiles[$i]
				$aSpecialScrapers[$j][$SCRAPER_URL] = StringStripWS( stringmid($sLine, 2), 3 )
				$aSpecialScrapers[$j][$SCRAPER_TYPE] = $sType
			EndIf
		Wend
		FileClose($hFile)
	Next
EndFunc
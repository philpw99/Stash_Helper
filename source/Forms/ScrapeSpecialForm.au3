;ScrapSpecialForm.au3

Global Const $TempHtmlFile = "StashHelperTemp.html", $SpecialScraper = "StashHelper.yml"


Func ScrapeSpecial()
	$sResult = GetCurrentTabCategoryAndNumber()
	Local $sHandle
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
		MsgBox(0, "Need to be a single scene/movie/gallery/performer", "The current Stash browser tab should be a single scene/movie/performer/gallery.")
		Return
	ElseIf Not StringIsDigit($aStr[2]) Then
		MsgBox(0, "Oops!", "Program error, cannot proceed!")
		Return 
	EndIf
	$sID = $aStr[2]
	; Disable the tray clicks
	TraySetClick(0)
	
	; Show the explanation.
	Local  $iSkipScraperExplain = RegRead("HKEY_CURRENT_USER\Software\Stash_Helper", "SkipScraperExplain")
	If $iSkipScraperExplain <> 1 Then 
		$guiScrapeExplain = GUICreate("Scrape The Unscrapable Explained",1049,617,-1,-1,$WS_SIZEBOX,-1)
		GUICtrlCreateLabel("Q: Why we need this special scraper?"&@crlf _ 
			&"A: Some websites have paywalls/login/scraping blocks, which will effective blocks the uses of any scrapers." _ 
			&@crlf&"Now this function is using Webdriver to open the webpage and let you bypass all those protections."&@crlf _ 
			&"To use it:"&@crlf&"  1. Get the URL ready in the clipboard. Paste it in the inputbox coming up next."&@crlf _ 
			&"  2. Stash_Helper then will open a new webpage with the URL you pasted. Click on login/verification or anything that's required to see the real content."&@crlf _ 
			&"  3. When the webpage is finally ready for scraping, click on the 'Start Scraping' button in the small window."&@crlf _ 
			&"Stash_Helper will fetch the webpage to a temp folder, uses a special scraper called 'StashHelper.yml' to scrape the content. And you will see the result.", _ 
			60,30,942,373,-1,-1)
		GUICtrlSetFont(-1,10,400,0,"Tahoma")
		GUICtrlSetBkColor(-1,"-2")
		GUICtrlSetResizing(-1,102)
		$chkNotShowExplanation = GUICtrlCreateCheckbox("I got it. Don't show this again.",293,430,413,45,-1,-1)
		GUICtrlSetFont(-1,12,400,0,"Tahoma")
		GUICtrlSetResizing(-1,960)
		$btnOK = GUICtrlCreateButton("OK",370,510,271,53,-1,-1)
		GUICtrlSetFont(-1,12,400,0,"Tahoma")
		GUICtrlSetResizing(-1,960)
		GUISetState(@SW_SHOW)
		While True
			$nMsg = GUIGetMsg()
			Switch $nMsg
				Case $btnOK
					If GUICtrlRead($chkNotShowExplanation) = $GUI_CHECKED Then 
						; check to not show this again.
						RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "SkipScraperExplain", "REG_DWORD", 1)
					EndIf
					ExitLoop
				Case $GUI_EVENT_CLOSE
					ExitLoop 
			EndSwitch
		Wend
		GUIDelete($guiScrapeExplain)
	EndIf
	
	; Now ask the URL
	$sScrapeURL = InputBox("URL Input", "Please paste your URL below.")
	; load the scrapers to the $aScraperArray if needed
	If UBound($aScraperArray) = 0 Or $sScraperPath = "" Then
		$sScraperPath = GetScraperPath()
		SetScraperArray()
	EndIf
	If @error then 
		; restore the tray icon functions.
		TraySetClick(9)
		Return SetError(1)
	EndIf
	
	; Find the right scraper
	Local $sScraperFile = "", $sInstalled
	For $i = 0 To UBound($aScraperArray) -1
		$aLine = StringSplit($aScraperArray[$i], "|")
		; $aLine[1] is the website
		If StringInStr($sScrapeURL, $aLine[1], 2) <> 0 Then
			; Found the correct line
			$sScraperFile = $aLine[2]
			$sInstalled = $aLine[7]
			ExitLoop
		EndIf
	Next
	c("Installed:" & $sInstalled)
	If $sScraperFile = "" Then 
		; No scraper for this URL
		MsgBox(0, "No scrapers for this URL", "Just search all the scraper list, but cannot find a scraper that can be used for your URL.")
		; restore the tray icon functions.
		TraySetClick(9)
		Return
	ElseIf $sInstalled <> "Yes" Then 
		$iReply = MsgBox(1,"Scraper Not Installed","We found the scraper: " & $sScraperFile & ", but it is not installed yet. Do you want to install it now?",0)
		switch $iReply
			case 1 ;OK
				; Set the global
				If $sScraperPath = "" Then $sScraperPath = GetScraperPath()
				FetchScraper($sScraperFile)
				; Now reload the scrapers
				ReloadScrapers()
				MsgBox(0, "OK, scraper installed", "The scraper is installed. Now we can continue.")
				
			case 2 ;CANCEL
				; Return
		endswitch
	EndIf ; End of if the scraper is installed.
	
	;  Save the current tab handle.
	$sHandle = _WD_Window($sSession, "Window")
	$sHandle = '{"handle":"' & $sHandle & '"}'
	
	_WD_NewTab($sSession, Default, Default, $sScrapeURL , Default)

	; Now show the mini scrape window
	$guiScrapeSpecial = GUICreate("ScrapeSpecial",528,258,-1,-1,$WS_SYSMENU,BitOr($WS_EX_TOPMOST,$WS_EX_DLGMODALFRAME))
	$btnStartScraping = GUICtrlCreateButton("StartScraping",110,130,297,84,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlCreateLabel("When the webpage is ready, click the button below.",40,20,427,81,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUISetState(@SW_SHOW)
	While True
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnStartScraping
				
				WriteTempHTML()
				If @error Then ExitLoop 
				; Close the current tab
				_WD_Window($sSession, "Close")
				; Now create a special scraper.
				CreateSpecialScraper($sScraperFile)
				If @error Then ExitLoop 
				; MsgBox(0, "scraper created", "check it out.")
				; Reload the scrapers
				ReloadScrapers()
				; Get the scraper ID of StashHelper
				
				; Ready the Mini Web Server, pass the quoted temp dir as directory.
				; Run(@ScriptDir & "\AutoIt3.exe", @ScriptDir, Q(@TempDir) )
				; Now you have 5 seconds to scrape it.
				
				
				ExitLoop 
			Case $GUI_EVENT_CLOSE
				$iReply = MsgBox(52,"Cancel the scraping?","Do you want to cancel the scraping?",0)
				switch $iReply
					case 6 ;YES
						ExitLoop 
					case 7 ;NO
						ContinueLoop 
				endswitch

		EndSwitch 
	WEnd
	; Switch back to the previous tab
	_WD_Window($sSession, "switch", $sHandle)

	GUIDelete($guiScrapeSpecial)
	; restore the tray icon functions.
	TraySetClick(9)

EndFunc 



	
Func WriteTempHTML()
	Local $sHTML = _WD_GetSource($sSession)
	If @error <> $_WD_ERROR_Success Then
		MsgBox(0, "Some error", "wd not successful.")
		Return SetError(1)
	EndIf

	Local $hFile = FileOpen(@TempDir & "\" & $TempHtmlFile, $FO_OVERWRITE)
	If @error Then
		MsgBox(0, "Error creating temp file.", "Try to create a temp file for html but failed.", 10)
		Return SetError(1)
	EndIf
	If FileWrite($hFile, $sHTML) = 0 Then 
		MsgBox(0, "Error writing file", "Error in writing the temp html file.")
		FileClose($hFile)
		Return SetError(1)
	EndIf
	FileClose($hFile)
EndFunc
	
Func CreateSpecialScraper($sScraperFile)
	; global $sScraperPath, $SpecialScraper
	Local $hSpecialFile = FileOpen($sScraperPath & $SpecialScraper, $FO_OVERWRITE)
	Local $sLine
	If @error Then
		MsgBox(0, "Error creating temp SCRAPER file.", "Try to create a temp scraper file but failed.", 10)
		Return SetError(1)
	EndIf
	Local $hScraperFile = FileOpen($sScraperPath & $sScraperFile)
	If @error Then
		MsgBox(0, "Error opening the scraper file.", "Try to open the scraper for this URL but failed.", 10)
		Return SetError(1)
	EndIf
	
	$sLine = FileReadLine($hScraperFile)
	If StringLeft($sLine, 5) = "name:" Then 
		FileWriteLine($hSpecialFile, "name: StashHelper")
	EndIf
	Local $bURLtag = False , $bURLwritten = False 
	While $sLine <> "xPathScrapers:"
		$sLine = FileReadLine($hScraperFile)
		If @error Then ExitLoop ; Just in case
		
		$sStr = StringStripWS($sLine, 3)
		if $sStr = "action: script" Then 
			MsgBox(0, "This is a python scraper", "Sorry, but I am afraid this will not work with a python scraper.")
			FileClose($hSpecialFile)
			FileClose($hScraperFile)
			FileDelete($sScraperPath & $SpecialScraper)
			Return SetError(1)
		EndIf
		
		If StringLeft($sStr, 4) = "url:" Then
			; The following are URLs
			$bURLtag = True
			FileWriteLine($hSpecialFile, $sLine)
			ContinueLoop
		EndIf
		
		If $bURLtag And StringLeft($sStr, 1) = "-" Then
			If Not $bURLwritten Then
				; First line of " - URL..."
				FileWriteLine($hSpecialFile, "      - localhost:9980")
				$bURLwritten = True
			Else
				; write nothing
			EndIf
			ContinueLoop 
		EndIf
		
		If stringleft($sStr, 8) = "scraper:" Then 
			; New section.
			$bURLtag = False
			$bURLwritten =  False 
		EndIf
		
		FileWriteLine($hSpecialFile, $sLine)
	Wend
	; Now just copy the rest
	While True 
		$sLine = FileReadLine($hScraperFile)
		If @error Then ExitLoop 
		FileWriteLine($hSpecialFile, $sLine)
	Wend
	FileClose($hSpecialFile)
	FileClose($hScraperFile)
	
EndFunc
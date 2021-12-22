Func ManagePlayList()
	; Global $aPlayList
	
	Global $guiManagePlayList = GUICreate("Manage Play List",1034,1037,-1,-1,$WS_SIZEBOX,-1)
	Global $lvPlayList = GUICtrlCreatelistview("#|Title|Duration|File/Path",30,60,959,864,-1,$WS_EX_CLIENTEDGE + $LVS_EX_FULLROWSELECT + $LVS_EX_GRIDLINES)
	_GUICtrlListView_SetTextBkColor($lvPlayList, $CLR_CREAM )
	GUICtrlSetResizing(-1,102)
	_GUICtrlListView_SetColumnWidth($lvPlayList, 0, 40)	 	; #
	_GUICtrlListView_SetColumnWidth($lvPlayList, 1, 300)	; Title
	_GUICtrlListView_SetColumnWidth($lvPlayList, 2, 100)	; Duration
	_GUICtrlListView_SetColumnWidth($lvPlayList, 3, 500)	; File
	_GUICtrlListView_JustifyColumn($lvPlayList, 0, 2)
	_GUICtrlListView_JustifyColumn($lvPlayList, 2, 2)
	Local $btnDelete = GUICtrlCreateButton("Delete",30,936,161,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Delete the current selected item from the list.")
	GUICtrlSetResizing(-1,834)
	Local $btnLoad = GUICtrlCreateButton("Load",621,937,161,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Load a play list file (.m3u) from a folder.")
	GUICtrlSetResizing(-1,836)
	Local $btnSave = GUICtrlCreateButton("Save",830,937,161,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Save the current list to a M3U file.")
	GUICtrlSetResizing(-1,836)
	Local $btnPlay = GUICtrlCreateButton("Play",236,937,161,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Play this list in external media player.")
	GUICtrlSetResizing(-1,834)
	Local $btnClear = GUICtrlCreateButton("Clear",422,937,161,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Clear the play list.")
	GUICtrlSetResizing(-1,960)

	; load the $aPlayList array to the list
	For $i = 0 To UBound($aPlayList)-1
		Local $iRow = _GUICtrlListView_AddItem($lvPlayList, $i+1)
		_GUICtrlListView_SetItemText($lvPlayList, $iRow, $aPlayList[$i][$LIST_TITLE], 1)
		_GUICtrlListView_SetItemText($lvPlayList, $iRow, TimeConvert($aPlayList[$i][$LIST_DURATION]), 2)
		_GUICtrlListView_SetItemText($lvPlayList, $iRow, $aPlayList[$i][$LIST_FILE], 3)
	Next 

	; Disable the tray clicks
	TraySetClick(0)

	GUISetState(@SW_SHOW, $guiManagePlayList)
	
	While True 
		; if click on tray icon, activate the current GUI
		Local $nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiManagePlayList)
 		EndSwitch 

		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnDelete
				; Delete the highlighted item in the play list.
				_GUICtrlListView_DeleteItemsSelected($lvPlayList)
			
			Case $btnLoad
				LoadList($lvPlayList)
			Case $btnSave
				SaveList($lvPlayList)
			Case $btnPlay	
				SendPlayerList()
			Case $btnClear
				ClearPlayList()
				_GUICtrlListView_DeleteAllItems($lvPlayList)

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
		
	Wend
	
	GUIDelete($guiManagePlayList)
	; restore the tray icon functions.
	TraySetClick(9)

EndFunc

; Save the list as m3u file
Func SaveList($lvPlayList)
	; Save the play list to a m3u file.
	Local $sFileSaveDialog = FileSaveDialog("Save the m3u list file as:", @DocumentsCommonDir, _ 
		"M3U Play List File (*.m3u)", 16, "MyPlaylist.m3u" )
	If @error Then
        ; Display the error message.
        MsgBox($MB_SYSTEMMODAL, "", "No file was saved.")
		Return SetError(1)
    EndIf
	
	; Retrieve the filename from the filepath e.g. Example.au3.
	Local $sFileName = StringTrimLeft($sFileSaveDialog, StringInStr($sFileSaveDialog, "\", 2, -1))

	; Check if the extension .au3 is appended to the end of the filename.
	Local $iExtension = StringInStr($sFileName, ".", 2, -1)

	; If a period (dot) is found then check whether or not the extension is equal to .au3.
	If $iExtension Then
		; If the extension isn't equal to .au3 then append to the end of the filepath.
		If StringTrimLeft($sFileName, $iExtension - 1) <> ".m3u" Then $sFileSaveDialog &= ".m3u"
	Else
		; If no period (dot) was found then append to the end of the file.
		$sFileSaveDialog &= ".m3u"
	EndIf
	; set the file name again after modification
	$sFileName = StringTrimLeft($sFileSaveDialog, StringInStr($sFileSaveDialog, "\", 2, -1))
	
	; Display the saved file.
	; MsgBox($MB_SYSTEMMODAL, "", "You saved the following file:" & @CRLF & $sFileSaveDialog)
	
	Local $hFile = FileOpen($sFileSaveDialog, $FO_OVERWRITE)
	If $hFile = -1 Then 
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when creating the file.")
		Return SetError(1)
	EndIf
	
	; Write the required first line.
	FileWriteLine($hFile, "#EXTM3U")
	; Now write the file/path list
	Local $iCount = UBound($aPlayList)
	Local $sTitle, $sFile
	For $i = 0 to $iCount-1
		$sTitle = $aPlayList[$i][$LIST_TITLE]
		Local $iDuration = $aPlayList[$i][$LIST_DURATION]
		$sFile = $aPlayList[$i][$LIST_FILE]
		Local $line = "#EXTINF:" & $iDuration & "," & $sTitle
		FileWriteLine($hFile, $line ) ; $aData[2] is the name of the file.
		; Write the real file/path on second line.
		FileWriteLine($hFile, $sFile)
	Next
	FileClose($hFile)
	MsgBox($MB_ICONINFORMATION, "File Saved.", "This file:" & $sFileName & " was saved.")
EndFunc


; Load the saved m3u to the play list.
Func LoadList($lvPlayList)
	; Global $aPlayList
	Local $sFileOpenDialog = FileOpenDialog("Open the m3u list file:", @DocumentsCommonDir, _ 
		"M3U Play List File (*.m3u)", 3 )
	If @error Then
        ; Display the error message.
        MsgBox($MB_SYSTEMMODAL, "", "No file was opened.")
		Return SetError(1)
    EndIf
	
	If StringInStr($sFileOpenDialog, "|") <> 0 Then 
        MsgBox($MB_SYSTEMMODAL, "", "Only one file is allowed.")
		Return SetError(1)
	EndIf
	
	Local $hFile = FileOpen($sFileOpenDialog, $FO_READ)
	If $hFile = -1 Then 
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when opening the file.")
        Return SetError(1)
	EndIf
	
	; Clean up the list view first
	_GUICtrlListView_DeleteAllItems($lvPlayList)
	; Clear the array.
	Global $aPlayList[0][3]
	
	Local $EOF = False 
	While Not $EOF
		Local $sLine = FileReadLine($hFile)
		If @error Then
			$EOF = True
			ExitLoop 
		EndIf
		; Ignore the extra info line
		If StringLeft($sLine, 8) = "#EXTINF:" then
			$i = UBound($aPlayList)
			ReDim $aPlayList[$i+1][3]
			; Add the item to the array.
			Local $iPos = StringInStr($sLine, ",", 2)
			Local $sTitle = stringmid($sLine, $iPos + 1 )
			Local $iDuration = Int( StringMid($sLine, 9, $iPos-9) )
			$aPlayList[$i][$LIST_TITLE] = $sTitle
			$aPlayList[$i][$LIST_DURATION] = $iDuration
			$aPlayList[$i][$LIST_FILE] = StringStripWS( FileReadLine($hFile), 3) ; The full file/path
			
			; Add the item to the list
			Local $iRow = _GUICtrlListView_AddItem($lvPlayList, $i+1)
			_GUICtrlListView_SetItemText($lvPlayList, $iRow, $sTitle, 1)
			_GUICtrlListView_SetItemText($lvPlayList, $iRow, TimeConvert($iDuration), 2)
			_GUICtrlListView_SetItemText($lvPlayList, $iRow, $aPlayList[$i][$LIST_FILE], 3)
		EndIf
	WEnd 
	FileClose($hFile)
EndFunc

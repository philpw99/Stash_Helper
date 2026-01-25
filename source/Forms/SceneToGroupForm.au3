Func Scene2Group()
	Global $mInfo
	; First to switch to the scene tab. * Disabled, no need to switch
	; SwitchToTab("scenes")
	; If @error Then Return SetError(1)
	Local $sURL = _WD_Action($sSession, "url")
	Local $nScene = GetNumber($sURL, "scenes")
	If @error Then Return SetError(2)
	; Get Scene info will set the global $mInfo
	GetSceneInfo($nScene)
	If @error Then Return SetError(3)

	; Now show a GUI and ask which info to copy over.
	Global $guiScene2Group = GUICreate("Copy Scene Info To Group",766,968,-1,-1,$WS_SIZEBOX,-1)
	GUICtrlCreateLabel("Please choose the information you like to transfer to the group.",80,19,698,80,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,550)
	Global $lvValues = GUICtrlCreatelistview("#|Properties|Value",32,110,703,282,$LVS_SINGLESEL,BitOr($LVS_EX_FULLROWSELECT,$LVS_EX_CHECKBOXES,$WS_EX_STATICEDGE))
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,550)
	_GUICtrlListView_SetColumnWidth($lvValues, 0, 40)
	_GUICtrlListView_SetColumnWidth($lvValues, 1, 200)
	_GUICtrlListView_SetColumnWidth($lvValues, 2, 450)
	GUICtrlCreateListViewItem("1|Title|" & $mInfo.Item("Title"), $lvValues)		;0
	GUICtrlCreateListViewItem("1|URL|" & $mInfo.Item("URL"), $lvValues)			;1
	GUICtrlCreateListViewItem("1|Date|" & $mInfo.Item("Date"), $lvValues)		;2
	GUICtrlCreateListViewItem("1|Duration|" & TimeConvert($mInfo.Item("Duration")), $lvValues)	;3
	GUICtrlCreateListViewItem("1|Details|" & $mInfo.Item("Details"), $lvValues)	;4
	GUICtrlCreateListViewItem("1|Studio|" & $mInfo.Item("StudioName"), $lvValues);5
	For $i = 0 To 5
		; Make all the item checked
		_GUICtrlListView_SetItemChecked($lvValues, $i)
	Next
	Local $btnOK = GUICtrlCreateButton("OK",548,448,184,54,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)
	
	Local $btnCancel = GUICtrlCreateButton("Cancel",548,516,184,54,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)
	
	local $btnBatchCreateStudio = GUICtrlCreateButton("Create groups for scenes in same Studio",100,780,555,51,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Create groups for all other scenes in the same studio that don't link to a group yet.")
	GUICtrlSetResizing(-1,836)

	
	Local $btnBatchCreate = GUICtrlCreateButton("Create groups for all other scenes",100,846,555,51,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Create groups for all other scenes which have no groups yet. Following the checked items here.")
	GUICtrlSetResizing(-1,836)
	
	; Download the image to temp folder.
	Local $sExt = StringMid($mInfo.Item("ScreenShot"), stringinstr($mInfo.Item("ScreenShot"), ".", 2, -1))
	Local $sTempPicFile = @TempDir & "\temp" & $sExt
	InetGet($mInfo.Item("ScreenShot"), $sTempPicFile)
	Local $imgCover = GUICtrlCreatePic($sTempPicFile,29,448,455,314,-1,$WS_EX_STATICEDGE)
	GUICtrlSetResizing(-1,102)
	
	Local $chkCover = GUICtrlCreateCheckbox("Cover",39,405,150,33,-1,-1)
	GUICtrlSetState($chkCover, $GUI_CHECKED)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,802)
	
	; Disable the tray clicks
	TraySetClick(0)

	GUISetState(@SW_SHOW, $guiScene2Group)
	While True 
		; if click on tray icon, activate the current GUI
		Local $nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiScene2Group)
 		EndSwitch 

		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnOK
				CreateSingleGroup($lvValues, $chkCover)
				RefreshAllTabs()
				ExitLoop
			Case $btnBatchCreate
				BatchCreate($lvValues, $chkCover)
				RefreshAllTabs()
				ExitLoop
			Case $btnBatchCreateStudio
				If $mInfo.Item("StudioID") = Null Then 
					MsgBox(0, "No Studio", "This scene doesn't have a studio.")
					ContinueLoop 
				EndIf
				; Add aditional filter.
				BatchCreate($lvValues, $chkCover, ",studios:{value:"& $mInfo.Item("StudioID") & ", modifier:INCLUDES}")
				RefreshAllTabs()
				ExitLoop
			Case $GUI_EVENT_RESIZED
				GUICtrlSetImage($imgCover, $sTempPicFile)
			Case $GUI_EVENT_CLOSE, $btnCancel
				ExitLoop 
		EndSwitch
	Wend
	GUIDelete($guiScene2Group)
	; restore the tray icon functions.
	TraySetClick(9)
EndFunc

Func BatchCreate($lvValues, $chkCover, $sFilter = "")
	; Global $mInfo, it should be a dictionary object
	
	Local $reply = MsgBox(262449,"Warning.","This function will create one group for every scene that's not linked to a group yet." _ 
		& @CRLF & "Also it will follow the check boxes here to only retrieve the information you specified." _
		& @CRLF & "However, it might create a lot of groups in the process. The problem is more serious when you have multiple scenes meant for the same group." _
		& @CRLF & "So are you sure you want to continue?",0)
	If $reply = 2 Then Return 
	
	Local $bGetTitle = _GUICtrlListView_GetItemChecked($lvValues, 0)
	Local $bGetUrl = _GUICtrlListView_GetItemChecked($lvValues, 1)
	Local $bGetDate = _GUICtrlListView_GetItemChecked($lvValues, 2)
	Local $bGetDuration = _GUICtrlListView_GetItemChecked($lvValues, 3)
	Local $bGetDetails = _GUICtrlListView_GetItemChecked($lvValues, 4)
	Local $bGetStudio = _GUICtrlListView_GetItemChecked($lvValues, 5)
	Local $bGetCover = (GUICtrlRead($chkCover) = $GUI_CHECKED )
	
	If Not $bGetTitle Then
		; Title was not check, exit
		MsgBox(48,"Must have title checked.","The check box next to 'Title' must be checked, because in this batch mode, title is mandatory.",0)
		Return
	EndIf
	
	; Now get the list of all scenes without a group
	local $sQuery = '{ "query": "{findScenes(scene_filter:{is_missing: \"group\"' _ 
		& $sFilter & '}filter:{per_page:-1}){count,scenes{id}}}" }'
	Local $sResult = Query($sQuery)
	If @error Then Return SetError(1)

	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	Local $oData = Json_ObjGet($oResult, "data.findScenes")
	Local $iCount = $oData.Item("count")

	If $iCount = "" Or $iCount = 0 Then
		MsgBox(0, "No scenes", "There is no scenes to create groups.")
		Return
	EndIf
	Local $aScenes = Json_ObjGet($oData, "scenes")
	If @error Then 
		MsgBox(0, "error decoding", "Error in decoding data from the query")
		Return SetError(1)
	EndIf
	
	$iCount = UBound($aScenes) ; For some reason, the previous iCount has serious problem
	Local $aIDs[$iCount]  ; Create an array for ids

	For $i = 0 To $iCount-1
		; get the string IDs
		$aIDs[$i] = $aScenes[$i].Item("id")
	Next
	
	; Batch create groups
	
	; Set mouse cursor to wait.
	Local $old_cursor = MouseGetCursor()
	GUISetCursor(15, 1, $guiScene2Group)

	Local $iGroupCreated = 0
	For $i = 0 to $iCount-1
		; Set the scene info in $mInfo
		GetSceneInfo($aIDs[$i])
		If Not $bGetURL Then $mInfo.Item("Url") = Null 
		If Not $bGetDate Then $mInfo.Item("Date") = Null 
		If Not $bGetDuration Then $mInfo.Item("Duration") = Null 
		If Not $bGetDetails Then $mInfo.Item("Details") = Null 
		If Not $bGetStudio Then $mInfo.Item("StudioID") = Null 
		If Not $bGetCover Then $mInfo.Item("ScreenShot") = Null
		; Now the info is ready.
		$sQuery =  '{"query": "mutation{ groupCreate(input:{name: \"' & $mInfo.Item("Title") & '\",' & _
			($mInfo.Item("Date") = Null ? "" : 'date: \"' & $mInfo.Item("Date") & '\",' ) & _
			($mInfo.Item("Details") = Null ? "" : 'synopsis: \"'& $mInfo.Item("Details") & '\",' ) & _
			($mInfo.Item("URL") = Null ? "" : 'urls: [\"' & $mInfo.Item("URL") & '\"],' ) & _
			($mInfo.Item("StudioID") = Null ? "" : 'studio_id:' & $mInfo.Item("StudioID") & ',' )& _
			($mInfo.Item("ScreenShot") = Null ? "" : 'front_image:\"' & $mInfo.Item("ScreenShot") & '\",' )& _
			($mInfo.Item("Duration") = 0 ? "" : 'duration: ' & $mInfo.Item("Duration") ) & _
			'}){id} }"}'
		
		; OK, now create a new group base on the above.
		$sResult = Query($sQuery)
		If @error Then ExitLoop 
		
		$oResult = Json_Decode($sResult)
		If Not IsObj($oResult) Then
			MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
			Return SetError(1)
		EndIf
		$mInfo.Item("GroupID") = Json_ObjGet($oResult, "data.groupCreate.id")
		
		; Now update the scene
		$sQuery = '{"query":"mutation{sceneUpdate(input:{id:' & $mInfo.Item("SceneID") & ',groups:{group_id:' _ 
			& $mInfo.Item("GroupID") & '}}){id}}"}'
		$sResult = Query($sQuery)
		If @error Then ExitLoop 

		$iGroupCreated += 1
	Next
	
	; Set cursor back.
	GUISetCursor($old_cursor, 1, $guiScene2Group)

	_WD_Action($sSession, 'refresh')
	MsgBox(0, "Job Done", "Total group created: " & $iGroupCreated)
	
EndFunc


Func CreateSingleGroup($lvValues, $chkCover)
	; Global $mInfo
	Local $bGetTitle = _GUICtrlListView_GetItemChecked($lvValues, 0)
	Local $bGetUrl = _GUICtrlListView_GetItemChecked($lvValues, 1)
	Local $bGetDate = _GUICtrlListView_GetItemChecked($lvValues, 2)
	local $bGetDuration = _GUICtrlListView_GetItemChecked($lvValues, 3)
	Local $bGetDetails = _GUICtrlListView_GetItemChecked($lvValues, 4)
	Local $bGetStudio = _GUICtrlListView_GetItemChecked($lvValues, 5)
	; ConsoleWrite("check state:" & GUICtrlGetState($chkCover))
	Local $bGetCover = ( GUICtrlRead($chkCover) = $GUI_CHECKED )
	; c("get cover?" & $bGetCover)
	Local $input = "", $sTitle = $bGetTitle ? $mInfo.Item("Title") : ""
	If $sTitle = "" Then 
		; Title is empty, get the title from user.
		$sTitle = $mInfo.Item("BaseName")	; Get the filename as suggested title.
		While $input = ""
			$input = InputBox("Must have a name", "The group must have a title.", $sTitle )
			if @error =  1 Then Return SetError(1)  ; Cancelled.
		WEnd
		$mInfo.Item("Title") = $input
	EndIf
	
	If Not $bGetURL Then $mInfo.Item("Url") = Null 
	If Not $bGetDate Then $mInfo.Item("Date") = Null 
	If Not $bGetDuration Then $mInfo.Item("Duration") = Null 
	If Not $bGetDetails Then $mInfo.Item("Details") = Null 
	If Not $bGetStudio Then $mInfo.Item("StudioID") = Null 
	If Not $bGetCover Then $mInfo.Item("ScreenShot") = Null 
	; c ("ScreenShot:" & $mInfo.Item("ScreenShot") )

	; Now the info is ready.
	Local $sQuery =  '{"query": "mutation{ groupCreate(input:{name: \"' & _JsonStringEscape( $mInfo.Item("Title") ) & '\",' & _
		($mInfo.Item("Date") = Null ? "" : 'date: \"' & $mInfo.Item("Date")  & '\",' ) & _
		($mInfo.Item("Details") = Null ? "" : 'synopsis: \"'& _JsonStringEscape( $mInfo.Item("Details") ) & '\",' ) & _
		($mInfo.Item("URL") = Null ? "" : 'urls: [\"' & $mInfo.Item("URL") & '\"],' ) & _
		($mInfo.Item("StudioID") = Null ? "" : 'studio_id:' & $mInfo.Item("StudioID") & ',' )& _
		($mInfo.Item("ScreenShot") = Null ? "" : 'front_image:\"' & $mInfo.Item("ScreenShot") & '\",' )& _
		($mInfo.Item("Duration") = 0 ? "" : 'duration: ' & $mInfo.Item("Duration") ) & _
		'}){id} }"}'
	
	; OK, now create a new group base on the above.
	Local $sResult = Query($sQuery)
	If @error Then Return SetError(1)

	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	$mInfo.Item("GroupID") = Json_ObjGet($oResult, "data.groupCreate.id")
	
	; Now update the scene
	$sQuery = '{"query":"mutation{sceneUpdate(input:{id:' & $mInfo.Item("SceneID") & ',groups:{group_id:' & $mInfo.Item("GroupID") & '}}){id}}"}'
	$sResult = Query($sQuery)
	If @error Then Return SetError(1)

	_WD_Action($sSession, 'refresh')
	Sleep(1000)
	OpenURL($stashURL & "groups/" & $mInfo.Item("GroupID") )

EndFunc


Func GetSceneInfo($nSceneNo)
	Global $mInfo
	; clear out the dictionary object
	$mInfo.RemoveAll
	
	Local $sQuery = '{"query": "{findScene(id:' & $nSceneNo & '){title,details,urls,date,paths{screenshot},files{basename,duration},studio{id,name}}}" }'
	Local $sResult = Query($sQuery)
	If @error Then Return SetError(1)

	; Got the result
	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then
		MsgBox(0, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(1)
	EndIf
	If not IsObj($oResult) Then Return SetError(2)
	Local $oData = Json_ObjGet($oResult, "data.findScene")
	If @error Then Return SetError(1)
	$mInfo.Add("SceneID", $nSceneNo)
	$mInfo.Add("Title", $oData.Item("title") )
	$mInfo.Add("Details", $oData.Item("details") )
	Local $aURL = $oData.Item("urls")
	$mInfo.Add("URL", UBound($aURL)=0 ? "": $aURL[0] )  ; Previously movie/group has only one URL, use the first one, or empty
	$mInfo.Add("Date", $oData.Item("date") )
	Local $aFiles = $oData.Item("files")
	$mInfo.Add("BaseName", UBound($aFiles) = 0 ? "" : $aFiles[0].Item("basename") )
	$mInfo.Add("Duration", UBound($aFiles) = 0 ? 0 : Floor($aFiles[0].Item("duration") ) ) ; duration in seconds.
	; Special handling with studio
	If $oData.Item("studio") = Null Then
		$mInfo.Add("StudioID", Null)
		$mInfo.Add("StudioName", Null)
	Else 	
		$mInfo.Add("StudioID", $oData.Item("studio").Item("id") )
		$mInfo.Add("StudioName", $oData.Item("studio").Item("name") )
	EndIf
	$mInfo.Add("ScreenShot", $oData.Item("paths").Item("screenshot") )

EndFunc

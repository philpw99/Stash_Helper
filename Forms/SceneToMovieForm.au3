Func Scene2Movie()
	Global $mInfo
	; First to switch to the scene tab
	SwitchToTab("scenes")
	If @error Then Return SetError(1)
	$sURL = _WD_Action($sSession, "url")
	$nScene = GetNumber($sURL, "scenes")
	If @error Then Return SetError(1)
	; Get Scene info will set the global $mInfo
	GetSceneInfo($nScene)
	If @error Then Return SetError(1)

	; Now show a GUI and ask which info to copy over.
	Global $guiScene2Movie = GUICreate("Copy Scene Info To Movie",766,910,-1,-1,$WS_SIZEBOX,-1)
	GUICtrlCreateLabel("Please choose the information you like to transfer to the movie.",80,19,698,80,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlSetResizing(-1,550)
	$lvValues = GUICtrlCreatelistview("#|Properties|Value",32,110,703,282,$LVS_SINGLESEL,BitOr($LVS_EX_FULLROWSELECT,$LVS_EX_CHECKBOXES,$WS_EX_STATICEDGE))
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
	$btnOK = GUICtrlCreateButton("OK",548,448,184,54,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)
	
	$btnCancel = GUICtrlCreateButton("Cancel",548,516,184,54,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,804)
	
	$btnBatchCreate = GUICtrlCreateButton("Create movies for all other scenes",241,789,489,51,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Create movies for all other scenes which have no movies yet. Following the checked items here.")
	GUICtrlSetResizing(-1,836)
	
	; Download the image to temp folder.
	$sExt = StringMid($mInfo.Item("ScreenShot"), stringinstr($mInfo.Item("ScreenShot"), ".", 2, -1))
	$sTempPicFile = @TempDir & "\temp" & $sExt
	InetGet($mInfo.Item("ScreenShot"), $sTempPicFile)
	$imgCover = GUICtrlCreatePic($sTempPicFile,29,448,455,314,-1,$WS_EX_STATICEDGE)
	GUICtrlSetResizing(-1,102)
	
	$chkCover = GUICtrlCreateCheckbox("Cover",39,405,150,33,-1,-1)
	GUICtrlSetState($chkCover, $GUI_CHECKED)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetResizing(-1,802)
	
	; Disable the tray clicks
	TraySetClick(0)

	GUISetState(@SW_SHOW, $guiScene2Movie)
	While True 
		; if click on tray icon, activate the current GUI
		$nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiScene2Movie)
 		EndSwitch 

		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnOK
				CreateSingleMovie($lvValues, $chkCover)
				ExitLoop
			Case $btnBatchCreate
				; Need code here
				BatchCreate($lvValues, $chkCover)
				ExitLoop
			Case $GUI_EVENT_RESIZED
				GUICtrlSetImage($imgCover, $sTempPicFile)
			Case $GUI_EVENT_CLOSE, $btnCancel
				ExitLoop 
		EndSwitch
	Wend
	GUIDelete($guiScene2Movie)
	; restore the tray icon functions.
	TraySetClick(9)
EndFunc

Func BatchCreate($lvValues, $chkCover)
	Global $mInfo
	
	$reply = MsgBox(262449,"Warning.","This function will create one movie for every scene that's not linked to a movie yet." _ 
		& @CRLF & "Also it will follow the check boxes here to only retrieve the information you specified." _
		& @CRLF & "However, it might create a lot of movies in the process. The problem is more serious when you have multiple scenes meant for the same movie." _
		& @CRLF & "So are you sure you want to continue?",0)
	If $reply = 2 Then Return 
	
	$bGetTitle = _GUICtrlListView_GetItemChecked($lvValues, 0)
	$bGetUrl = _GUICtrlListView_GetItemChecked($lvValues, 1)
	$bGetDate = _GUICtrlListView_GetItemChecked($lvValues, 2)
	$bGetDuration = _GUICtrlListView_GetItemChecked($lvValues, 3)
	$bGetDetails = _GUICtrlListView_GetItemChecked($lvValues, 4)
	$bGetStudio = _GUICtrlListView_GetItemChecked($lvValues, 5)
	$bGetCover = (GUICtrlRead($chkCover) = $GUI_CHECKED )
	
	If Not $bGetTitle Then
		; Title was not check, exit
		MsgBox(48,"Must have title checked.","The check box next to 'Title' must be checked, because in this batch mode, title is mandatory.",0)
		Return
	EndIf
	
	; Now get the list of all scenes without a movie
	$sQuery = '{ "query": "{findScenes(scene_filter:{is_missing: \"movie\"}filter:{per_page:-1}){count,scenes{id}}}" }'
	$sResult = Query($sQuery)
	If @error or QueryResultError($sResult) Then 
		MsgBox(0, "Oops!", "The query to ask scenes without movie failed. Result:" & $sResult)
		Return SetError(1)
	EndIf
	$oResult = Json_Decode($sResult)
	$oData = Json_ObjGet($oResult, "data.findScenes")
	$iCount = $oData.Item("count")

	If $iCount = "" Or $iCount = 0 Then
		MsgBox(0, "No scenes", "There is no scenes to create movies.")
		Return
	EndIf
	$aScenes = Json_ObjGet($oData, "scenes")
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
	
	; Batch create movies
	
	; Set mouse cursor to wait.
	$old_cursor = MouseGetCursor()
	GUISetCursor(15, 1, $guiScene2Movie)

	$iMovieCreated = 0
	For $i = 0 to $iCount-1
		; Set the scene info in $mInfo
		GetSceneInfo($aIDs[$i])
		If Not $bGetURL Then $mInfo.Item("Url") = Null 
		If Not $bGetDate Then $mInfo.Item("Date") = Null 
		If Not $bGetDuration Then $mInfo.Item("Duration") = Null 
		If Not $bGetDetails Then $mInfo.Item("Details") = Null 
		If Not $bGetStudio Then $mInfo.Item("Studio") = Null 
		If Not $bGetCover Then $mInfo.Item("ScreenShot") = Null
		; Now the info is ready.
		$sQuery =  '{"query": "mutation{ movieCreate(input:{name: \"' & $mInfo.Item("Title") & '\",' & _
			($mInfo.Item("Date") = Null ? "" : 'date: \"' & $mInfo.Item("Date") & '\",' ) & _
			($mInfo.Item("Details") = Null ? "" : 'synopsis: \"'& $mInfo.Item("Details") & '\",' ) & _
			($mInfo.Item("URL") = Null ? "" : 'url: \"' & $mInfo.Item("URL") & '\",' ) & _
			($mInfo.Item("StudioName") = Null ? "" : 'studio_id:' & $mInfo.Item("StudioID") & ',' )& _
			($mInfo.Item("ScreenShot") = Null ? "" : 'front_image:\"' & $mInfo.Item("ScreenShot") & '\",' )& _
			($mInfo.Item("Duration") = 0 ? "" : 'duration: ' & $mInfo.Item("Duration") ) & _
			'}){id} }"}'
		
		; OK, now create a new movie base on the above.
		$sResult = Query($sQuery)
		If @error or QueryResultError($sResult) Then 
			; c( "query result:" & $sResult)
			MsgBox(0, "Create movie error.", "Couldn't create the movie:" & $mInfo.Item("Title") _ 
				& " for some reason. here is the result: " & $sResult)
			ExitLoop 
		EndIf
		
		$oResult = Json_Decode($sResult)
		$mInfo.Item("MovieID") = Json_ObjGet($oResult, "data.movieCreate.id")
		; c ( "ID:" & $sMovieID)
		
		; Now update the scene
		$sQuery = '{"query":"mutation{sceneUpdate(input:{id:' & $mInfo.Item("SceneID") & ',movies:{movie_id:' _ 
			& $mInfo.Item("MovieID") & '}}){id}}"}'
		$sResult = Query($sQuery)
		If @error or QueryResultError($sResult) Then 
			; c( "query result:" & $sResult)
			MsgBox(0, "Set movie error.", "Couldn't set the movie:" & $mInfo.Item("Title") _ 
				& " for that scene. here is the result: " & $sResult)
			ExitLoop 
		EndIf
		$iMovieCreated += 1
	Next
	
	; Set cursor back.
	GUISetCursor($old_cursor, 1, $guiScene2Movie)

	_WD_Action($sSession, 'refresh')
	MsgBox(0, "Job Done", "Total movie created: " & $iMovieCreated)
	
EndFunc


Func CreateSingleMovie($lvValues, $chkCover)
	Global $mInfo
	$bGetTitle = _GUICtrlListView_GetItemChecked($lvValues, 0)
	$bGetUrl = _GUICtrlListView_GetItemChecked($lvValues, 1)
	$bGetDate = _GUICtrlListView_GetItemChecked($lvValues, 2)
	$bGetDuration = _GUICtrlListView_GetItemChecked($lvValues, 3)
	$bGetDetails = _GUICtrlListView_GetItemChecked($lvValues, 4)
	$bGetStudio = _GUICtrlListView_GetItemChecked($lvValues, 5)
	ConsoleWrite("check state:" & GUICtrlGetState($chkCover))
	$bGetCover = ( GUICtrlRead($chkCover) = $GUI_CHECKED )
	c("get cover?" & $bGetCover)
	Local $input = ""

	If Not $bGetTitle Then 
		; Title was not checked, get the title from user.
		While $input = ""
			$input = InputBox("Must have a name", "The movie must have a title.", $mInfo.Item("Title") )
		WEnd
		$mInfo.Item("Title") = $input
	EndIf
	
	If Not $bGetURL Then $mInfo.Item("Url") = Null 
	If Not $bGetDate Then $mInfo.Item("Date") = Null 
	If Not $bGetDuration Then $mInfo.Item("Duration") = Null 
	If Not $bGetDetails Then $mInfo.Item("Details") = Null 
	If Not $bGetStudio Then $mInfo.Item("Studio") = Null 
	If Not $bGetCover Then $mInfo.Item("ScreenShot") = Null 
	c ("ScreenShot:" & $mInfo.Item("ScreenShot") )

	; Now the info is ready.
	$sQuery =  '{"query": "mutation{ movieCreate(input:{name: \"' & $mInfo.Item("Title") & '\",' & _
		($mInfo.Item("Date") = Null ? "" : 'date: \"' & $mInfo.Item("Date") & '\",' ) & _
		($mInfo.Item("Details") = Null ? "" : 'synopsis: \"'& $mInfo.Item("Details") & '\",' ) & _
		($mInfo.Item("URL") = Null ? "" : 'url: \"' & $mInfo.Item("URL") & '\",' ) & _
		($mInfo.Item("StudioName") = Null ? "" : 'studio_id:' & $mInfo.Item("StudioID") & ',' )& _
		($mInfo.Item("ScreenShot") = Null ? "" : 'front_image:\"' & $mInfo.Item("ScreenShot") & '\",' )& _
		($mInfo.Item("Duration") = 0 ? "" : 'duration: ' & $mInfo.Item("Duration") ) & _
		'}){id} }"}'
	
	c( "create movie query:" & $sQuery)
	; OK, now create a new movie base on the above.
	$sResult = Query($sQuery)
	If @error or QueryResultError($sResult) Then 
		; c( "query result:" & $sResult)
		MsgBox(0, "Create movie error.", "Couldn't create the movie for some reason. here is the result: " & $sResult)
		Return SetError(1)
	EndIf
	$oResult = Json_Decode($sResult)
	$mInfo.Item("MovieID") = Json_ObjGet($oResult, "data.movieCreate.id")
	; c ( "ID:" & $sMovieID)
	
	; Now update the scene
	$sQuery = '{"query":"mutation{sceneUpdate(input:{id:' & $mInfo.Item("SceneID") & ',movies:{movie_id:' & $mInfo.Item("MovieID") & '}}){id}}"}'
	$sResult = Query($sQuery)
	If @error or QueryResultError($sResult) Then 
		; c( "query result:" & $sResult)
		MsgBox(0, "Set movie error.", "Couldn't set the movie for that scene. here is the result: " & $sResult)
		Return SetError(1)
	EndIf
	_WD_Action($sSession, 'refresh')
	Sleep(1000)
	OpenURL($stashURL & "movies/" & $mInfo.Item("MovieID") )
	Sleep(2000)
	Alert("Movie created.")
	
EndFunc


Func GetSceneInfo($nSceneNo)
	Global $mInfo
	; clear out the dictionary object
	$mInfo.RemoveAll
	
	$sQuery = '{"query": "{findScene(id:' & $nSceneNo & '){title,details,url,date,paths{screenshot},file{duration},studio{name}}}" }'
	$sResult = Query($sQuery)
	If @error Or QueryResultError($sResult) Then
		MsgBox(0, "Scene query error.", "Couldn't query the scene for some reason. here is the result: " & $sResult)
		Return SetError(1)
	EndIf
	; Got the result
	$oResult = Json_Decode($sResult)
	If not IsObj($oResult) Then Return SetError(1)
	$oData = Json_ObjGet($oResult, "data.findScene")
	If @error Then Return SetError(1)
	$mInfo.Add("SceneID", $nSceneNo)
	$mInfo.Add("Title", $oData.Item("title") )
	$mInfo.Add("Details", $oData.Item("details") )
	$mInfo.Add("URL", $oData.Item("url") )
	$mInfo.Add("Date", $oData.Item("date") )
	$mInfo.Add("Duration", Floor( $oData.Item("file").Item("duration") ) ) ; duration in seconds.
	$mInfo.Add("StudioName", $oData.Item("studio").Item("name") )
	$mInfo.Add("ScreenShot", $oData.Item("paths").Item("screenshot") )

	If @error Then
		c("Add studioname error.")
		Return SetError(1)
	EndIf
		

	c("studio name:" & $mInfo.Item("StudioName") & " is null?" & ($mInfo.Item("StudioName") = Null) )

	$mInfo.Add("StudioID", "" )
	If $mInfo.Item("StudioName") <> Null Then 
		; Search the studio id by name
		$sQuery = '{"query": "{findStudios(studio_filter:{name: {value: \"' & $mInfo.Item("StudioName") & '\",modifier: EQUALS}}){count,studios{id}}}" }'
		$sResult = Query($sQuery)
		If @error Or QueryResultError($sResult) Then
			MsgBox(0, "Studio inquery error.", "Couldn't find the studio for some reason. here is the result: " & $sResult)
			Return SetError(1)
		EndIf
		$oResult = Json_Decode($sResult)
		$iCount = json_ObjGet($oResult, "data.findStudios.count")
		c("Found studio:" & $iCount)
		If  $iCount <> 0 Then
			$aStudios = Json_ObjGet($oResult, "data.findStudios.studios")
			$mInfo.Item("StudioID") = $aStudios[0].Item("id")
		Else 
			; Set the name to empty, to avoid error later.
			$mInfo.Item("StudioName") = Null 
		EndIf
	Else 
		$mInfo.Item("StudioID") = Null
	EndIf
EndFunc

Func MergePerformers()
	Global $guiMergePerformers = GUICreate("Merge 2 Performers",820,590,-1,-1,-1,-1)
	Local $inpP1 = GUICtrlCreateInput("",329,40,306,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlCreateLabel("Merge All Performer 1 :",20,40,306,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlCreateLabel("Scenes",651,45,123,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	Local $inpP2 = GUICtrlCreateInput("",329,100,306,36,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlCreateLabel("Into Performer 2 :",85,100,233,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlCreateLabel("Scenes",651,100,113,36,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	GUICtrlCreateLabel("And Make Performer 1 An Alias of Performer 2",130,150,600,41,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	Global $lstPerformers = GUICtrlCreatelist("",329,203,306,278,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlCreateLabel("Performers List"&@crlf&""&@crlf&"(type something"&@crlf&"above to show"&@crlf&"the list)",166,210,152,97,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	Local $btnOK = GUICtrlCreateButton("OK",176,504,196,52,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	Local $btnCancel = GUICtrlCreateButton("Cancel",476,504,196,52,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	
	; Disable the tray clicks
	TraySetClick(0)
	
	Local $sOldP1, $sOldP2
	Global $giCurrentInput
	
	GUISetState(@SW_SHOW, $guiMergePerformers)
	While True 
		; if click on tray icon, activate the current GUI
		Local $nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiMergePerformers)
 		EndSwitch 

		Local $sP1 = GUICtrlRead($inpP1)
		Local $sP2 = GUICtrlRead($inpP2)
		
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $inpP1, $inpP2

			Case $lstPerformers
				If $giCurrentInput = 1 Then
					$sP1 = GUICtrlRead($lstPerformers)
					GUICtrlSetData( $inpP1, $sP1 )
					$sOldP1 = $sP1
					GUICtrlSetState( $inpP2, $GUI_FOCUS)
					$giCurrentInput = 2
				ElseIf $giCurrentInput = 2 Then 
					$sP2 = GUICtrlRead($lstPerformers)
					GUICtrlSetData( $inpP2, $sP2 )
					$sOldP2 = $sP2
					GUICtrlSetState( $inpP1, $GUI_FOCUS)
					$giCurrentInput = 1
				EndIf
			Case $btnOK
				$msgConfirm = MsgBox(262433,"Sure to merge 2 performers?","Are you sure to merge " _ 
					& $sP1 & " into " & $sP2 & " ? Once it happens," & @CRLF _ 
					& "1. " & $sP1 & "'s info will be copied to " & $sP2 & " if that data is missing in " & $sP2 _
					& @CRLF & "2. All " & $sP1 & "'s scenes will be linked to " & $sP2 & @CRLF _ 
					& "3. " & $sP1 & " will be added as an alias to " & $sP2 & ".", 0 , $guiMergePerformers)
				if $msgConfirm <> 1 Then ContinueLoop ; Cancel or close
			
				; OK
				If $sP1 = $sP2 Then 
					MsgBox(0, "Cannot merge the same one.", "Cannot merge the same performer")
					ContinueLoop 
				EndIf
				
				Local $sID1 = GetPerformerID($sP1)
				If @error Then 
					c("query id1 error: " & @error )
					If @error = 3 Then 
						MsgBox( 0, "Performer name not unique", "This performer name: " _ 
							& $sP1 & " is not unique in the database." & @CRLF _
							& "Cannot do the merge like this.")
					Else 
						MsgBox( 0, "Error in query", "Error in the query for performer " & $sP1 & "'s ID.")
					EndIf
					ContinueLoop 
				EndIf
				
				Local $sID2 = GetPerformerID($sP2)
				If @error Then 
					c("query id2 error: " & @error )
					If @error = 3 Then 
						MsgBox( 0, "Performer name not unique", "This performer name: " _ 
							& $sP2 & " is not unique in the database." & @CRLF _
							& "Cannot do the merge like this.")
					Else 
						MsgBox( 0, "Error in query", "Error in the query for performer " & $sP2 & "'s ID.")
					EndIf
					ContinueLoop 
				EndIf
				
				; Now all is ready
				
				; Copy data from P1 to P2
				CopyPerformerData( $sID1, $sID2)
				
				; Get the list of all scenes of P1
				Local $sP1SceneList = GetPerformerScenes($sID1)
				If @error Then 
					c( "Error getting performer1's scene ids. Error: " & @error)
				EndIf
				If $sP1SceneList <> "" Then 
					; some ids returned.
					SetPerformerScenes( $sID1, $sID2, $sP1SceneList )
				EndIf

				
				MsgBox(64,"Transfer Done","Now info from " & $sP1 & " is transfered to " & $sP2 & "," _ 
					& @CRLF & $sP1 & " is now an alias of " & $sP2 & @CRLF _ 
					& "and all the " & $sP1 & "'s scenes and movies are updated and added " & $sP2 & " to them as well." & @CRLF _ 
					& "Right now " & $sP1 & " is unchanged, but you can delete it to make it final.", 0)

				ExitLoop
				
			Case $GUI_EVENT_CLOSE, $btnCancel
				ExitLoop
		EndSwitch
		; check InputP1 and InputP2
		If $sOldP1 <> $sP1 And stringlen($sP1) > 3 Then 
			$sOldP1 = $sP1
			$giCurrentInput = 1
			; fetch the performer list
			ShowPerformerList($sP1)
		ElseIf $sOldP2 <> $sP2 And stringlen($sP2) > 3 Then 
			$sOldP2 = $sP2
			$giCurrentInput = 2
			; fetch the performer list
			ShowPerformerList($sP2)
		EndIf
		
		Sleep(50)
	Wend
	; Enable the tray clicks.
	TraySetClick(9)
	
	GUIDelete( $guiMergePerformers )
EndFunc 

Func CopyPerformerData($sOldID, $sNewID)
	; Copy all the data from old id to new id, if the new id field is empty.
	Local $sQuery = PerformerInfoQuery($sOldID)
	
	Local $sResult = Query2($sQuery)
	If @error Then 
		c ( 'Error getting old id data. Error:' & @error )
		Return SetError(1)
	EndIf
	
	Local $oResult = Json_Decode( $sResult )
	If Not IsObj($oResult) Then Return SetError(2)
	Local $oPerfOld = json_get($oResult, ".data.findPerformer" )
	If Not IsObj($oPerfOld) Then Return SetError(3)
	
	$sQuery = PerformerInfoQuery($sNewID)
	Local $sResult = Query2($sQuery)
	If @error Then 
		c ( 'Error getting new id data. Error:' & @error )
		Return SetError(4)
	EndIf

	Local $oResult = Json_Decode( $sResult )
	If Not IsObj($oResult) Then Return SetError(5)
	Local $oPerfNew = json_get($oResult, ".data.findPerformer" )
	If Not IsObj($oPerfNew) Then Return SetError(6)
	
	; Go through all the items.
	For $key in $oPerfOld
		Local $item = $oPerfOld.Item($key)
		; Skip the unnecessary fields.
		if $Key = "id" Or $item = Null Then ContinueLoop 
				
		Switch VarGetType( $item )
			Case "String"
				If ( Not IsEmpty($item)) And IsEmpty( $oPerfNew.Item($key) ) Then 
					$oPerfNew.Item($key) = $item
				EndIf
				
			Case "Int32"
				if $oPerfNew.Item($key) = Null  Then 
					$oPerfNew.Item($key) = $item
				EndIf

			Case "Array"
				; Merge 2 arrays
				Local $aNewItem = $oPerfNew.Item($key), $aNewArray
				If UBound($aNewItem) = 0 Then 
					$aNewArray = $item
				Else 
					_ArrayConcatenate( $item, $aNewItem )
					$aNewArray = _ArrayUnique( $item, 0,0,0,0 )	; Remove duplicates
				EndIf
				$oPerfNew.Item($key) = $aNewArray

			Case Else
				If Not IsEmpty($item) And IsEmpty( $oPerfNew.Item($key)) Then 
					$oPerfNew.Item($key) = $item
				EndIf
		EndSwitch
	Next
	
	; Special handling of image_path here
	; Get P1 image
	Local $sP1_Img = $oPerfOld.Item("image_path")

	InetGet( $sP1_Img, @TempDir & "\p1.png")
	Local $sP2_Img = $oPerfNew.Item("image_path")
	InetGet( $sP2_Img, @TempDir & "\p2.png")
	; Use GDP Plus to get the dimensions
	_GDIPlus_Startup()
	Local $bImg1IsOK = True , $bImg2IsOK = True 
	
	Local $hImg1 = _GDIPlus_ImageLoadFromFile( @TempDir & "\p1.png")
	If _GDIPlus_ImageGetWidth($hImg1) = 850 And _GDIPlus_ImageGetHeight($hImg1) = 1250 Then $bImg1IsOK = False 

	Local $hImg2 = _GDIPlus_ImageLoadFromFile( @TempDir & "\p2.png" )
	If _GDIPlus_ImageGetWidth($hImg2) = 850 And _GDIPlus_ImageGetHeight($hImg2) = 1250 Then $bImg2IsOK = False 

	_GDIPlus_ImageDispose($hImg1)
	_GDIPlus_ImageDispose($hImg2)
	_GDIPlus_Shutdown()
	
	c( "P1 OK:" & $bImg1IsOK & " P2 OK:" & $bImg2IsOK )
	If $bImg1IsOK And (Not $bImg2IsOK) Then 
		$oPerfNew.Item("image") = $sP1_Img
	EndIf
		
	; Add the alias
	$oPerfNew.Item( "aliases" ) = AddToList( $oPerfNew.Item("aliases"), $oPerfOld.Item("name"), ", " )
	; Now convert it to string
	$sQuery = SetPerfUpdateQuery( $oPerfNew )
	; Force convert it to UTF8 binary
	; $sQueryUTF8 = StringToBinary( $sQuery, $SB_UTF8)
	$sResult = QueryMutation( $sQuery )
	If @error Then 
		c("error in performer update. Error:" & @error)
		Return SetError(7)
	EndIf
	
EndFunc

Func SetPerfUpdateQuery( ByRef $obj)
	Local $sQuery = '{performerUpdate(input:{id:' & Q2($obj.Item("id")) & ', name:' & Q2($obj.Item("name"))
	$sQuery &= IsEmpty($obj.Item("aliases"))? "": ', aliases:' & Q2($obj.Item("aliases"))
	$sQuery &= IsEmpty($obj.Item("gender"))? "": ', gender:' & $obj.Item("gender") 
	$sQuery &= IsEmpty($obj.Item("url")) ? "" : ', url:' & Q2( $obj.Item("url") ) 
	$sQuery &= IsEmpty($obj.Item("twitter")) ? "" : ', twitter:' & Q2( $obj.Item("twitter"))
	$sQuery &= IsEmpty($obj.Item("instagram")) ? "" : ', instagram:' & Q2( $obj.Item("instagram") )
	$sQuery &= IsEmpty($obj.Item("birthdate")) ? "" : ', birthdate:' & Q2( $obj.Item("birthdate") )
	$sQuery &= IsEmpty($obj.Item("ethnicity")) ? "" : ', ethnicity:' & Q2( $obj.Item("ethnicity") )
	$sQuery &= IsEmpty($obj.Item("country")) ? "" : ', country:' & Q2( $obj.Item("country") )
	$sQuery &= IsEmpty($obj.Item("eye_color")) ? "" : ', eye_color:' & Q2( $obj.Item("eye_color") )
	$sQuery &= IsEmpty($obj.Item("height")) ? "" : ', height:' & Q2( $obj.Item("height") )
	$sQuery &= IsEmpty($obj.Item("measurements")) ? "" : ', measurements:' & Q2( $obj.Item("measurements") )
	$sQuery &= IsEmpty($obj.Item("fake_tits")) ? "" : ', fake_tits:' & Q2( $obj.Item("fake_tits") )
	$sQuery &= IsEmpty($obj.Item("career_length")) ? "" : ', career_length:' & Q2( $obj.Item("career_length") )
	$sQuery &= IsEmpty($obj.Item("tattoos")) ? "" : ', tattoos:' & Q2( $obj.Item("tattoos") )
	$sQuery &= IsEmpty($obj.Item("piercings")) ? "" : ', piercings:' & Q2( $obj.Item("piercings") )
	$sQuery &= IsEmpty($obj.Item("stash_ids")) ? "" : ', stash_ids:' & Array2JsonStr($obj.Item("stash_ids"), "stash_id")
	$sQuery &= IsEmpty($obj.Item("tags")) ? "" : ', tags:' & Array2JsonStr( $obj.Item("tags"),"name" )
	$sQuery &= IsEmpty($obj.Item("rating")) ? "" : ', rating:' & $obj.Item("rating")
	$sQuery &= IsEmpty($obj.Item("death_date")) ? "" : ', death_date:' & Q2( $obj.Item("death_date") )
	$sQuery &= IsEmpty($obj.Item("hair_color")) ? "" : ', hair_color:' & Q2( $obj.Item("hair_color") )
	$sQuery &= IsEmpty($obj.Item("image")) ? "" : ', image:' & Q2( $obj.Item("image") )
	$sQuery &= '}){name}}'
	; c( "sQuery:" & $sQuery)
	Return $sQuery
EndFunc

Func Array2JsonStr($aArray, $sKey)
	; return something like [{key:\"1\"},{key\"2\"},\"3\"]
	If UBound($aArray) = 0 Then Return "[]"
	$sOut = "["
	For $str in $aArray
		Local $sItem = '{' & $sKey & ':' & Q2($str) & '}'
		$sOut &= ( $sOut = "[" ? $sItem : "," & $sItem )
	Next
	$sOut &= "]"
	Return $sOut
EndFunc

Func PerformerInfoQuery($sID)
	Return '{findPerformer(id:\"' & $sID & '\"){id,name,aliases,gender,url,twitter,instagram,birthdate,ethnicity,' _
	    & 'country,eye_color,height,measurements,fake_tits,career_length,tattoos,piercings,' _
		 &  'image_path,stash_ids{stash_id},tags{name},rating,death_date,hair_color,weight}}'
EndFunc


Func SetPerformerScenes( $sOldID, $sNewID, $sSceneList)
	; set the performer new id to each scene by scene id
	Local $aList = StringSplit( $sSceneList, "|"  )
	For $i = 1 to $aList[0]
		Local $sQuery = '{findScene(id:\"' & $aList[$i] & '\"){performers{id}}}'
		Local $sResult = Query2($sQuery)
		If @error Then
			c ( "Error getting performer info in scene id:" & $aList[$i] )
			Return SetError(1)
		EndIf

		$oResult = Json_Decode($sResult)
		If @error or not IsObj($oResult) Then 
			c( "error decoding, line :" & @ScriptLineNumber )
			return SetError(2)
		EndIf
		$aIDs = Json_Get($oResult, ".data.findScene.performers")
		If @error Or Not IsArray($aIDs) Then 
			c( "error in getting ids, Line :" & @ScriptLineNumber)
			Return SetError(3)
		EndIf
		; Set the array like [\"570\", \"306\"]
		$sArray = "["
		For $oID in $aIDs
			$sArray &= ( $sArray = "[" ? Q2($oID.Item("id")) : ", " & Q2($oID.Item("id"))  )
		Next
		$sArray &= ", " & Q2($sNewID) & "]"	; Add the new id to the scene
		
		Local $sUpdateQuery = '{sceneUpdate(input: {id: ' & Q2($aList[$i]) & ', performer_ids:' & $sArray & '}){title}}'
		$sResult = QueryMutation($sUpdateQuery)
		; c( "Updated scene:" & $aList[$i] )
	Next
EndFunc

Func GetPerformerScenes($sID)
	; In: $sID the ID of the performer
	; Out: array of scenes id the performer is in.
	
	Local $sQuery = '{findScenes(scene_filter:{performers:{value: \"' & $sID & '\", modifier: INCLUDES}}){scenes{id}}}'
	Local $sResult = Query2($sQuery)
	If @error Then Return SetError(1)
	
	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then Return SetError(2)
	
	Local $aScenes = Json_Get($oResult, ".data.findScenes.scenes")
	If Not IsArray($aScenes) Then Return SetError(3)
	
	Local $sList = ""
	For $oScene In $aScenes
		$sList = AddToList( $sList, $oScene.Item("id") )
	Next
	
	Return $sList
EndFunc

Func GetPerformerID($sName)
	; get the id for the name. If more than one match then return error
	Local $sQuery = '{findPerformers(performer_filter:{name:{value: \"' & $sName & '\", modifier: EQUALS}}){count,performers{id}}}'
	Local $sResult = Query2($sQuery)
	If @error Then Return SetError(1)
	
	Local $oResult = Json_Decode($sResult)
	If Not IsObj($oResult) Then Return SetError(2)
	
	Local $iCount = Json_Get($oResult, ".data.findPerformers.count")
	If $iCount <> 1 Then Return SetError(3)
	
	Local $aPerformers = Json_Get( $oResult, ".data.findPerformers.performers")
	If not IsArray( $aPerformers) Then Return SetError(4)
	
	Return $aPerformers[0].Item("id")
EndFunc 


Func ShowPerformerList($sFilter)
	; Global $lstPerformers
	Local $sResult = Query2( PerformerListQuery($sFilter) )
	If @error Then 
		c("Query for performer 1 error.")
		Return SetError(1)
	EndIf
	
	; now set the result to the list
	Local $oResult = Json_Decode( $sResult )
	If Not IsObj($oResult) Then
		c("result not object.")
		return SetError(2)
	EndIf
		
	Local $aPerformers = Json_get($oResult, ".data.findPerformers.performers")
	If Not IsArray($aPerformers) Then 
		c("aPerformers not array.")
		Return SetError(3)
	EndIf

	Local $sList = ""
	For $oPerformer in $aPerformers
		; c( "type: " & $oP )
		$sList = AddToList( $sList, $oPerformer.Item("name") )
	Next
	; c("List: " & $sList )
	_GUICtrlListBox_ResetContent($lstPerformers)
	GUICtrlSetData( $lstPerformers, $sList )
	
EndFunc

Func PerformerListQuery($sName)
	Return '{findPerformers(performer_filter:{name:{value: \"' & $sName & '\", modifier: INCLUDES}}){performers{name}}}'
EndFunc
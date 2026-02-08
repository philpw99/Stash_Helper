#cs
	AutoHandleJAV.au3
 This is used in the pop up menu "Auto Handle JAV"
 It will do a few things in batch:
 1. Gather all the scenes in the current browser
 2. Assume they are all JAV scenes, and start getting info from R18 scraper.
 3. If the scene doesn't have a group(movie), create the group and copy the info to the group.
 
#ce

Func AutoHandleJAV()
	; Check to see if R18 is installed.
	Local $sResult = Query2("{listScrapers(types:SCENE){id}}")
	if @error Then Return SetError(1)
	If StringInStr($sResult, '"id":"R18.dev"') = 0 Then 
		MsgBox(0, "R18 scraper not installed", "In order to run this you need to install R18 scraper and set the Scraper Agent first.")
		Return SetError(2)
	EndIf

	Local $sURL = GetURL()
	If @error Then Return SetError(1)

	Local $sCategory = GetCategory($sURL)
	if @error Then Return SetError(2)

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

	; Get the full list of ids.
	$sQuery = URLtoQuery($sURL, "id")
	if @error then Return SetError(3)

	If StringLeft($sQuery, 3) = "id=" Then
		; No need to get query. Has one single id.
		Local $sID = PairValue($sQuery), $iNo
		Switch $sCategory
			Case "scenes"
				; scrape this scene
				$iGroupCount = ScrapeJAVScene($sID)
				MsgBox(262208, "Done", "Totally 1 scene was processed." & @CRLF _
					& "And " & $iGroupCount & " group was created", 10)
				_WD_Action($sSession, 'refresh')
				Return
			Case Else 
				MsgBox(262192, "Not support", "This is for scene or scenes only.")
				Return SetError(4)
		EndSwitch
		Return
	EndIf
	
	; Batch processing
	$sResult = Query2($sQuery)
	if @error Then Return SetError(1)
	Local $oData = Json_Decode($sResult)
	If Not IsObj($oData) Then
		MsgBox(262192, "Error decoding result", "Error getting result:" & $sResult)
		Return SetError(5)
	EndIf

	If $sCategory <> "scenes" Then 
		MsgBox(262192, "Not support", "This is for scene or scenes only.")
		Return SetError(4)
	EndIf
	
	Local $aScenes = Json_ObjGet($oData, "data.findScenes.scenes")
	If UBound($aScenes) = 0 Then
		MsgBox(262192, "strange", "Weird, program error. There is nothing to add to the list.")
		Return SetError(6)
	EndIf

	Local $i = 0, $iGroupCount = 0
	For $oScene in $aScenes
		$iGroupCount += ScrapeJAVScene($oScene.item("id"))
		if @error Then
			c("Error processing scene id:" & $oScene.item("id"))
		Else 
			$i += 1
		EndIf
		c( "Slow down for 1 second.")
		Sleep(1000) ; Slow down the requests.
	Next
	MsgBox(262208, "Done", "Totally "& $i & " scenes were processed." & @CRLF _
		& "And " & $iGroupCount & " movies were created", 10)
	_WD_Action($sSession, 'refresh')
EndFunc

Func ScrapeJAVScene($SceneID)
	; Get the product id from scene file name.
	; Return the number of movie auto created. Usually either 0 or 1.
	$iGroupCreated = 0
	$sQuery = "{findScene(id:" & $SceneID & "){files{basename}}}"
	$sResult = Query2($sQuery)
	if @error Then  Return SetError(1)
	$oData = Json_Decode($sResult)
	$aFiles = Json_ObjGet( $oData, "data.findScene.files")
	$sBaseName = $aFiles[0].item("basename")
	; c( "Scene " & $SceneID & " Got basename:" & $sBaseName)
	If StringInStr($sBaseName, "@") <> 0 Then
		; Patch for filenames like "4k2.com@KAVR00123.MP4"
		$sBaseName = StringMid($sBaseName, StringInStr($sBaseName, "@") + 1)
	EndIf
	
	; Use global array $gaJAVStudioData
	Local $aStr[2]
	If UBound($gaJAVStudioData) <> 0 Then 
		For $i = 0 to UBound($gaJAVStudioData) -1
			If StringInStr($sBaseName, $gaJAVStudioData[$i][0]) <> 0 Then 
				$aStr = StringRegExp($sBaseName, '.*?((?i)' & $gaJAVStudioData[$i][0] & ')-?(\d+)[zZ]?[eE]?(?:-pt)?(\d{1,2})?.*', $STR_REGEXPARRAYMATCH )
				$aStr[0] = $gaJAVStudioData[$i][1]
				ExitLoop 
			EndIf
		Next
		if $aStr[0] = "" Then 
			; No match, use default 
			$aStr = StringRegExp($sBaseName, '.*?([a-zA-Z|tT28]+)-?(\d+)[zZ]?[eE]?(?:-pt)?(\d{1,2})?.*', $STR_REGEXPARRAYMATCH )
		EndIf
	EndIf
	
	If UBound($aStr) < 2 or $aStr[0] = "" or $aStr[1] = "" Then
		c( "Scene " & $SceneID & " basename: " & $sBaseName & " is not a JAV file.")
		Return SetError(2)
	EndIf

	Local $sProductID = StringLower($aStr[0]) & StringLeft("00000", 5-StringLen($aStr[1])) & $aStr[1]
	Local $sGroupName = $aStr[0] & "-" & $aStr[1]
	Local $sScrapeURL = "https://r18.dev/videos/vod/movies/detail/-/id=" & $sProductID
	; c("Product ID:" & $sProductID)

	$sQuery = '{scrapeSceneURL(url:' & QueryQ($sScrapeURL) _
		& '){title,details,director,date,studio{name},tags{name},performers{name}}}'
	$sResult = Query2($sQuery)
	if @error Then
		c("Error scraping product id:" & $sProductID & " result:" & $sResult)
		Return SetError(3)
	EndIf
	$oData = Json_Decode($sResult)
	$oSceneData = Json_ObjGet($oData, "data.scrapeSceneURL")
	
	; Check studio. If none then create one with name
	$sStudio = $oSceneData.item("studio").item("name")
	$sStudioID = ""
	if $sStudio Then
		$sQuery = "{findStudios(studio_filter:{name:{value:" & QueryQ($sStudio) & ",modifier: EQUALS}}){count,studios{id}}}"
		$sResult = Query2($sQuery)
		if StringInStr($sResult, '"count":0') <> 0 Then 
			; No such a studio yet, create one.
			$sQuery = "mutation{studioCreate(input:{name:" & QueryQ($sStudio) & "}){id}}"
			$sResult = QueryMutation($sQuery)
			if @error Then
				c("Error create studio:" & $sStudio & " result:" & $sResult)
				Return SetError(4)
			EndIf
		EndIf 
		$sStudioID =  GetResultProperty($sResult, "id")
	EndIf
	c( "Studio id:" & $sStudioID)
	; Check tag names. If no such tag then auto create them.
	$aTags =  $oSceneData.item("tags")
	Local $aTagIDs[0]
	c( "Tags: " & UBound($aTags) )
	If UBound($aTags) <> 0 Then 
		For $tag in $aTags
			; Just create the tags. It's ok to have errors.
			$sQuery = "{findTags(tag_filter:{name:{value:" & QueryQ($tag.item("name")) & ",modifier:EQUALS}}){count,tags{id}}}"
			$sResult = Query2($sQuery)
			if GetResultProperty($sResult, "count") = "0" Then
				$sQuery = "mutation{tagCreate(input:{name:" & QueryQ($tag.item("name")) & "}){id}}"
				$sResult = QueryMutation($sQuery)
				if @error Then
					c("Error creating tag:" & $tag.item("name") & " result :" & $sResult)
					Return SetError(5)
				EndIf
			EndIf
			$sTagID = GetResultProperty($sResult, "id")
			ArrayAdd( $aTagIDs, $sTagID )
		Next
		c( "tag ids:" & ArrayToString($aTagIDs))
	EndIf 
	; Check performers. Create them if missing.
	$aPerformers = $oSceneData.item("performers")
	Local $aPerformerIDs[0]
	c( "Performers: " & UBound($aPerformers) )
	If UBound($aPerformers) <> 0 Then 
		For $performer in $aPerformers
			$sQuery = "{findPerformers(performer_filter:{name:{value:" & QueryQ($performer.item("name")) & ",modifier: EQUALS}}){count,performers{id}}}"
			$sResult = Query2($sQuery)
			If GetResultProperty($sResult, "count") = "0" Then 
				; Create this performer by name
				$sQuery = "mutation{performerCreate(input:{name:" & QueryQ($performer.item("name")) & "}){id}}"
				$sResult = QueryMutation($sQuery)
				if @error Then
					c("Error creating performer :" & $performer.item("name") & " result :" & $sResult)
					Return SetError(6)
				EndIf
			EndIf
			$sTagID = GetResultProperty($sResult, "id")
			ArrayAdd( $aPerformerIDs, $sTagID)
		Next
		c( "performer ids:" & ArrayToString($aPerformerIDs))
	EndIf
	; Check groups. The group name should be the product id like ABC-1234
	$sQuery = "{findGroups(group_filter:{name:{value:" & QueryQ($sGroupName) & ",modifier: EQUALS}}){count,groups{id}}}"
	$sResult = Query2($sQuery)
	if GetResultProperty($sResult, "count") = "0" Then 
		; Create this movie and get the id.
		
		; First get the group's info
		$sQuery = "{scrapeGroupURL(url:" & QueryQ($sScrapeURL) & "){aliases,date,synopsis,director,duration,front_image}}"
		$sResult = Query2($sQuery)
		If @error Then
			c("Error getting group info. Result:" & $sResult)
			Return SetError(7)
		EndIf
		$oData = Json_Decode($sResult)
		$oGroupData = Json_ObjGet($oData, "data.scrapeGroupURL")
		$iDuration = HMStoInt($oGroupData.item("duration"))
		c( "front image:" & StringLeft( $oGroupData.item("front_image"), 100) )
		$sQuery = "mutation{groupCreate(input:{" & _
			"name:" & QueryQ($sGroupName) & ","
		
		$sQuery &= AddQueryItem( "aliases", $oGroupData.item("aliases") )
		$sQuery &= AddQueryItem( "date", $oGroupData.item("date"))
		$sQuery &= AddQueryItem( "studio_id", $sStudioID)
		$sQuery &= AddQueryItem( "director", $oGroupData.item("director"))
		$sQuery &= AddQueryItem( "synopsis", $oGroupData.item("synopsis"))
		$sQuery &= "urls:[" & QueryQ($sScrapeURL) & "]," & _
			"duration:" & $iDuration & "," & _
			"tag_ids:" & ArrayToStringQuery($aTagIDs) & ","
		$sQuery &= AddQueryItem( "front_image", $oGroupData.item("front_image"))
		$sQuery &= "}){id}}"
		$sResult = QueryMutation($sQuery)
		if @error Then
			c("Error creating group: " & $sGroupName & " result:" & $sResult)
			Return SetError(8)
		EndIf
		$sGroupID = GetResultProperty($sResult, "id")
		$iGroupCreated += 1
	Else 
		$sGroupID = GetResultProperty($sResult, "id")
	EndIf
	c( "group id:" & $sGroupID)
	
	; Now this scene is all ready.
	$sQuery = "mutation{sceneUpdate(input:{" & _
		"id:" & QueryQ($SceneID) & ","
		$sQuery &= AddQueryItem( "details", $oSceneData.item("details") )
		$sQuery &= AddQueryItem( "director", $oSceneData.item("director") )
		$sQuery &= AddQueryItem( "date", $oSceneData.item("date"))
		$sQuery &= AddQueryItem( "studio_id", $sStudioID)
		$sQuery &= "performer_ids:" & ArrayToStringQuery($aPerformerIDs) & "," & _
		"groups:{group_id:" & QueryQ($sGroupID) & "}," & _
		"tag_ids:" & ArrayToStringQuery($aTagIDs) & "," & _
		"organized: true" & _
		"}){id}}"
	$sResult = QueryMutation($sQuery)
	if @error Then 
		c( "Error updating scene: " & $sBaseName & " result: " & $sResult)
		Return SetError(9)
	EndIf
	c ("update scene success.")
	TrayTip("Done", "Finish processing scene:" & $sBaseName, 5, 16)
	Return $iGroupCreated
EndFunc

Func AddQueryItem($sKey, $sItem)
	return $sItem = "" ? "" : $sKey & ":" & QueryQ($sItem) & ","
EndFunc

Func HMStoInt($sDuration)
	; Convert "mm:ss" or "hh:mm:ss" to seconds
	$aTime = StringSplit($sDuration, ":")
	Switch $aTime[0]
		Case 2	; mm:ss format
			Return Int($aTime[1]) * 60 + Int($aTime[2])
		Case 3  ; hh:mm:ss format
			Return Int($aTime[1]) * 3600 + Int($aTime[2]) * 60 + Int($aTime[3])
		Case Else
			Return 0
	EndSwitch
EndFunc
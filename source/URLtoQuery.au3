;URLtoQuery.au3

; translate the URL into graphql.
; $sURL is the full url in stash browser.
; $sQueryType is either "count" or "id"

Func URLtoQuery($sURL, $sQueryType = "id", $sQueryExtra = "")
	; 
	; get the string after the base url
	If $sQueryExtra <> "" Then $sQueryExtra = ',' & $sQueryExtra
	Local $aResult[1]
	Local $sStr = StringMid($sURL, StringLen($stashURL) +1 )
	If StringLeft($sStr, 1) = "/" Then $sStr = StringTrimLeft($sStr, 1)
	$aStr = StringSplit($sStr, "?&/", $STR_NOCOUNT)
	
	local $aStrOut[0]
	; Even $sStr is empty. Still $aStr[0] is 1
	Local $iCount = UBound($aStr), $bHaveQuery =  False 
	
	Local $sSortby = "", $sSortDir = "ASC", $sQuickQuery = ""
	Local $aCQuery[0]  ; For "c=xxx" queries
	; Remove the 'sortby=xxx' or "qsortd=xxx" from the array
	For $i = 0 to $iCount-1
		Switch PairName($aStr[$i])
			Case "sortby", "qsort"
				$sSortby = PairValue( $aStr[$i])
			Case "sortdir", "qsortd"
				$sSortDir = StringUpper( PairValue($aStr[$i]) )
			Case "disp", "p", "perPage", "qfp", "continue"
				; Dont care about these at all.
				; Remember to remove all those unecessary parameters,
				; Or the whole thing won't work !!
			Case "q"
				$sQuickQuery = PairValue($aStr[$i])
				$bHaveQuery = True
			Case "c"
				; Add one c query, this is should be part of c
				Local $iU = UBound($aCQuery)
				ReDim $aCQuery[ $iU + 1]
				$aCQuery[$iU] = PairValue($aStr[$i])
				$bHaveQuery = True 
			Case Else
				; Save the other part of URLs to $aStrOut, like ['movies','123']
				Local $iUB = UBound($aStrOut)
				ReDim $aStrOut[ $iUB+1 ]
				$aStrOut[$iUB] = $aStr[$i]
		EndSwitch 
	Next
	; $aStr now is removed all filters.
	$aStr = $aStrOut
	; Reset the iCount after remove the filters
	$iCount = UBound($aStr)
	Local $sFilter = "filter:{per_page:-1"
	If $sQuickQuery <> "" Then $sFilter &= " q: " & QueryQ($sQuickQuery)
	If $sSortby <> "" Then $sFilter &= " sort:" & QueryQ($sSortby) & " direction:" & $sSortDir
	$sFilter &= "}"
	
	; _ArrayDisplay($aStr)
	
	c("sFilter:" & $sFilter & " icount:" & $iCount)
	c("c query ubound:" & UBound($aCQuery))
	If $iCount = 1 And Not $bHaveQuery Then
		; Home page or category root
		Switch $aStr[0] & $sQueryType
			Case "id", "count"
				return "home"
			Case "scenescount"
				Return '{findScenes(scene_filter:{title:{value: \".+\" modifier: MATCHES_REGEX }}){count ' & $sQueryExtra & '}}'
			Case "scenesid"
				Return '{findScenes(scene_filter:{title:{value: \".+\" modifier: MATCHES_REGEX }} ' & $sFilter & '){count, scenes {id ' & $sQueryExtra & '}}}'
			Case "imagescount"
				Return '{findImages(image_filter:{title:{value: \".+\" modifier: MATCHES_REGEX}}){count ' & $sQueryExtra & '}}'
			Case "imagesid"
				Return '{findImages(image_filter:{title:{value: \".+\" modifier: MATCHES_REGEX }} ' & $sFilter & '){count, images {id ' & $sQueryExtra & '}}}'
			Case "moviescount"
				Return '{findMovies(movie_filter:{name:{value: \".+\" modifier: MATCHES_REGEX }}){count ' & $sQueryExtra & '}}'
			Case "moviesid"
				Return '{findMovies(movie_filter:{name:{value: \".+\" modifier: MATCHES_REGEX }} ' & $sFilter & '){count, movies {id ' & $sQueryExtra & '}}}'
			Case "galleriescount"
				Return '{findGalleries(gallery_filter:{title:{value: \".+\" modifier: MATCHES_REGEX}}){count ' & $sQueryExtra & '}}'
			Case "galleriesid"
				Return '{findGalleries(gallery_filter:{title:{value: \".+\" modifier: MATCHES_REGEX }} ' & $sFilter & '){count,galleries {id ' & $sQueryExtra & '}}}'
			Case Else
				Return 'not support'
		EndSwitch
	EndIf
	; c ("icount =" & $iCount & " is digit?" & StringIsDigit($aStr[1]))
	
	If Not $bHaveQuery And StringIsDigit($aStr[1]) Then
		; Specified image, gallery, scene or movie
		Switch $aStr[0] & $sQueryType
			Case "scenescount", "imagescount", "moviescount", "galleriescount"
				Return "1"
			Case "scenesid", "imagesid", "moviesid", "galleriesid"
				; return a single scene id
				If  $sQueryExtra = "" Then 
					Return 'id='& $aStr[1]
				Else
					; With extra request
					Switch $aStr[0]
						Case "scenes" 
							Return '{findScene(id:' & $aStr[1]& '){id '& $sQueryExtra& '}}'
						Case "movies"
							; Cannot use findMovies with  movie id
							Return '{findMovie('& $aStr[1]& '){id ' & $sQueryExtra & '}}'
						Case "images"
							Return '{findImage(id:'& $aStr[1]& '){id '& $sQueryExtra & '}}'
						Case "galleries"
							; Cannot use findGalleries with gallery id either.
							Return '{findGallery(id:'& $aStr[1] & '){id '& $sQueryExtra & '}}'
					EndSwitch
				EndIf 
			Case Else
				Return "not support"
		EndSwitch 
	EndIf
	
	; Now it's just pure c= queries
	Local $sCriteria = ""
	If UBound($aCQuery) > 0 Then 
		; Have to check before this for...in...
		For $sCQuery In $aCQuery
			c("$sCQuery:" & $sCQuery)
			Local $oCriteria =  Json_Decode($sCQuery)
			If @error Or ( Not IsObj($oCriteria)) Then
				ContinueLoop
			Else 
				Switch $oCriteria.item("type")
					Case "sceneChecksum", "movieChecksum", "galleryChecksum", "imageChecksum"
						$sCriteria &= MakeCriteria("checksum", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "details"
						$sCriteria &= MakeCriteria("details", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "duration"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								Local $sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("duration", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("duration", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
					Case "hasMarkers"
						$sCriteria &= MakeCriteria2( "has_markers", QueryQ($oCriteria.Item("value")) ) ; The type is set to string. Why??!!
					Case "oshash"
						$sCriteria &= MakeCriteria("oshash", QueryQ($oCriteria.Item("value")) , $oCriteria.Item("modifier") )
					Case "interactive"
						$sCriteria &= MakeCriteria2("interactive", $oCriteria.Item("value")) ; Now this type is set to boolean, which is right.
					Case "sceneIsMissing", "movieIsMissing", "galleryIsMissing", "imageIsMissing"
						$sCriteria &= MakeCriteria2("is_missing", QueryQ($oCriteria.Item("value")) )
					Case "movies"  ; This is only in scenes
						Switch $oCriteria.item("modifier")
							Case "IS_NULL", "NOT_NULL"
								$sCriteria &= MakeCriteria("movies", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
							Case Else
								; The value is a movie array, convert it to "[123, 124...]" format
								Local $aMovies = $oCriteria.item("value")
								Local $sIDs = "["
								If UBound($aMovies)> 0 Then  ; Just in case
									For $oMovie In $aMovies
										If $sIDs = "[" Then 
											$sIDs &= $oMovie.Item("id")
										Else 
											$sIDs &= "," & $oMovie.Item("id")
										EndIf
									Next
									$sIDs &= "]"
								EndIf
								$sCriteria &= MakeCriteria("movies", $sIDs, $oCriteria.Item("modifier") )
						EndSwitch
					Case "o_counter"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								$sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("o_counter", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("o_counter", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
					Case "organized"
						$sCriteria &= MakeCriteria2("organized", $oCriteria.Item("value"))
					Case "path"
						$sCriteria &= MakeCriteria("path", QueryQ( $oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "performer_count"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								$sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("performer_count", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("performer_count", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
					Case "performerTags"
						Switch $oCriteria.item("modifier")
							Case "IS_NULL", "NOT_NULL"
								$sCriteria &= MakeCriteria("performer_tags", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
							Case Else
								; The value is a movie array, convert it to "[123, 124...]" format
								Local $aTags = $oCriteria.item("value").item("items")
								Local $sIDs = "["
								If UBound($aTags)> 0 Then  ; Just in case
									For $oTag In $aTags
										If $sIDs = "[" Then 
											$sIDs &= $oTag.item("id")
										Else 
											$sIDs &= "," & $oTag.item("id")
										EndIf
									Next
									$sIDs &= "]"
								EndIf
								; Add the depth: value
								$sIDs &= " depth:" & $oCriteria.item("value").item("depth")
								$sCriteria &= MakeCriteria("performer_tags", $sIDs, $oCriteria.Item("modifier") )
						EndSwitch
					Case "performers"
						Switch $oCriteria.item("modifier")
							Case "IS_NULL", "NOT_NULL"
								$sCriteria &= MakeCriteria("performers", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
							Case Else
								; The value is a movie array, convert it to "[123, 124...]" format
								Local $aPerformers = $oCriteria.item("value")
								Local $sIDs = "["
								If UBound($aPerformers)> 0 Then  ; Just in case
									For $oPerformer In $aPerformers
										If $sIDs = "[" Then 
											$sIDs &= $oPerformer.item("id")
										Else 
											$sIDs &= "," & $oPerformer.item("id")
										EndIf
									Next
									$sIDs &= "]"
								EndIf
								$sCriteria &= MakeCriteria("performers", $sIDs, $oCriteria.Item("modifier") )
						EndSwitch
					Case "phash"
						$sCriteria &= MakeCriteria("phash", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "rating"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								$sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("rating", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("rating", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
					Case "resolution"
						$sCriteria &= MakeCriteria("resolution", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
					Case "stash_id"
						$sCriteria &= MakeCriteria("stash_id", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "studios"
						Switch $oCriteria.item("modifier")
							Case "IS_NULL", "NOT_NULL"
								$sCriteria &= MakeCriteria("studios", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
							Case Else
								; The value is a movie array, convert it to "[123, 124...]" format
								Local $aStudios = $oCriteria.item("value").item("items")
								Local $sIDs = "["
								If UBound($aStudios)> 0 Then  ; Just in case
									For $oStudio In $aStudios
										If $sIDs = "[" Then 
											$sIDs &= $oStudio.item("id")
										Else 
											$sIDs &= "," & $oStudio.item("id")
										EndIf
									Next
									$sIDs &= "]"
								EndIf
								; Add the depth: value
								$sIDs &= " depth:" & $oCriteria.item("value").item("depth")
								$sCriteria &= MakeCriteria("studios", $sIDs, $oCriteria.Item("modifier") )
						EndSwitch
					Case "tag_count"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								$sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("tag_count", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("tag_count", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
					Case "tags"
						Switch $oCriteria.item("modifier")
							Case "IS_NULL", "NOT_NULL"
								$sCriteria &= MakeCriteria("tags", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
							Case Else
								; The value is a movie array, convert it to "[123, 124...]" format
								Local $aTags = $oCriteria.item("value").item("items")
								Local $sIDs = "["
								If UBound($aTags)> 0 Then  ; Just in case
									For $oTag In $aTags
										If $sIDs = "[" Then 
											$sIDs &= $oTag.item("id")
										Else 
											$sIDs &= "," & $oTag.item("id")
										EndIf
									Next
									$sIDs &= "]"
								EndIf
								; Add the depth: value
								$sIDs &= " depth:" & $oCriteria.item("value").item("depth")
								$sCriteria &= MakeCriteria("tags", $sIDs, $oCriteria.Item("modifier") )
						EndSwitch
					Case "title"
						$sCriteria &= MakeCriteria("title", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "url"
						$sCriteria &= MakeCriteria("url", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					; Now it's the movie's specific criteria
					Case "director"
						$sCriteria &= MakeCriteria("director", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "name"
						$sCriteria &= MakeCriteria("name", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					Case "synopsis"
						$sCriteria &= MakeCriteria("synopsis", QueryQ($oCriteria.Item("value")), $oCriteria.Item("modifier") )
					; Now it's galleries specific criteria
					Case "average_resolution"
						$sCriteria &= MakeCriteria("average_resolution", $oCriteria.Item("value"), $oCriteria.Item("modifier") )
					Case "image_count"
						Switch $oCriteria.item("modifier")
							Case "BETWEEN", "NOT_BETWEEN"
								; It has value 1 and value 2. So much trouble !
								$sValues = $oCriteria.Item("value").Item("value") & " value2:" & $oCriteria.Item("value").Item("value2")
								$sCriteria &= MakeCriteria("image_count", $sValues, $oCriteria.Item("modifier") )
							Case Else 
								$sCriteria &= MakeCriteria("image_count", $oCriteria.Item("value").Item("value"), $oCriteria.Item("modifier") )
						EndSwitch
				EndSwitch
			EndIf
		Next
	EndIf
	
	; Now put the Criteria and filter in the query string.
	Local $sQString
	Switch $aStr[0] & $sQueryType
		Case "scenescount"
			$sQString = '{findScenes('
			If $sCriteria <> "" Then $sQString &= "scene_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count '& $sQueryExtra & '}}'
			Return $sQString
		Case "scenesid"
			$sQString = '{findScenes('
			If $sCriteria <> "" Then $sQString &= "scene_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count,scenes{id '& $sQueryExtra & '}}}'
			Return $sQString
		Case "moviescount"
			$sQString = '{findMovies('
			If $sCriteria <> "" Then $sQString &= "movie_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count '& $sQueryExtra & '}}'
			Return $sQString
		Case "moviesid"
			$sQString = '{findMovies('
			If $sCriteria <> "" Then $sQString &= "movie_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count,movies{id '& $sQueryExtra & '}}}'
			Return $sQString
		Case "imagescount"
			$sQString = '{findImages('
			If $sCriteria <> "" Then $sQString &= "image_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count '& $sQueryExtra & '}}'
			Return $sQString
		Case "imagesid"
			$sQString = '{findImages('
			If $sCriteria <> "" Then $sQString &= "image_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count,images{id '& $sQueryExtra & '}}}'
			Return $sQString
		Case "galleriescount"
			$sQString = '{findGalleries('
			If $sCriteria <> "" Then $sQString &= "gallery_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count '& $sQueryExtra & '}}'
			Return $sQString
		Case "galleriesid"
			$sQString = '{findGalleries('
			If $sCriteria <> "" Then $sQString &= "gallery_filter: {" & $sCriteria & "} "
			$sQString &= $sFilter & '){count,galleries{id '& $sQueryExtra & '}}}'
			Return $sQString
		Case Else
			Return 'not support'
	EndSwitch
	
EndFunc

Func GetResultProperty($sJson, $sProperty)
	; This will save some time for json string result
	; It could get the wrong property with the same name. So make sure $sProperty is the only one in result.
	Local $aStr = StringRegExp($sJson, Q($sProperty) & ':\s*"?(.+?)["},\n\r]', $STR_REGEXPARRAYMATCH )
	If @error Then Return ""
	Return $aStr[0]
EndFunc

Func QueryQ($str)
	; Quote within a query
	Return '\"' & $str & '\"'
EndFunc

Func MakeCriteria2($type, $value)
	Return " " & $type & ":" & $value & " "
EndFunc

Func MakeCriteria($type, $value, $modifier)
	If $value = "" Then 
		Return " " & $type & ":{modifier : " & $modifier & "}"
	Else 
		Return " " & $type & ":{value:" & $value & " modifier : " & $modifier & "}"
	EndIf
EndFunc

Func PairName($str, $separator = "=")
	Return stringleft( $str, stringinstr($str, $separator, 2) -1 )
EndFunc

Func PairValue($str, $separator = "=")
	Return stringmid( $str, stringinstr($str, $separator, 2) + 1 )
EndFunc

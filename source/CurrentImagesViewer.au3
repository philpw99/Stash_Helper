;GalleryViewer.au3

; Create a temporary html with all the gallery pictures.
; Use light gallery 2.0 as the picture viewer.
; $nGallery is the gallery number in string.
Func CurrentImagesViewer()
	; Don't want to handle all those quotes
	Const $sHTML_Head = _BinaryCall_Base64Decode( "PCFET0NUWVBFIGh0bWw+PGh0bWwgbGFuZz0iZW4tVVMiPgo8aGVhZD4KCTx0aXRsZT5UZXN0IExp" & _
		"Z2h0IGdhbGxlcnk8L3RpdGxlPgoJPG1ldGEgY2hhcnNldD0id2luZG93cy0xMjUyIj4KCTxsaW5r" & _
		"IHR5cGU9InRleHQvY3NzIiByZWw9InN0eWxlc2hlZXQiIGhyZWY9InN0eWxlLmNzcyIgLz4KPHN0" & _
		"eWxlPgpib2R5IHsKICBiYWNrZ3JvdW5kLWNvbG9yOiAjMDAwMDAwOwp9Ci5mbGV4LWNvbnRhaW5l" & _
		"cnsKICBkaXNwbGF5OiBmbGV4OwogIGZsZXgtd3JhcDogd3JhcDsKfQouZ2FsbGVyeS1pdGVtewog" & _
		"IHBhZGRpbmc6IDEwcHgKfQouaW1nLXJlc3BvbnNpdmV7CiAgaGVpZ2h0OiAzMDBweDsKfQo8L3N0" & _
		"eWxlPgo8L2hlYWQ+Cjxib2R5Pgo8c2NyaXB0IHNyYz0ic2NyaXB0LmpzIj48L3NjcmlwdD4KCiAg" & _
		"ICA8ZGl2IGNsYXNzPSJmbGV4LWNvbnRhaW5lciIgaWQ9ImFuaW1hdGVkLXRodW1ibmFpbHMtZ2Fs" & _
		"bGVyeSI+Cg==" )

	Const $sHTML_Tail = _BinaryCall_Base64Decode ( "CiAgICA8L2Rpdj4KCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4KCSAgICB3aW5kb3cu" & _
		"bGlnaHRHYWxsZXJ5KCBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgiYW5pbWF0ZWQtdGh1bWJuYWls" & _
		"cy1nYWxsZXJ5IiksCgkgICAgICB7CgkgICAgICAgIHBsdWdpbnM6IFtsZ1pvb20sIGxnVGh1bWJu" & _
		"YWlsXQoJICAgICAgfQoJICAgICk7Cjwvc2NyaXB0Pgo8L2JvZHk+CjwvaHRtbD4=" )
	

	; Get all the files in a gallery.
	Local $sURL = GetURL()
	If @error Then Return SetError(1)
		
	Local $sCategory = GetCategory($sURL)
	If @error Then Return SetError(1)
	
	; Image array, first one is full size, second is thumbnail.
	Local $aImages[0]
	
	Switch $sCategory
		
		Case "groups", "scenes", "markers", "performers", "studios", "tags"
			MsgBox(0, "Not support", "Sorry, this operation only supports images and galleries.")
			Return
		Case "images"
			$sQuery = URLtoQuery($sURL)
			c("Image query:" & $sQuery)
			Select 
				Case $sQuery = "not support"
					MsgBox(0, "Not support", "This URL is not supported.")
					Return 
				Case StringLeft($sQuery, 3) = "id="
					MsgBox(0, "Not support", "Single image viewing is not supported.")
					Return
				Case Else
					$sResult = Query2($sQuery)
					If @error then Return SetError(1)
					$oResult = Json_Decode($sResult)
					If not IsObj($oResult) Then
						MsgBox(0, "Error", "Error processing images result.")
						Return SetError(1)
					EndIf
					$aImages = Json_ObjGet($oResult, "data.findImages.images")
			EndSelect
		Case "galleries"
			$sQuery = URLtoQuery($sURL, "id", "images{id}")
			c("Gallery query:" & $sQuery)
			Select 
				Case $sQuery = "not support"
					MsgBox(0, "Not support", "This URL is not supported.")
					Return 
				Case StringLeft($sQuery, 12) = "{findGallery"
					; Get the id of gallery
					$sResult = Query2($sQuery)
					If @error then Return SetError(1)
					$oResult = Json_Decode($sResult)
					If not IsObj($oResult) Then
						MsgBox(0, "Error", "Error processing gallery result.")
						Return SetError(1)
					EndIf
					$aImages = Json_ObjGet($oResult, "data.findGallery.images")
				Case Else
					; Should be findGalleries(...)
					$sResult = Query2($sQuery)
					If @error then Return SetError(1)
					$oResult = Json_Decode($sResult)
					If not IsObj($oResult) Then
						MsgBox(0, "Error", "Error processing galleries result.")
						Return SetError(1)
					EndIf
					$aGalleries = Json_ObjGet($oResult, "data.findGalleries.galleries")
					For $i = 0 To UBound($aGalleries)-1
						$aImg = $aGalleries[$i].Item("images")
						; Add the array data to the $aImages
						_ArrayConcatenate($aImages, $aImg)
					Next
			EndSelect
	EndSwitch
	; Now process the $aImages
	Local $sLinks = ""
	
	; If too many images, give out a warning.
	Local $iImageCount = UBound($aImages)
	If $iImageCount > 1000 Then 
		Local $reply = MsgBox(266272,"Are you sure?","There are " & $iImageCount & " images in this list. It will take the web browser quite a while to process them." _ 
			& @CRLF & "Do you want to continue?",0)
		if $reply = $IDNO Then Return 
	EndIf
	
	For $i = 0 to $iImageCount-1
		$sLinks &= '<a  class="gallery-item" href="' & $stashURL & 'image/' & $aImages[$i].Item("id") & '/image">' & @LF _
			& '<img class="img-responsive"  src="' & $stashURL & 'image/' & $aImages[$i].Item("id") & '/thumbnail" /> </a>' & @LF
	Next
	
	CopyGalleryFiles()
	
	$hFile = FileOpen( @AppDataDir & "\Webdriver\tempImageList.html", $FO_OVERWRITE)
	If $hFile = -1 Then 
		MsgBox(0, "error", "Error creating temporary html file.")
		Return SetError(1)
	EndIf
	FileWrite($hFile, $sHTML_Head)
	FileWrite($hFile, $sLinks)
	FileWrite($hFile, $sHTML_Tail)
	If @error Then 
		MsgBox(0, "Error", "Error writing to temporary html file.")
		FileClose($hFile)
		Return SetError(1)
	EndIf
	FileClose($hFile)
	$sFileURL = "file:///" & StringReplace(@AppDataDir & "\Webdriver\tempImageList.html", "\", "/")
	OpenURL($sFileURL)
EndFunc

Func CopyGalleryFiles()
	Local $sDestPath = @AppDataDir & "\Webdriver\"
	If Not FileExists($sDestPath & "lg.ttf") Then 
		FileCopy(@ScriptDir & "\gallery\lg.ttf", $sDestPath & "lg.ttf")
	EndIf
	If Not FileExists($sDestPath & "lg.woff") Then 
		FileCopy(@ScriptDir & "\gallery\lg.woff", $sDestPath & "lg.woff")
	EndIf
	If Not FileExists($sDestPath & "lg.svg") Then 
		FileCopy(@ScriptDir & "\gallery\lg.svg", $sDestPath & "lg.svg")
	EndIf
	If Not FileExists($sDestPath & "script.js") Then 
		FileCopy(@ScriptDir & "\gallery\script.js", $sDestPath & "script.js")
	EndIf
	If Not FileExists($sDestPath & "style.css") Then 
		FileCopy(@ScriptDir & "\gallery\style.css", $sDestPath & "style.css")
	EndIf
EndFunc


;GalleryViewer.au3

; Create a temporary html with all the gallery pictures.
; Use light gallery 2.0 as the picture viewer.
; $nGallery is the gallery number in string.
Func CurrentImagesViewer()
	; Don't want to handle all those quotes
	Const $sHTML_Head = _BinaryCall_Base64Decode( "PCFET0NUWVBFIGh0bWw+PGh0bWwgbGFuZz0iZW4tVVMiPgo8aGVhZD4KCTx0aXRsZT5UZXN0IExp" & _
		"Z2h0IGdhbGxlcnk8L3RpdGxlPgoJPG1ldGEgY2hhcnNldD0id2luZG93cy0xMjUyIj4KCTxsaW5r" & _
		"IHR5cGU9InRleHQvY3NzIiByZWw9InN0eWxlc2hlZXQiIGhyZWY9Imh0dHBzOi8vY2RuLmpzZGVs" & _
		"aXZyLm5ldC9ucG0vbGlnaHRnYWxsZXJ5QDIuMC4wLWJldGEuMy9jc3MvbGlnaHRnYWxsZXJ5LmNz" & _
		"cyIgLz4KCTxsaW5rIHR5cGU9InRleHQvY3NzIiByZWw9InN0eWxlc2hlZXQiIGhyZWY9Imh0dHBz" & _
		"Oi8vY2RuLmpzZGVsaXZyLm5ldC9ucG0vbGlnaHRnYWxsZXJ5QDIuMC4wLWJldGEuMy9jc3MvbGct" & _
		"em9vbS5jc3MiIC8+Cgk8bGluayB0eXBlPSJ0ZXh0L2NzcyIgcmVsPSJzdHlsZXNoZWV0IiBocmVm" & _
		"PSJodHRwczovL2Nkbi5qc2RlbGl2ci5uZXQvbnBtL2p1c3RpZmllZEdhbGxlcnlAMy44LjEvZGlz" & _
		"dC9jc3MvanVzdGlmaWVkR2FsbGVyeS5jc3MiIC8+Cgk8bGluayB0eXBlPSJ0ZXh0L2NzcyIgcmVs" & _
		"PSJzdHlsZXNoZWV0IiBocmVmPSJodHRwczovL2Nkbi5qc2RlbGl2ci5uZXQvbnBtL2Jvb3RzdHJh" & _
		"cEA1LjAuMS9kaXN0L2Nzcy9ib290c3RyYXAuY3NzIiAvPgoJPGxpbmsgdHlwZT0idGV4dC9jc3Mi" & _
		"IHJlbD0ic3R5bGVzaGVldCIgaHJlZj0iaHR0cHM6Ly9jZG4uanNkZWxpdnIubmV0L25wbS9saWdo" & _
		"dGdhbGxlcnlAMi4wLjAtYmV0YS4zL2Nzcy9sZy10aHVtYm5haWwuY3NzIiAvPgo8L2hlYWQ+Cjxi" & _
		"b2R5Pgo8c2NyaXB0IHNyYz0iaHR0cHM6Ly9jZG4uanNkZWxpdnIubmV0L25wbS9qcXVlcnlAMy42" & _
		"LjAvZGlzdC9qcXVlcnkuanMiPjwvc2NyaXB0Pgo8c2NyaXB0IHNyYz0iaHR0cHM6Ly9jZG4uanNk" & _
		"ZWxpdnIubmV0L25wbS9saWdodGdhbGxlcnlAMi4wLjAtYmV0YS4zL2xpZ2h0Z2FsbGVyeS51bWQu" & _
		"anMiPjwvc2NyaXB0Pgo8c2NyaXB0IHNyYz0iaHR0cHM6Ly9jZG4uanNkZWxpdnIubmV0L25wbS9s" & _
		"aWdodGdhbGxlcnlAMi4wLjAtYmV0YS4zL3BsdWdpbnMvem9vbS9sZy16b29tLnVtZC5qcyI+PC9z" & _
		"Y3JpcHQ+CjxzY3JpcHQgc3JjPSJodHRwczovL2Nkbi5qc2RlbGl2ci5uZXQvbnBtL2p1c3RpZmll" & _
		"ZEdhbGxlcnlAMy44LjEvZGlzdC9qcy9qcXVlcnkuanVzdGlmaWVkR2FsbGVyeS5qcyI+PC9zY3Jp" & _
		"cHQ+CjxzY3JpcHQgc3JjPSJodHRwczovL2Nkbi5qc2RlbGl2ci5uZXQvbnBtL2xpZ2h0Z2FsbGVy" & _
		"eUAyLjAuMC1iZXRhLjMvcGx1Z2lucy90aHVtYm5haWwvbGctdGh1bWJuYWlsLnVtZC5qcyI+PC9z" & _
		"Y3JpcHQ+Cgo8ZGl2IGNsYXNzPSJjb250YWluZXItc20iPgogIDxkaXYgY2xhc3M9InJvdyBqdXN0" & _
		"aWZ5LWNvbnRlbnQtY2VudGVyIj4KICAgIDxkaXYgY2xhc3M9ImNvbCBjb2wtbWQtMTAiPgogICAg" & _
		"ICA8ZGl2IGNsYXNzPSJnYWxsZXJ5LWNvbnRhaW5lciIgaWQ9ImFuaW1hdGVkLXRodW1ibmFpbHMt" & _
		"Z2FsbGVyeSI+Cg==" )

	Const $sHTML_Tail = _BinaryCall_Base64Decode ("ICAgIDwvZGl2PgogICAgPC9kaXY+CiAgICA8L2Rpdj4KICA8L2Rpdj4KCjxzY3JpcHQgdHlwZT0i" & _
		"dGV4dC9qYXZhc2NyaXB0Ij4KCWpRdWVyeSgiI2FuaW1hdGVkLXRodW1ibmFpbHMtZ2FsbGVyeSIp" & _
		"CgkgIC5qdXN0aWZpZWRHYWxsZXJ5KHsKCSAgICBjYXB0aW9uczogZmFsc2UsCgkgICAgbGFzdFJv" & _
		"dzogImhpZGUiLAoJICAgIHJvd0hlaWdodDogMzAwLAoJICAgIG1hcmdpbnM6IDEwCgkgIH0pCgkg" & _
		"IC5vbigiamcuY29tcGxldGUiLCBmdW5jdGlvbiAoKSB7CgkgICAgd2luZG93LmxpZ2h0R2FsbGVy" & _
		"eSgKCSAgICAgIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCJhbmltYXRlZC10aHVtYm5haWxzLWdh" & _
		"bGxlcnkiKSwKCSAgICAgIHsKCSAgICAgICAgcGx1Z2luczogW2xnWm9vbSwgbGdUaHVtYm5haWxd" & _
		"CgkgICAgICB9CgkgICAgKTsKCSAgfSk7Cjwvc2NyaXB0Pgo8L2JvZHk+CjwvaHRtbD4=" )
	

	; Get all the files in a gallery.
	Local $sURL = GetURL()
	If @error Then Return SetError(1)
		
	Local $sCategory = GetCategory($sURL)
	If @error Then Return SetError(1)
	
	; Image array, first one is full size, second is thumbnail.
	Local $aImages[0]
	
	Switch $sCategory
		
		Case "movies", "scenes", "markers", "performers", "studios", "tags"
			MsgBox(0, "Not support", "Sorry, this operation only supports images and galleries.")
			Return
		Case "images"
			$sQuery = URLtoQuery($sURL)
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
	
	$hFile = FileOpen( @TempDir & "\tempImageList.html", $FO_OVERWRITE)
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
	$sFileURL = "file:///" & StringReplace(@TempDir & "\tempImageList.html", "\", "/")
	OpenURL($sFileURL)
EndFunc

